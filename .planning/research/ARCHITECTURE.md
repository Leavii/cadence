# Architecture Research

**Domain:** OSS gamification service for Claude Code (3-component distributed system: backend service, web app, local helper)
**Researched:** 2026-05-08
**Confidence:** HIGH on component boundaries, wire protocols, and data model. HIGH on storage strategy. MEDIUM on long-horizon scaling beyond ~10k users (the project explicitly targets hundreds initially, so this is appropriate).

## Executive Summary

This is a classic three-tier with one twist: the third tier is not a browser but a **local helper running inside the user's Claude Code environment**. That changes everything about wire protocols and identity binding compared to a normal web app.

The architecture has one absolute rule: **the backend is the only authority on score, XP, quests, and achievements.** The helper produces signals; it does not produce truth. The web app reads truth; it does not produce it. Anything else makes anti-cheat impossible and breaks the open-source posture (people will run modified helpers — that has to be fine).

The other shape-defining constraints:

1. **Hooks must be invisible to the user's session.** Hook latency budget is well under 50ms, so hook handlers can only enqueue locally and return. Network is somebody else's problem (a background flusher).
2. **Device pairing is OAuth Device Authorization Grant (RFC 8628).** Better Auth ships this as a first-class plugin — confirmed via Context7. The CLI never prompts for a password; the browser handles auth.
3. **Leaderboards belong in Valkey sorted sets, scoreboards belong in Postgres.** Ephemeral hot path in memory, durable record in SQL.
4. **SSE for live, REST for everything else.** Hono ships first-class `streamSSE` — confirmed via Context7. WebSockets are deferred to v2 raids.

Build the **backend first**, then the **CLI helper** (because device pairing depends on the auth server existing), then the **web app** (which is the largest surface area but consumes existing APIs). This sequencing also matches risk profile: the parts most likely to need iteration are exposed earliest.

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         USER'S LOCAL MACHINE                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌──────────────────┐   hooks (JSON/stdin)   ┌─────────────────────┐  │
│  │   Claude Code    │ ─────────────────────► │  Helper CLI (Node)  │  │
│  │  (hook fire)     │                        │  - hook subcommands │  │
│  └──────────────────┘                        │  - stats subcommand │  │
│                                              │  - pair subcommand  │  │
│  ┌──────────────────┐    `cli stats` JSON    │                     │  │
│  │  User's Custom   │ ◄───────────────────── │  ┌──────────────┐   │  │
│  │   Statusline     │                        │  │ SQLite outbox│   │  │
│  └──────────────────┘                        │  │ + cache      │   │  │
│                                              │  └──────┬───────┘   │  │
│                                              └─────────┼───────────┘  │
│                                                        │              │
└────────────────────────────────────────────────────────┼──────────────┘
                                                         │ HTTPS batched
                                                         │ (bearer token)
                                                         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          BACKEND (Hono on Node)                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────────┐  │
│  │   Auth     │  │  Ingest    │  │  Public    │  │  SSE Streamer  │  │
│  │ (RFC 8628) │  │  /events   │  │   API      │  │ /sse/...       │  │
│  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘  └────────┬───────┘  │
│        │               │               │                  │           │
│        ▼               ▼               ▼                  ▼           │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │              Domain services (TypeScript modules)              │  │
│  │  accounts │ quests │ achievements │ leaderboards │ social      │  │
│  │           │ anti-cheat │ cosmetics │ feed                       │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │                BullMQ workers (separate process at scale)       │  │
│  │  daily-quest-rotate │ achievement-eval │ leaderboard-recompute │  │
│  │  anti-cheat-sweep   │ feed-fanout      │ usage-poll            │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────┬──────────────────────────────┬─────────────────────┘
                   │                              │
                   ▼                              ▼
        ┌──────────────────┐            ┌──────────────────┐
        │  PostgreSQL 17   │            │   Valkey 8.x     │
        │  - accounts      │            │  - leaderboards  │
        │  - profiles      │            │    (ZSETs)       │
        │  - quests        │            │  - BullMQ queues │
        │  - achievements  │            │  - rate limits   │
        │  - cosmetics     │            │  - SSE pub/sub   │
        │  - friend graph  │            │  - hot caches    │
        │  - events (raw)  │            │                  │
        │  - rollups       │            │                  │
        └──────────────────┘            └──────────────────┘
                                                ▲
                   ┌────────────────────────────┘
                   │ SSE / REST
                   │
┌──────────────────┴──────────────────────────────────────────────────────┐
│                    WEB APP (SvelteKit on Node adapter)                  │
├─────────────────────────────────────────────────────────────────────────┤
│   /              profile, badge case                                    │
│   /leaderboards  4 boards, live via SSE                                 │
│   /quests        today's 5, progress, history                           │
│   /u/[handle]    public profile, comments, friends                      │
│   /device        device-pairing confirmation page                       │
│   /settings      account, handle, privacy                               │
└─────────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Owns (authoritative for) | Does NOT own | Implementation |
|-----------|--------------------------|--------------|----------------|
| **Helper CLI** | Local capture of Claude Code signals; local outbox; OAuth token storage; statusline data fragment | XP, score, quest progress, leaderboard rank — these are server-derived | Node 22 + citty + better-sqlite3 + conf, distributed via `npm` / `npx` |
| **Backend (HTTP)** | Auth, event ingestion, public read API, device-pairing endpoints, SSE fan-out | Long-running compute (delegated to workers) | Hono + Better Auth + Drizzle, single process at v1 |
| **Backend (Workers)** | Quest rotation, achievement evaluation, leaderboard recompute, anti-cheat sweeps, feed fan-out | Real-time request handling | BullMQ workers; same codebase, different entry point; separate process at scale |
| **PostgreSQL** | Source of truth for all durable state: identities, quest definitions and assignments, achievement definitions and unlocks, friend graph, comments, raw event log, rollups | Hot leaderboard ranges, ephemeral session state | Postgres 17 + Drizzle |
| **Valkey** | Leaderboard sorted sets, BullMQ queue state, rate-limit counters, SSE pub/sub channel, ephemeral hot caches | Anything that must survive a full restart with zero loss | Valkey 8.x |
| **Web App** | UI state, view composition, SSR rendering, browser-side device-pairing confirmation UI | Any business logic — purely a client of the backend API | SvelteKit 2 (Svelte 5) on Node adapter |
| **Browser (during pairing)** | Authenticating the user, confirming the pairing, displaying the user_code | Storing tokens, talking to the CLI directly | Standard browser session against the SvelteKit `/device` route |

### The hard boundary that must not be crossed

> **The helper CLI never asserts game state. It only reports observed signals.**

Every score, XP value, quest progress count, achievement unlock, and rank shown by the statusline or web app must trace back to a server computation. The CLI caches what the server tells it (so the statusline is fast and offline-tolerant for display), but it never computes that state itself. If a user runs a modified helper that lies about events, the worst they can do is poison their own input stream — which the anti-cheat sweep then catches.

This is the single most load-bearing rule in the architecture and the reason the app can be open-source without becoming a free-for-all.

## Recommended Project Structure

Monorepo with pnpm workspaces. Three deployable apps, two shared packages.

```
GSD-StatusLineGamification/
├── apps/
│   ├── api/                          # Hono backend (HTTP + workers)
│   │   ├── src/
│   │   │   ├── http/                 # Hono routes & middleware
│   │   │   │   ├── auth.ts           # Better Auth mount + device flow
│   │   │   │   ├── ingest.ts         # POST /events (helper → backend)
│   │   │   │   ├── public.ts         # GET /me, /leaderboards, /quests/today
│   │   │   │   ├── sse.ts            # streamSSE endpoints
│   │   │   │   └── admin.ts          # moderation, anti-cheat overrides
│   │   │   ├── domain/               # Pure business logic (no I/O)
│   │   │   │   ├── quests/           # quest rotation, progress evaluation
│   │   │   │   ├── achievements/     # achievement evaluation rules
│   │   │   │   ├── leaderboards/     # ranking dimension calculators
│   │   │   │   ├── anti-cheat/       # sanity checks, delta validation
│   │   │   │   ├── cosmetics/        # cosmetic loadout resolution
│   │   │   │   └── social/           # friend graph, comments, feed
│   │   │   ├── infra/                # I/O adapters
│   │   │   │   ├── db/               # Drizzle schema + queries
│   │   │   │   ├── cache/            # Valkey client + leaderboard ZSET ops
│   │   │   │   └── queue/            # BullMQ producers & consumers
│   │   │   ├── workers/              # BullMQ worker entrypoints
│   │   │   │   ├── quest-rotate.ts
│   │   │   │   ├── achievement-eval.ts
│   │   │   │   ├── leaderboard-recompute.ts
│   │   │   │   ├── anti-cheat-sweep.ts
│   │   │   │   ├── feed-fanout.ts
│   │   │   │   └── usage-poll.ts
│   │   │   ├── env.ts                # @t3-oss/env-core validation
│   │   │   ├── http-server.ts        # entrypoint: Hono on @hono/node-server
│   │   │   └── worker.ts             # entrypoint: BullMQ workers
│   │   └── drizzle/                  # migrations
│   │
│   ├── web/                          # SvelteKit web app
│   │   ├── src/
│   │   │   ├── routes/
│   │   │   │   ├── +layout.svelte
│   │   │   │   ├── +page.svelte      # /  (own profile)
│   │   │   │   ├── leaderboards/
│   │   │   │   ├── quests/
│   │   │   │   ├── u/[handle]/       # public profile
│   │   │   │   ├── device/           # OAuth device-pairing confirm page
│   │   │   │   ├── settings/
│   │   │   │   └── api/              # SvelteKit endpoints (BFF if needed)
│   │   │   ├── lib/
│   │   │   │   ├── api/              # typed client for backend
│   │   │   │   ├── sse/              # SSE subscription helpers
│   │   │   │   ├── components/       # 8bitcn/ui-derived primitives
│   │   │   │   └── auth.ts           # Better Auth client
│   │   │   └── app.css               # Tailwind 4 entry
│   │   └── svelte.config.js          # @sveltejs/adapter-node
│   │
│   └── cli/                          # Helper module (local)
│       ├── src/
│       │   ├── commands/
│       │   │   ├── pair.ts           # cli pair (device flow)
│       │   │   ├── stats.ts          # cli stats (statusline data)
│       │   │   ├── status.ts         # cli status (diagnostics)
│       │   │   └── hooks/            # one file per Claude Code hook
│       │   │       ├── session-start.ts
│       │   │       ├── user-prompt-submit.ts
│       │   │       ├── pre-tool-use.ts
│       │   │       ├── post-tool-use.ts
│       │   │       ├── stop.ts
│       │   │       └── session-end.ts
│       │   ├── outbox/               # local SQLite queue
│       │   │   ├── schema.ts
│       │   │   ├── enqueue.ts        # called by hook subcommands
│       │   │   └── flusher.ts        # background daemon
│       │   ├── statusline/           # cached gamification state
│       │   │   └── render.ts         # ANSI + JSON output formats
│       │   ├── auth/                 # OAuth client + token storage
│       │   ├── config.ts             # `conf`-backed settings
│       │   └── index.ts              # citty entry
│       └── sea-config.json           # optional Node SEA build
│
├── packages/
│   ├── shared/                       # Code shared across all 3 apps
│   │   ├── schemas/                  # Zod schemas for the wire
│   │   │   ├── events.ts             # signal event payloads
│   │   │   ├── quests.ts
│   │   │   ├── achievements.ts
│   │   │   └── leaderboards.ts
│   │   ├── types/                    # cross-cutting TS types
│   │   └── constants/                # signal kinds, achievement IDs
│   │
│   └── content/                      # Game content (versioned in repo)
│       ├── quests/                   # quest template definitions (JSON/TS)
│       ├── achievements/             # achievement definitions
│       └── cosmetics/                # cosmetic asset metadata
│
├── docker-compose.yml                # local dev: postgres + valkey + api + web
├── pnpm-workspace.yaml
├── turbo.json
└── README.md
```

### Structure Rationale

- **`apps/api/src/domain/` is pure.** No DB, no Valkey, no HTTP. This is the only sensible way to test quest evaluation and achievement rules — they have to be a function of `(user_state, signal) → new_state`. Pulling I/O out of the domain layer is the single biggest determinant of testability.
- **`apps/api/src/infra/` holds all I/O.** When the schema changes or a query gets slow, it changes here, not in 40 places. Domain code calls infra through narrow interfaces.
- **`apps/api/src/workers/` shares the same codebase as HTTP.** Same Drizzle, same Valkey client, same domain logic — just a different entry point. At v1 you can run the worker in the same process as the HTTP server (set `WORKER_ENABLED=true`); at scale you split it. No code changes needed for the split.
- **`apps/cli/src/commands/hooks/` is one file per Claude Code hook event.** Hook handlers are ~10 lines each (parse stdin → enqueue → exit). They share an `enqueue.ts` and never import network code, which makes the `hook handler must not block` rule structurally enforced.
- **`packages/shared/schemas/` is the wire contract.** A Zod schema is simultaneously: a runtime validator on the backend, a TypeScript type on all three apps, and a (via `drizzle-zod`) DB row shape. One source of truth.
- **`packages/content/` is the design surface.** Quest authors and balance tweaks happen here without touching engine code. Lets you ship a balance patch as a version bump of one package.

## Wire Protocols

This is the question the project most needs answered. Three pairs, three protocols.

### 1. Helper CLI ↔ Backend — Batched HTTPS POST with Bearer Token

**Choice:** REST over HTTPS, batched, fire-and-forget from a local SQLite outbox.

**Why not gRPC, WebSocket, webhooks:**
- **gRPC** requires HTTP/2 and adds a Protobuf toolchain to a project where every byte of CLI install footprint matters. Doesn't earn its weight here.
- **WebSocket** wants to stay open. Hooks are spiky (a flurry of events around a session, then silence). A persistent socket from every user's machine is worse for both the user (idle connection) and the backend (file descriptors).
- **Webhooks** are backwards — *we* would be the webhook receiver, but the helper isn't a public service, so the model doesn't fit.

**Endpoints:**
```
POST /v1/events                      # Batched event ingestion (the hot path)
GET  /v1/me                          # Current user's gamification snapshot
GET  /v1/me/quests/today             # Today's 5 quests + progress
GET  /v1/me/cosmetics/active         # Resolved cosmetic loadout
POST /v1/refresh                     # Refresh OAuth access token
```

**Event ingest payload (the only request that runs on every Claude Code session):**
```json
POST /v1/events
Authorization: Bearer <token>
Idempotency-Key: <uuid-v7>
Content-Type: application/json

{
  "client_version": "0.4.2",
  "device_id": "<stable per-install uuid>",
  "events": [
    {
      "id": "<uuid-v7>",                  // dedup across retries
      "kind": "session_start",
      "ts": "2026-05-08T14:31:08.117Z",   // ISO 8601 UTC
      "session_id": "<claude code session>",
      "data": { "model": "claude-opus-4-7", "cwd_hash": "..." }
    },
    {
      "id": "<uuid-v7>",
      "kind": "user_prompt_submit",
      "ts": "2026-05-08T14:31:42.003Z",
      "session_id": "<claude code session>",
      "data": { "tokens_in": 1247 }
    },
    { ... }
  ]
}

→ 202 Accepted
{ "accepted": 12, "duplicates": 0, "rejected": 0 }
```

**Properties this design buys:**
- **Idempotent.** Each event has its own UUID v7 (sortable, generated client-side); the backend dedups on `(user_id, event.id)`. Retries are safe forever.
- **Offline-tolerant.** Hook handlers write to local SQLite. The flusher posts when network is available. Power loss is fine — SQLite is durable, hooks already returned success to Claude Code.
- **Bounded concurrency.** `p-queue` caps in-flight requests; one batch at a time is fine for a single user.
- **No new round trip per hook.** Hooks return in <50ms because they only insert one row into a local SQLite file.
- **Bearer auth, not session cookies.** Cookies require browser context; bearer tokens (from device pairing) are clean for headless CLIs.

**Batch policy:** Flush on session end, on outbox depth ≥ 50, or every 30s while idle, whichever comes first. Tuning these is cheap (CLI config); the protocol doesn't change.

**Why no payload signing in v1:** The PROJECT.md explicitly accepts that lightweight anti-cheat is sufficient. HMAC-signing every event from a CLI binary that's open source provides ~zero security (anyone can read the signing code) at meaningful UX cost (token rotation, signing overhead). Defer until/unless real abuse appears.

### 2. Web App ↔ Backend — REST + SSE

**Choice:** REST for state-changing and one-shot reads, SSE for live pushes. No GraphQL, no tRPC for v1.

**Why not GraphQL:** Surface area is small and the access patterns are well-known (profile, quests, leaderboards, comments). GraphQL's flexibility earns its complexity at much larger schemas. Add later if a v2 raid system needs it.

**Why not tRPC for v1:** tRPC binds the client to the server's TS types tightly, which is great for DX but creates one more layer of churn early in the project. Stick with `Zod schemas in packages/shared` — same end-to-end typing, looser coupling, and the helper CLI uses the same schemas.

**Routes:**
```
# Auth (Better Auth managed, mounted at /api/auth/*)
POST /api/auth/sign-up/email
POST /api/auth/sign-in/email
POST /api/auth/sign-out
GET  /api/auth/session
POST /api/auth/device/code             # CLI starts pairing
POST /api/auth/device/token            # CLI polls
GET  /device                           # browser confirms (SvelteKit page)
POST /api/auth/device/approve          # browser confirm action

# Public read (no auth required)
GET  /v1/u/:handle                     # public profile
GET  /v1/u/:handle/badges
GET  /v1/leaderboards/:dimension       # raw | streak | xp | efficiency
GET  /v1/quests/today                  # today's 3 global quests (everyone sees same)

# Authenticated read
GET  /v1/me
GET  /v1/me/quests/today               # 3 global + 2 personalized
GET  /v1/me/achievements
GET  /v1/me/feed                       # friend activity feed

# Authenticated write
POST /v1/me/handle                     # claim/change handle (rate-limited)
POST /v1/me/cosmetics/loadout
POST /v1/me/friends/:handle            # follow
DEL  /v1/me/friends/:handle            # unfollow
POST /v1/u/:handle/comments
POST /v1/reports                       # moderation reports

# Live (SSE)
GET  /v1/sse/leaderboards/:dimension   # rank deltas as they happen
GET  /v1/sse/me                        # this user's quest progress + unlocks
```

**Why SSE over WebSocket:**
- **Read-heavy.** Live updates flow server → browser. The browser doesn't push back — it sends discrete actions over REST.
- **Auto-reconnect is built in.** Browsers retry SSE connections automatically with `Last-Event-ID`. With WebSockets you write the reconnect/backoff logic yourself.
- **Plays well with proxies.** SSE is just HTTP; WebSockets need explicit upgrade-header support that some load balancers and corporate proxies break.
- **Hono ships it natively.** Confirmed via Context7: `streamSSE` is in `hono/streaming` and just works on the Node adapter.

**Concrete SSE example (from Hono docs):**
```typescript
import { streamSSE } from 'hono/streaming'

app.get('/v1/sse/leaderboards/:dimension', auth(), (c) =>
  streamSSE(c, async (s) => {
    const dim = c.req.param('dimension')
    const sub = valkey.duplicate()
    await sub.subscribe(`leaderboard:${dim}:updates`)

    sub.on('message', async (_ch, msg) => {
      await s.writeSSE({
        event: 'rank_update',
        data: msg,
        id: String(Date.now()),
      })
    })

    // keepalive
    while (!c.req.raw.signal.aborted) {
      await s.sleep(15000)
      await s.writeSSE({ event: 'ping', data: '' })
    }
  })
)
```

**Bridge between workers and SSE:** workers `PUBLISH leaderboard:xp:updates "..."` to Valkey; HTTP servers subscribed to that channel forward to connected SSE clients. This means N HTTP servers can fan out to all connected browsers without coordinating with each other — Valkey pub/sub is the bus.

**v2 hook for raids:** when raid coordination needs bidirectional traffic, add a single `/v1/ws/raid/:id` endpoint and let SSE keep doing the read fan-out. Don't refactor v1 to WebSocket-everything.

### 3. Browser ↔ Helper CLI for Device Pairing — RFC 8628 (Indirect via Backend)

**Choice:** OAuth 2.0 Device Authorization Grant, exactly as specified by RFC 8628 and implemented by Better Auth's `deviceAuthorization` plugin (confirmed via Context7 docs).

**Critical clarification:** the browser and the helper CLI never talk to each other directly. They both talk to the backend. This is intentional — direct browser↔CLI communication via localhost callbacks would require the CLI to bind a port (which fights with corporate firewalls and feels invasive on the user's machine). The device flow was designed exactly for this case.

**Sequence:**

```
User                CLI                       Backend                 Browser
 │                   │                            │                      │
 │  cli pair         │                            │                      │
 │ ─────────────────►│                            │                      │
 │                   │  POST /device/code         │                      │
 │                   │  (client_id, scope)        │                      │
 │                   │ ──────────────────────────►│                      │
 │                   │                            │                      │
 │                   │  { device_code, user_code, │                      │
 │                   │    verification_uri,       │                      │
 │                   │    verification_uri_       │                      │
 │                   │    complete, interval }    │                      │
 │                   │ ◄──────────────────────────│                      │
 │                   │                            │                      │
 │  prints user_code │                            │                      │
 │  & opens browser  │                            │                      │
 │ ◄─────────────────│                            │                      │
 │                   │                            │                      │
 │                   │                            │  GET /device?        │
 │                   │                            │   user_code=...      │
 │                   │                            │ ◄────────────────────│
 │                   │                            │                      │
 │  signs in /       │                            │  (sign in flow)      │
 │  signs up         │                            │ ─────────────────────►
 │                   │                            │                      │
 │                   │                            │  POST /device/       │
 │                   │                            │       approve        │
 │                   │                            │ ◄────────────────────│
 │                   │                            │                      │
 │                   │  POST /device/token        │                      │
 │                   │  (poll every `interval`s)  │                      │
 │                   │ ──────────────────────────►│                      │
 │                   │                            │                      │
 │                   │  { access_token,           │                      │
 │                   │    refresh_token, ... }    │                      │
 │                   │ ◄──────────────────────────│                      │
 │                   │                            │                      │
 │                   │  store via `conf`          │                      │
 │                   │  in OS config dir          │                      │
 │                   │                            │                      │
 │  "✓ Paired as     │                            │                      │
 │   @handle"        │                            │                      │
 │ ◄─────────────────│                            │                      │
```

**Why this is the right choice:**
- **No port binding.** The CLI never opens a server socket. Works inside any firewall, container, or remote SSH session.
- **Familiar UX.** This is exactly how `gh auth login`, `claude` itself, `aws sso login`, `npm login` (modern), and `vercel login` work.
- **Spec-compliant.** RFC 8628 is the IETF standard for this case. Better Auth ships it as a plugin; we don't write the protocol — we configure it.
- **Self-hostable.** Forks point their CLI at their own backend by changing one config value. No external IDP dependency.

**Token lifecycle:**
- **access_token:** ~1h, used as `Authorization: Bearer ...` on every backend call.
- **refresh_token:** long-lived, used by the CLI to silently rotate access tokens.
- **revocation:** user can revoke from `/settings/devices`; backend invalidates the refresh token; the next access-token rotation fails and the CLI prompts re-pairing.

## Data Model Sketches

Drizzle schema sketches for the major aggregates. Generated SQL is straight Postgres 17.

### User, Account, Handle

```typescript
// Better Auth manages `account` and `session` tables itself; this is the app's
// extension table for identity that's project-specific.

users = pgTable('users', {
  id: text('id').primaryKey(),                  // matches Better Auth user id
  handle: text('handle').notNull().unique(),    // public, lowercase, ^[a-z0-9_]{3,20}$
  display_handle: text('display_handle').notNull(), // user's preferred casing
  email: text('email').notNull().unique(),      // mirrored from auth.user
  bio: text('bio'),
  joined_at: timestamp('joined_at').notNull().defaultNow(),
  shadow_banned: boolean('shadow_banned').notNull().default(false),
  shadow_ban_reason: text('shadow_ban_reason'),
  total_xp: integer('total_xp').notNull().default(0),     // denorm for fast reads
  current_streak_days: integer('current_streak_days').notNull().default(0),
  longest_streak_days: integer('longest_streak_days').notNull().default(0),
  last_active_at: timestamp('last_active_at'),
})

handles_history = pgTable('handles_history', {
  user_id: text('user_id').references(() => users.id),
  old_handle: text('old_handle').notNull(),
  changed_at: timestamp('changed_at').notNull().defaultNow(),
})  // squat-prevention: rate-limit handle changes, keep history
```

The Twitch-style "real handle" model means handle uniqueness is paramount. `handles_history` exists so a freed handle has a cooldown before reuse and so moderation can trace identity changes.

### Quest — three-table split

```typescript
// 1. Definition: the immutable description of a quest type, lives in
//    packages/content/quests/ and is loaded into the DB on deploy.
quest_definitions = pgTable('quest_definitions', {
  id: text('id').primaryKey(),                  // 'send_50_messages_v1'
  difficulty: text('difficulty').notNull(),     // easy | medium | hard
  category: text('category').notNull(),         // activity | efficiency | exploration | streak
  title: text('title').notNull(),
  description: text('description').notNull(),
  rule: jsonb('rule').notNull(),                // declarative rule, see below
  xp_reward: integer('xp_reward').notNull(),
  active: boolean('active').notNull().default(true),
})

// 2. Assignment: which quest this user is doing today.
//    5 rows per user per day: 3 global (same for everyone) + 2 personalized.
quest_assignments = pgTable('quest_assignments', {
  id: text('id').primaryKey(),
  user_id: text('user_id').notNull().references(() => users.id),
  quest_def_id: text('quest_def_id').notNull().references(() => quest_definitions.id),
  slot: text('slot').notNull(),                 // 'global_easy' | 'global_med' | 'global_hard' | 'personal_skill' | 'personal_growth'
  assigned_for: date('assigned_for').notNull(), // the quest's "day"
  expires_at: timestamp('expires_at').notNull(),
}, (t) => ({
  uniq: uniqueIndex().on(t.user_id, t.slot, t.assigned_for),
}))

// 3. Progress: how much progress the user has on this assignment.
//    Updated incrementally as events arrive.
quest_progress = pgTable('quest_progress', {
  assignment_id: text('assignment_id').primaryKey().references(() => quest_assignments.id),
  current_value: integer('current_value').notNull().default(0),
  target_value: integer('target_value').notNull(),
  completed_at: timestamp('completed_at'),
  xp_awarded: boolean('xp_awarded').notNull().default(false),
  updated_at: timestamp('updated_at').notNull().defaultNow(),
})
```

**Why three tables, not one:** definitions are static and small (rotate the whole catalog at deploy); assignments are the per-day pivot (one row per user-quest-slot-day, easy to index); progress is hot (one row updated per event). Splitting them keeps the hot table narrow and lets you cheaply join definitions when displaying.

**Rule format example (`quest_definitions.rule`):**
```json
{
  "kind": "counter",
  "match": { "event_kind": "user_prompt_submit" },
  "target": 50,
  "window": "today_local"
}
```

The quest engine is a small interpreter for these rules. Adding a new quest type is a content change, not a code change.

### Achievement — definition vs unlock

```typescript
achievement_definitions = pgTable('achievement_definitions', {
  id: text('id').primaryKey(),                  // 'first_session', 'token_marathon_1m'
  title: text('title').notNull(),
  description: text('description').notNull(),
  flavor_text: text('flavor_text'),
  rule: jsonb('rule').notNull(),                // same DSL as quests, but lifetime/feat-based
  cosmetic_id: text('cosmetic_id').references(() => cosmetics.id),
  rarity: text('rarity').notNull(),             // common | rare | epic | legendary
  hidden: boolean('hidden').notNull().default(false),  // surprise unlocks
})

achievement_unlocks = pgTable('achievement_unlocks', {
  user_id: text('user_id').notNull().references(() => users.id),
  achievement_id: text('achievement_id').notNull().references(() => achievement_definitions.id),
  unlocked_at: timestamp('unlocked_at').notNull().defaultNow(),
  evidence: jsonb('evidence'),                  // event ids that triggered it (audit)
}, (t) => ({
  pk: primaryKey({ columns: [t.user_id, t.achievement_id] }),
}))
```

**Achievements vs quests:** quests have a fixed window (today) and reset; achievements are lifetime feats and never reset. Same rule DSL, different evaluation cadence. Quests evaluated on every event; achievements evaluated by a periodic worker (hourly is fine).

### Leaderboards — Valkey-primary, Postgres mirror

Leaderboards live in **Valkey sorted sets** (the canonical primitive — confirmed by Redis's official leaderboard guide).

```
Key                                Members
─────────────────────────────────  ──────────────────────────────────────
lb:raw:alltime                     <user_id> ─► raw activity score
lb:raw:weekly:2026-W19             <user_id> ─► raw activity score this week
lb:streak:current                  <user_id> ─► current streak days
lb:xp:alltime                      <user_id> ─► quest XP total
lb:xp:weekly:2026-W19              <user_id> ─► quest XP this week
lb:efficiency:weekly:2026-W19      <user_id> ─► efficiency score this week
```

**Why a sorted set per (dimension, window):** ranges, ranks, and percentile queries are O(log N + M). A weekly board is just a separate key that ages out via TTL. No partitioning logic — the key itself is the partition.

**Postgres mirror:** for each "this week's leaderboard", a worker periodically snapshots the top 1,000 into a `leaderboard_snapshots` table so historical boards survive a Valkey wipe and can be displayed without keeping infinite weekly ZSETs in memory:

```typescript
leaderboard_snapshots = pgTable('leaderboard_snapshots', {
  dimension: text('dimension').notNull(),
  window: text('window').notNull(),             // 'alltime' | '2026-W19' | etc.
  user_id: text('user_id').notNull(),
  rank: integer('rank').notNull(),
  score: bigint('score', { mode: 'number' }).notNull(),
  snapshot_at: timestamp('snapshot_at').notNull().defaultNow(),
}, (t) => ({
  pk: primaryKey({ columns: [t.dimension, t.window, t.user_id] }),
  rank_idx: index().on(t.dimension, t.window, t.rank),
}))
```

**Tie-breaking:** Valkey ZSET uses the score; ties are lexicographic by member id. Document this; users won't care and it's deterministic.

**Window resets:** the `weekly:YYYY-WW` keying means there's never a "reset" — a new key just starts existing. Old keys age out via TTL (keep last 4 weeks live in Valkey, archive to Postgres beyond that). This sidesteps the timezone-reset trap (you don't need atomic Lua resets because there's no global moment of reset).

### Cosmetic — definition + unlock + loadout

```typescript
cosmetics = pgTable('cosmetics', {
  id: text('id').primaryKey(),                  // 'badge_first_quest', 'glyph_streak_30'
  kind: text('kind').notNull(),                 // 'badge' | 'glyph' | 'theme'
  name: text('name').notNull(),
  asset: jsonb('asset').notNull(),              // ANSI string / pixel art ref / theme tokens
  animated: boolean('animated').notNull().default(false),
})

// Unlocks are derived from achievement_unlocks via cosmetic_id, but we store
// a flat unlock table for fast lookup ("does user X have cosmetic Y?")
cosmetic_unlocks = pgTable('cosmetic_unlocks', {
  user_id: text('user_id').notNull().references(() => users.id),
  cosmetic_id: text('cosmetic_id').notNull().references(() => cosmetics.id),
  unlocked_at: timestamp('unlocked_at').notNull().defaultNow(),
}, (t) => ({
  pk: primaryKey({ columns: [t.user_id, t.cosmetic_id] }),
}))

// User's currently-equipped cosmetics. One row per slot.
cosmetic_loadouts = pgTable('cosmetic_loadouts', {
  user_id: text('user_id').notNull().references(() => users.id),
  slot: text('slot').notNull(),                 // 'badge_primary' | 'glyph_streak' | 'theme'
  cosmetic_id: text('cosmetic_id').notNull().references(() => cosmetics.id),
}, (t) => ({
  pk: primaryKey({ columns: [t.user_id, t.slot] }),
}))
```

The PROJECT.md rule is clear: every cosmetic ties to exactly one achievement. `cosmetics.id ↔ achievement_definitions.cosmetic_id` is 1:1. The unlock table exists for query convenience; it's derived state.

### Friend graph — relational, not Neo4j

```typescript
follows = pgTable('follows', {
  follower_id: text('follower_id').notNull().references(() => users.id),
  followee_id: text('followee_id').notNull().references(() => users.id),
  followed_at: timestamp('followed_at').notNull().defaultNow(),
}, (t) => ({
  pk: primaryKey({ columns: [t.follower_id, t.followee_id] }),
  followee_idx: index().on(t.followee_id, t.follower_id),  // for "who follows me"
}))
```

**Why Postgres, not a graph DB:** the project's social model is a simple directed follow graph (Twitter-style). The expensive query a graph DB would crush is "friends of friends N hops out" — and the project has no feature that needs depth-N traversal. Comments, feeds, and "who do I follow" are 1-hop joins, which Postgres does fine into the millions of edges with the right indexes.

**Reconsider if/when:** v2 raids introduce coordinated party graphs with depth-N reachability queries, OR the friend feed needs "second-degree connections you might know" recommendations. Neither is in v1.

### Comments

```typescript
profile_comments = pgTable('profile_comments', {
  id: text('id').primaryKey(),
  profile_user_id: text('profile_user_id').notNull().references(() => users.id),
  author_user_id: text('author_user_id').notNull().references(() => users.id),
  body: text('body').notNull(),
  created_at: timestamp('created_at').notNull().defaultNow(),
  hidden: boolean('hidden').notNull().default(false),     // moderation soft-delete
  hidden_reason: text('hidden_reason'),
}, (t) => ({
  profile_idx: index().on(t.profile_user_id, t.created_at),
}))
```

Public + real handle means the comments table is a moderation surface from day one. Soft-delete (`hidden=true`), reports table, and per-user mute lists need to ship in v1.

### Raw events + rollups — how time-series activity actually lives

```typescript
// The raw event log: append-only, every signal the helper emits.
// This is the source of truth for re-evaluating quests/achievements after a rule change.
events = pgTable('events', {
  id: uuid('id').primaryKey(),                  // UUID v7, sortable by time
  user_id: text('user_id').notNull().references(() => users.id),
  device_id: text('device_id').notNull(),
  client_version: text('client_version').notNull(),
  kind: text('kind').notNull(),                 // 'session_start', 'user_prompt_submit', etc.
  ts: timestamp('ts').notNull(),                // event timestamp from client
  received_at: timestamp('received_at').notNull().defaultNow(),
  session_id: text('session_id'),
  data: jsonb('data').notNull(),
}, (t) => ({
  user_ts_idx: index().on(t.user_id, t.ts.desc()),
  user_kind_ts_idx: index().on(t.user_id, t.kind, t.ts.desc()),
}))

// Daily rollups computed by a worker. The hot path for "what's my XP today?"
// reads from here, not from raw events.
daily_user_stats = pgTable('daily_user_stats', {
  user_id: text('user_id').notNull().references(() => users.id),
  day: date('day').notNull(),                   // user's local day
  raw_activity_score: integer('raw_activity_score').notNull().default(0),
  xp_earned: integer('xp_earned').notNull().default(0),
  efficiency_score: integer('efficiency_score').notNull().default(0),
  sessions: integer('sessions').notNull().default(0),
  prompts: integer('prompts').notNull().default(0),
  tokens_in: bigint('tokens_in', { mode: 'number' }).notNull().default(0),
  tokens_out: bigint('tokens_out', { mode: 'number' }).notNull().default(0),
}, (t) => ({
  pk: primaryKey({ columns: [t.user_id, t.day] }),
}))
```

**Storage strategy for time-series:**
- **At hundreds of users:** vanilla Postgres with the indexes above is fine. A single user generating ~500 events/day × 1,000 users × 365 days = ~180M rows/year, which Postgres handles comfortably with periodic partitioning.
- **At thousands:** add monthly partitioning on `events` by `received_at`. Drop old partitions when raw events are no longer needed (rollups have what we need).
- **At tens of thousands:** consider TimescaleDB extension on the `events` hypertable. It's a Postgres extension — same SQL, same Drizzle schema — that adds automatic partitioning, compression, and continuous aggregates for the rollup tables. **Don't add it on day one;** it's free to add later.
- **Don't add InfluxDB / TimescaleDB Cloud / dedicated TSDB.** Splitting stores doubles your operational surface and the workload is fundamentally relational (joining events to users, quests, achievements).

## Hook Ingestion — How Claude Code Hooks Reach the Backend

Per Claude Code docs, hooks fire as configured commands; Claude Code passes JSON about the event over **stdin** to the configured command. Output on stdout (when the hook is allowed to influence behavior) is parsed back as JSON.

The CLI exposes one subcommand per hook event:

```bash
# In ~/.claude/settings.json
{
  "hooks": {
    "SessionStart": [
      { "hooks": [{ "type": "command", "command": "npx -y @gsd/cli hook session-start" }] }
    ],
    "UserPromptSubmit": [
      { "hooks": [{ "type": "command", "command": "npx -y @gsd/cli hook user-prompt-submit" }] }
    ],
    "Stop": [
      { "hooks": [{ "type": "command", "command": "npx -y @gsd/cli hook stop" }] }
    ],
    "SessionEnd": [
      { "hooks": [{ "type": "command", "command": "npx -y @gsd/cli hook session-end" }] }
    ]
  }
}
```

Each hook subcommand does exactly three things:

```typescript
// apps/cli/src/commands/hooks/user-prompt-submit.ts (sketch)
export async function userPromptSubmit() {
  // 1. Read JSON from stdin (Claude Code's hook payload)
  const payload = await readStdin()

  // 2. Insert one row into local SQLite outbox. Synchronous, ~1ms.
  enqueue({
    id: uuidv7(),
    kind: 'user_prompt_submit',
    ts: new Date().toISOString(),
    session_id: payload.session_id,
    data: { /* whatever Claude Code gave us */ },
  })

  // 3. Exit 0 immediately. No network call here.
}
```

**The latency budget is met by structure, not by optimization:** hook subcommands literally cannot block on network because they don't have networking code in their import graph. The flusher is a separate process spawned (or warmed) on `SessionStart` that handles the actual upload.

### The flusher daemon

`SessionStart` does double duty: enqueues the session-start event AND ensures the flusher daemon is running (e.g., a long-lived background process started with `cli flush --daemon` on first session). The daemon:

1. Polls the SQLite outbox every N seconds (default: 5s during active session, 30s when idle).
2. Reads up to 50 events (sorted by `id`, which is UUID v7 = time-sortable).
3. POSTs them in one batch with `Idempotency-Key`.
4. On 2xx: deletes the rows from the outbox.
5. On retryable error (5xx, network failure): exponential backoff up to 5 minutes, retries forever.
6. On 4xx other than 401: logs and gives up on those rows (they're broken).
7. On 401: triggers refresh-token rotation.

**`SessionEnd` triggers an immediate flush** so the user sees their post-session XP fast.

**Statusline read path:** the statusline calls `cli stats`, which reads from a small `~/.gsd-cache.json` (or SQLite) that the flusher updates every time it gets a snapshot back from `/v1/me`. The statusline never blocks on network. If offline, it shows the last-known state with an `(offline)` indicator.

## Anti-Cheat Placement

**Authoritative anti-cheat lives on the backend. The client does no validation that matters.**

This is non-negotiable in an open-source project where the client is auditable and patchable. Lightweight server-side validation per the PROJECT.md spec:

| Layer | Check | Where it runs |
|-------|-------|---------------|
| **Schema** | Event payload matches Zod schema; rejected if not | At `/v1/events` ingest, synchronous |
| **Velocity** | No more than N events of kind K per minute per user (configurable per kind); excess silently dropped (don't 4xx — that signals to a cheater what to tune) | At `/v1/events` ingest, Valkey rate counter |
| **Plausibility** | Token counts within Anthropic-published ranges, session durations within human ranges, no time travel (`ts` not in future, not too old) | At `/v1/events` ingest |
| **Cross-source** | Compare claimed token usage against Anthropic OAuth usage API; flag if claimed >> reported | Periodic worker (hourly), per user |
| **Anomaly sweep** | Statistical outliers across the user base (sudden 100x activity, perfectly periodic events suggesting a bot) | Periodic worker (daily) |
| **Shadow ban** | Flagged users continue to see their own scores rise but are excluded from public leaderboards. They don't know they're banned (this is the entire point of "shadow"). | All public leaderboard reads filter `users.shadow_banned = false` |

**What the client does:** nothing security-relevant. It might do trivial sanity (don't enqueue events with no `session_id`), but it never tries to "verify" anything because verification on attacker-controlled hardware is theatre.

**What the client must not do:** sign payloads with embedded secrets, run obfuscated event normalization, or "validate" anything before submission. Those are all costly to implement and provide ~zero security in OSS.

**Anti-cheat against the user's own benefit:** the velocity-cap-on-ingest design means a cheating user can't even harm themselves much without our cooperation. We accept some level of casual gaming (the PROJECT.md is explicit about this) and concentrate effort on protecting public leaderboards.

## Suggested Build Order

The dependency graph is strict; build order falls out of it.

```
                        ┌─────────────────────────────┐
                        │  Phase 1: Backend skeleton  │
                        │  - Hono + Drizzle + Postgres│
                        │  - Valkey + BullMQ          │
                        │  - Better Auth (email/pass) │
                        │  - users + handles tables   │
                        └─────────────┬───────────────┘
                                      │
                ┌─────────────────────┼─────────────────────┐
                │                     │                     │
                ▼                     ▼                     ▼
   ┌──────────────────────┐ ┌────────────────────┐ ┌─────────────────┐
   │ Phase 2: Device flow │ │ Phase 3: Ingest    │ │ Phase 4: Web    │
   │ - deviceAuthorization│ │ - /v1/events       │ │   minimum       │
   │   plugin enabled     │ │ - events table     │ │ - /signup, /me  │
   │ - /device page       │ │ - rate limits      │ │ - Better Auth UI│
   └──────────┬───────────┘ │ - daily_user_stats │ │ - SvelteKit     │
              │             │   rollup worker    │ └────────┬────────┘
              ▼             └─────────┬──────────┘          │
   ┌──────────────────────┐           │                     │
   │ Phase 5: CLI helper  │ ◄─────────┘                     │
   │ - pair command       │                                 │
   │ - hook subcommands   │                                 │
   │ - SQLite outbox      │                                 │
   │ - flusher daemon     │                                 │
   │ - stats command      │                                 │
   └──────────┬───────────┘                                 │
              │                                             │
              └────────────────────┬────────────────────────┘
                                   │
                                   ▼
                ┌──────────────────────────────────┐
                │ Phase 6: Quest engine            │
                │ - quest_definitions/assignments/ │
                │   progress tables                │
                │ - rule interpreter               │
                │ - daily rotation worker          │
                │ - /v1/me/quests/today endpoint   │
                │ - quests UI in web               │
                └────────────────┬─────────────────┘
                                 │
                                 ▼
                ┌──────────────────────────────────┐
                │ Phase 7: Achievements +cosmetics │
                │ - achievement_definitions/unlocks│
                │ - cosmetic tables                │
                │ - hourly evaluation worker       │
                │ - badge case UI                  │
                └────────────────┬─────────────────┘
                                 │
                                 ▼
                ┌──────────────────────────────────┐
                │ Phase 8: Leaderboards            │
                │ - 4 dimensions, ZSET keys        │
                │ - score-update worker            │
                │ - /v1/leaderboards/:dim          │
                │ - /v1/sse/leaderboards/:dim      │
                │ - leaderboards UI in web         │
                └────────────────┬─────────────────┘
                                 │
                                 ▼
                ┌──────────────────────────────────┐
                │ Phase 9: Social hub              │
                │ - follows, comments, feed        │
                │ - public profile pages           │
                │ - moderation tools               │
                └────────────────┬─────────────────┘
                                 │
                                 ▼
                ┌──────────────────────────────────┐
                │ Phase 10: Anti-cheat hardening   │
                │ - cross-source token check       │
                │ - daily anomaly sweep            │
                │ - shadow-ban surfaces            │
                │ - moderator/admin endpoints      │
                └──────────────────────────────────┘
```

### Build order rationale

1. **Backend skeleton must come first.** Nothing else has anywhere to talk to.
2. **Device flow before CLI.** The CLI is useless without a server that accepts pairings. Build `/device/code` and the `/device` confirmation page first; smoke-test with `curl` and a browser before writing CLI code.
3. **Event ingest before quests.** Quests are interpreters over events. Build the substrate before the interpreter.
4. **Web minimum can be parallel** with phases 2–3 because it doesn't depend on game features — it only needs auth and basic user pages. A team of two can split here.
5. **CLI ships last in the foundation tier (phase 5).** Once `/device/*` and `/v1/events` exist, the CLI is "just" a Node app that calls them. This is also the last point at which the wire protocol can be cheaply changed.
6. **Quests before achievements** even though achievements seem simpler. Quests prove the rule-DSL design end-to-end on a daily cadence; achievements then reuse the proven DSL on a lifetime cadence.
7. **Leaderboards after achievements** because rank computations depend on the rollup tables that the quest/achievement workers populate.
8. **Social hub last among feature tiers.** Comments/follows are independently testable but need real users to be useful. Defer the moderation surface area until the rest exists.
9. **Anti-cheat hardening throughout, but its own phase for the heavy passes.** Schema/velocity checks ship in Phase 3; cross-source and anomaly sweeps come once there's enough data to detect anomalies in.

### Hard dependencies (the things you can't reorder)

- **Backend ↔ everything:** axiomatic.
- **Auth + device flow → CLI pair command.** The CLI cannot exist meaningfully without it.
- **Event ingest → CLI hooks.** The CLI hook commands need somewhere to send events.
- **Daily rollup worker → quest engine and leaderboards.** Both read from `daily_user_stats`.
- **Rule DSL (introduced for quests) → achievements (reuses DSL).** Build the DSL once.
- **Cosmetic table → achievement definitions reference cosmetics.** Build cosmetics table before achievement seeding.

### Soft dependencies (could go in either order if you wanted)

- Achievements vs leaderboards: both depend on the rollup worker; either could come first. Recommended order is achievements first because they exercise more of the rule DSL.
- Friend feed vs comments: independent.
- Moderation tools vs anti-cheat sweep: both write to the same shadow-ban column; either order fine.

## Scaling Path

Hosting hundreds of users initially, scaling path **must not require a rewrite**. The architecture above already pencils to ~10k users on commodity hardware with no design changes; here are the transition points.

| Scale | What changes | What doesn't |
|-------|-------------|---------------|
| **0 – 500 users** | Single VM. API + workers in one process. Postgres + Valkey on same VM. Docker Compose. | Schema, wire protocol, code structure |
| **500 – 5k users** | Split workers into a separate process (still same code, different entry). Move Postgres to managed (Fly Postgres / Neon). Move Valkey to managed (Upstash / DragonflyDB). Add Cloudflare in front for CDN + DDoS. | Schema, wire protocol, app structure |
| **5k – 50k users** | Multiple API replicas behind a load balancer. Valkey pub/sub becomes the cross-replica bus for SSE (already designed for this). Add Postgres read replica for `/v1/u/:handle` and leaderboard snapshots. Partition `events` table by month. | Schema (additive only), wire protocol, app structure |
| **50k – 500k users** | TimescaleDB extension on `events`. Worker fleet split by queue (anti-cheat workers separate from quest workers). Possibly CDN-cache `/v1/u/:handle` and leaderboard top-100 endpoints. | Wire protocol, fundamental data model |
| **500k+ users** | This is far enough out that it deserves its own re-evaluation, but the natural moves are: regional sharding of users (one Valkey + Postgres pair per region), event ingest split into a write-only fleet that lands events in Postgres + Kafka/Redpanda, and a separate read fleet. | Domain logic in `src/domain/` is reusable everywhere |

### Bottlenecks in the order they will appear

1. **Postgres write contention on the `events` table.** Mitigation: monthly partitioning (one DDL change). Trigger: when ingest p95 exceeds 200ms.
2. **Valkey memory for leaderboard ZSETs.** Mitigation: tighten weekly-key TTL, archive older windows to Postgres-only. Trigger: Valkey RSS approaches 1GB.
3. **HTTP server CPU during SSE fan-out.** Mitigation: scale horizontally, Valkey pub/sub already handles cross-replica fan-out. Trigger: SSE connection count > ~5k per replica.
4. **Quest evaluation latency.** Mitigation: rule DSL ships with an indexable predicate hint so quest progress only needs to recheck quests whose rule could plausibly match the event kind. Trigger: ingest worker queue depth grows during peak.
5. **Cross-source anti-cheat poll.** Mitigation: cache Anthropic usage responses; only re-poll when activity diverges. Trigger: rate-limit responses from Anthropic API.

### What the architecture gets right that prevents future rewrites

- **Workers and HTTP share a process at v1, separate at scale.** Same code, different entry. No refactor.
- **SSE fan-out via Valkey pub/sub.** Multi-replica from day one without writing it.
- **Idempotent event ingest with UUID v7.** Lets you retry or re-ingest entire backlogs (e.g., after a rule change) without dedup pain.
- **Rule DSL.** Adding new quests/achievements is a content change, not a schema change.
- **Domain layer with no I/O.** Test changes to game rules without spinning up Postgres.
- **Postgres-only relational store.** No premature heterogeneous-database tax.

### What the architecture deliberately does NOT do (and why that's right for hundreds of users)

- **No Kafka / Redpanda / NATS.** Valkey + BullMQ is enough until well past v1.
- **No graph DB.** Friend graph is shallow; relational handles it.
- **No GraphQL.** REST + Zod schemas is simpler at this scale.
- **No payload signing.** Adds friction, provides illusory security in OSS.
- **No microservices.** Modular monolith with separate worker process is sufficient until 50k+.
- **No CDN-cached read API.** Add when reads outscale Postgres replica throughput.
- **No dedicated TSDB.** Postgres with monthly partitioning + later TimescaleDB extension covers the path.

## Architectural Patterns

### Pattern 1: Modular Monolith with Pluggable Workers

**What:** One codebase, two entry points (`http-server.ts`, `worker.ts`). Same DB connection pool, same Valkey client, same domain modules. Switch a worker from in-process to separate-process by changing a deploy config; no code change.

**When to use:** Greenfield projects with small teams that need a clean scaling path. This is the right choice 90% of the time and the wrong choice exactly when you have multiple independent product surfaces with different deploy cadences.

**Trade-offs:** A monolith means the whole app deploys together, but at the team size this project will start at, that's a feature, not a bug. The cost is discipline: keep the domain layer pure or the modularity rots.

```typescript
// apps/api/src/http-server.ts
import { serve } from '@hono/node-server'
import { app } from './http/app'
import { env } from './env'
import { startWorkers } from './workers'

serve({ fetch: app.fetch, port: env.PORT })
if (env.WORKERS_IN_PROCESS) startWorkers() // v1 monolith mode
```

### Pattern 2: Outbox + Idempotent Receiver for Helper Ingest

**What:** Helper writes events to a local SQLite outbox; a flusher posts them with a UUID v7 id; backend dedups on `(user_id, event.id)`. At-least-once delivery; consumer is idempotent.

**When to use:** Any time a client must enqueue work without blocking and the wire is unreliable.

**Trade-offs:** Adds local storage to the helper (small — SQLite is one file). In return: zero hook latency, offline tolerance, retry safety, no dropped events on power loss.

### Pattern 3: Pure Domain + I/O Adapters

**What:** `src/domain/` contains only TS modules with no DB, network, or file I/O imports. I/O lives in `src/infra/`. HTTP handlers and workers compose domain functions with infra adapters.

**When to use:** Whenever the same logic runs from multiple entry points (HTTP, worker, CLI tool) — which is exactly this project.

**Trade-offs:** A small ceremony tax (passing repos as parameters instead of importing them globally). In exchange: domain tests run in milliseconds with no fixtures, and you can inline the worker in the HTTP process or split it without rewriting business logic.

```typescript
// src/domain/quests/evaluate.ts — pure
export function evaluateProgress(
  rule: QuestRule,
  event: Event,
  current: QuestProgress
): QuestProgress { /* ... */ }

// src/http/ingest.ts — composes domain with infra
const updated = evaluateProgress(def.rule, event, currentProgress)
await questRepo.saveProgress(updated)
```

### Pattern 4: Valkey ZSET as Leaderboard Primitive, Postgres as Source of Record

**What:** Leaderboard reads (rank lookups, top-N, percentile) hit Valkey. Score updates fan into both Valkey (immediate) and Postgres rollups (periodic). Postgres is the recovery source.

**When to use:** Any "ranked board" feature with hundreds-of-users-or-more cardinality.

**Trade-offs:** Two writes per score update. Mitigated because the Postgres write happens in the daily rollup worker, not on the hot path — the hot path is one `ZADD`.

### Pattern 5: Server-Authoritative Game State

**What:** All game state (XP, quest progress, achievements, rank) is computed and stored on the backend. The helper and web app both read it; neither computes it.

**When to use:** Any system where the client is untrusted (open source, user-controlled, or hostile network).

**Trade-offs:** Backend is the bottleneck for new feature design — every game change requires a backend deploy. That's correct and worth the cost.

### Pattern 6: Rule DSL for Quests and Achievements

**What:** Quests and achievements are described by JSON rules (counters, thresholds, sequences) rather than imperative code. A small interpreter evaluates rules against events.

**When to use:** When you'll have many similar rules with small variations and content authors who shouldn't need to write TypeScript.

**Trade-offs:** Initial DSL design takes thought. Deciding what's expressible in the DSL vs what requires a new "kind" is an ongoing balance. In return: most new quests/achievements are content PRs, not code PRs, which is essential for an OSS project.

## Anti-Patterns

### Anti-Pattern 1: Computing XP / Rank on the Client

**What people do:** "It's faster to compute XP locally and sync the result." So the helper calculates XP and posts the number.

**Why it's wrong:** The helper is open source and on the user's machine. There is no XP value the helper computes that we can trust. This sinks every leaderboard.

**Do this instead:** Helper sends raw signal events. Backend computes XP. Helper *displays* the result the backend returns.

### Anti-Pattern 2: Synchronous Hook Handlers That Touch the Network

**What people do:** Hook handler POSTs the event directly to the backend. "It's just one request."

**Why it's wrong:** Network latency is unbounded. Corporate proxies stall. DNS hangs. Captive portals exist. Any of these add seconds to a hook that has tens of milliseconds. The PROJECT.md is explicit: zero perceivable cost.

**Do this instead:** Hook handler enqueues into local SQLite and returns. A separate flusher process owns the network.

### Anti-Pattern 3: One Giant `events` Table That Lives Forever

**What people do:** Append every event forever to a single table; one day notice queries are slow and panic.

**Why it's wrong:** Postgres indexes degrade with cardinality. Vacuum cost grows. Backup time grows. Joining an unbounded events table to anything else gets slow.

**Do this instead:** Plan for monthly partitioning from day one (define the partitioning even if you only have one partition initially). Plan to drop or archive partitions older than your re-evaluation window (e.g., 90 days; older than that, you trust your rollups).

### Anti-Pattern 4: Storing OAuth Tokens in Plaintext Dotfiles

**What people do:** Helper stores `access_token` in `~/.gsdrc` as plain JSON.

**Why it's wrong:** Other processes on the user's machine can read it. Backups slurp it up. Screen-shares leak it.

**Do this instead:** Use `conf` (sindresorhus/conf), which writes to the OS-standard config dir with appropriate permissions; consider OS keychain integration (Keychain on macOS, libsecret on Linux, Credential Manager on Windows) for the refresh token specifically.

### Anti-Pattern 5: Trusting `Idempotency-Key` to be Unique Without Server-Side Dedup

**What people do:** "The client sends a key, so we'll just trust it's idempotent."

**Why it's wrong:** Clients can have bugs (or malice). The server must dedup, not assume.

**Do this instead:** Unique constraint on `(user_id, event.id)` in `events` table. Inserts with conflict do nothing. The server is the dedup, the client just provides the key.

### Anti-Pattern 6: WebSockets When You Only Need Server-Push

**What people do:** "Real-time means WebSockets." Builds a WS server for one-way push.

**Why it's wrong:** WebSockets are bidirectional; you only need one direction. You pay all the WebSocket costs (connection upgrade, heartbeat logic, reconnect logic, proxy compatibility) for nothing.

**Do this instead:** SSE for unidirectional push. It's HTTP. Browsers handle reconnect for free. Hono ships `streamSSE`. Reach for WebSockets when v2 raids actually need bidirectional traffic.

### Anti-Pattern 7: Direct Browser ↔ CLI Localhost Callback for Pairing

**What people do:** CLI binds a localhost port; browser redirects to `localhost:31415/callback?code=...`.

**Why it's wrong:** Corporate firewalls block it. Container environments don't have a host browser. SSH-into-remote-and-run-CLI is broken. Antivirus alerts on a CLI binding a port.

**Do this instead:** OAuth Device Authorization Grant (RFC 8628). The CLI never opens a port; it polls. Confirmed via Better Auth's `deviceAuthorization` plugin docs (Context7).

### Anti-Pattern 8: Shipping a Heavy Dependency Footprint to End Users

**What people do:** Helper CLI bundles 200+ npm packages and `npm install` takes 60 seconds.

**Why it's wrong:** Every CC user installs the helper. Slow installs erode trust on first contact. Each transitive dep is a supply-chain risk.

**Do this instead:** Audit the CLI's dep tree ruthlessly. Prefer `citty` (UnJS, tiny) over `commander`. Prefer `undici` (Node-native) over `axios`. Run `npm-pkg-size` in CI and fail the build above a threshold.

### Anti-Pattern 9: Coupling SvelteKit to Vercel-Only Features

**What people do:** Use Vercel ISR / edge middleware / image optimization. Self-hosters are stuck.

**Why it's wrong:** Project is OSS and self-hostable. Vercel-coupled features fork the codebase between hosted-instance and self-hosted-instance.

**Do this instead:** SvelteKit `adapter-node` everywhere. CDN-caching at Cloudflare/Caddy in front of the Node server, not in the framework.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| **Anthropic OAuth Usage API** (`api.anthropic.com/api/oauth/usage`) | Periodic poll (worker, every ~hour per active user) using user's existing OAuth token from `~/.claude/.credentials.json`. Cache 5h/7d window data in Postgres. | Token is read by the helper, never touches the backend (helper does the call and posts the parsed bars as a `usage_window` event). This keeps the user's Anthropic credential local. |
| **Email provider** (Resend / Postmark / SES) | Better Auth's email transport for verification + password reset. | Pluggable; choose at deploy. Self-hosters can use SMTP. |
| **OAuth providers** (GitHub, Google) (optional) | Better Auth's social sign-in. | Skip for v1 if email/password ships first; trivial to add later. |
| **Donation processor** (GitHub Sponsors / OpenCollective / Stripe) | Webhook receiver at `/v1/webhooks/donations`. | Recipe-quality only; the project is donations, not paid tiers. |
| **Sentry / Honeycomb / Grafana Cloud** | OpenTelemetry SDK exports. | Vendor-neutral by construction; self-hosters can point at their own stack. |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| HTTP routes ↔ Domain | Direct function call | Routes are thin; they parse, validate, call domain, serialize. |
| Domain ↔ Postgres | Drizzle queries via `infra/db/` | Repository functions, not raw queries scattered across domain. |
| Domain ↔ Valkey | ioredis client via `infra/cache/` | Wrap ZSET ops; never let raw `ZADD` calls litter the domain. |
| HTTP ↔ Workers | BullMQ job queues | HTTP enqueues, workers process. No direct HTTP-to-worker calls. |
| Workers ↔ HTTP (for SSE) | Valkey pub/sub | Workers `PUBLISH`; HTTP servers subscribed forward to SSE clients. |
| Web app ↔ Backend | REST + SSE over HTTPS | Cookies for browser auth, bearer for CLI auth; same backend. |
| Helper CLI ↔ Backend | Batched HTTPS POST + bearer token | OAuth refresh handled inside the flusher. |
| Helper CLI ↔ Statusline scripts | Subprocess call: `cli stats --json` | The contract is the CLI's stdout schema; users compose. |

## Sources

**Authoritative (HIGH confidence):**

- Context7 — `/better-auth/better-auth` — `deviceAuthorization` plugin docs including full CLI polling client and POST `/device/code` API spec — confirmed RFC 8628 implementation
- Context7 — `/honojs/hono` — `streamSSE` API in `hono/streaming` with `writeSSE({ event, data, id, retry })` confirmed
- [RFC 8628 — OAuth 2.0 Device Authorization Grant](https://datatracker.ietf.org/doc/html/rfc8628) — the protocol spec
- [Claude Code Hooks Reference (official docs)](https://code.claude.com/docs/en/hooks) — JSON-on-stdin protocol, hook event names (SessionStart, UserPromptSubmit, Stop, SessionEnd, etc.)
- [Redis Sorted Sets / Leaderboards (official tutorial)](https://redis.io/tutorials/howtos/leaderboard/) — canonical ZSET-as-leaderboard pattern; O(log N) updates, O(log N + M) range
- [Better Auth Device Authorization plugin docs](https://better-auth.com/docs/plugins/device-authorization) — `verificationUri` config, plugin mounting

**Strong supporting (MEDIUM-HIGH):**

- [Auth0 Device Authorization Flow guide](https://auth0.com/docs/get-started/authentication-and-authorization-flow/device-authorization-flow) — flow details
- [Microsoft Entra Device Code Flow](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-device-code) — alternate reference implementation
- [Curity OAuth Device Flow Explained](https://curity.io/resources/learn/oauth-device-flow/) — interaction-flow reference
- [Designing Real-Time Leaderboards (System Design Substack)](https://systemdr.substack.com/p/designing-real-time-leaderboards) — ZSET architecture patterns; rolling-window keying advice
- [How to Scale a Leaderboard Beyond Basic Redis (Trophy 2026)](https://trophy.so/blog/scaling-leaderboards-redis-architecture) — timezone-reset pitfalls; per-window keying
- [Transactional Outbox Pattern](https://microservices.io/patterns/data/transactional-outbox.html) — applied here as local-SQLite outbox in the helper
- [SvelteKit + Adapter-Node](https://svelte.dev/docs/kit/adapter-node) — non-Vercel deploy model
- [TimescaleDB extension for Postgres](https://github.com/timescale/timescaledb) — drop-in extension, deferred until ~50k users
- [Event-Driven.io: Audit log via event sourcing](https://event-driven.io/en/audit_log_event_sourcing/) — events table as audit / re-evaluation source
- [Memgraph: Graph DB vs Relational](https://memgraph.com/blog/graph-database-vs-relational-database) — confirmed shallow follow graph belongs in relational

**Domain prior art (MEDIUM):**

- [Habitica gamification analysis (Trophy 2025)](https://trophy.so/blog/habitica-gamification-case-study) — quest/reward dual-track precedent
- [Plausible vs Umami architecture comparison](https://aaronjbecker.com/posts/umami-vs-plausible-vs-matomo-self-hosted-analytics/) — self-hostable analytics with Postgres-only storage, batched event ingest
- [Steam VAC / Anti-cheat integration docs](https://partner.steamgames.com/doc/features/anticheat) — server-authoritative achievement validation precedent
- [Steam Achievement Integrity discussion (Quora)](https://www.quora.com/Can-you-cheat-Steam-achievements) — confirms server-side validation is the only protection that works

---
*Architecture research for: OSS gamification service for Claude Code (web + backend + helper module)*
*Researched: 2026-05-08*

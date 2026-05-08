# Stack Research

**Domain:** OSS gamification service for Claude Code (web app + backend + local helper module)
**Researched:** 2026-05-08
**Confidence:** HIGH for backend / DB / auth / hosting; HIGH for helper module language; MEDIUM for retro-arcade UI library specifics (smaller ecosystems)

## Executive Summary

Recommended stack — TypeScript end-to-end on Node.js LTS, Hono on the backend, PostgreSQL 17 + Redis 7 for storage, Better Auth (with the Device Authorization plugin for RFC 8628 browser-mediated CLI pairing), BullMQ for background jobs, SvelteKit + Tailwind v4 + 8bitcn/ui for the retro-arcade web app, Server-Sent Events for live leaderboard pushes, and a thin Node.js CLI distributed via `npm` (with optional Node SEA single-binary builds) for the helper module. Hosting on Fly.io for the app, with Docker Compose support for self-hosters.

Every choice below is OSS-license safe (MIT/Apache/BSD/ISC/PostgreSQL license — no GPL contagion risk in core dependencies), has zero vendor lock-in, and has a credible self-hosting story so forks can run their own instance end-to-end.

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **Node.js** | 22 LTS | Runtime for backend + helper module | LTS through April 2027, native test runner, native `fetch`, native SEA build flag. Node is non-negotiable for the helper module since Claude Code itself ships on Node and its hooks/statusline contracts assume Node availability — using the same runtime backend keeps one toolchain, one mental model, one set of deps. License: MIT. |
| **TypeScript** | 5.7+ | Language | Type safety across the wire (server → CLI → web) catches schema drift early. Better Auth, Drizzle, Hono, and SvelteKit are all TS-first. License: Apache-2.0. |
| **Hono** | 4.12.x | Backend HTTP framework | Ultra-fast, runs on Node/Bun/Deno/Workers (no lock-in if we ever change runtime), zero deps, first-class TS, clean middleware model, tiny bundle. Chosen over Fastify because Hono's runtime-portability and modern Web Standards API future-proof the project; chosen over Elysia because Elysia is Bun-only and the helper module needs Node anyway. License: MIT. |
| **PostgreSQL** | 17.x | Primary data store | Released Sep 2024, stable through 2025. Stores accounts, profiles, quests, achievements, friend graph, comments, audit/anti-cheat events. Strong relational fit (users have many quests, achievements, comments — graphy-but-bounded, classic relational territory). Native JSONB for cosmetic loadouts and quest definitions. License: PostgreSQL License (BSD-style). |
| **Redis** | 7.4 (or **Valkey 8.x**) | Cache + leaderboards + job queue backend | Sorted sets are *the* canonical leaderboard primitive (O(log N) score updates, O(log N + M) range queries, automatic ordering). Also used for BullMQ queues and short-lived rate-limit counters. **Use Valkey 8.x if redistribution matters** — Redis re-licensed to RSALv2/SSPL in 2024; Valkey is the Linux Foundation BSD-3 fork and is wire-compatible. License: Valkey BSD-3 / Redis RSALv2 (still free to use as a service dependency, just not redistributable). |
| **Drizzle ORM** | 0.44.x (or 1.0 RC if stabilized at build time) | Database access layer | TypeScript-native schema (no separate DSL like Prisma's `.prisma` file), zero codegen drift, ~7 KB bundle, SQL-close API so we can read query plans. Picked over Prisma because Prisma's heavier generation step and historical Rust query engine added friction; Drizzle's 1.0 line just landed JIT row mappers (~25-30% latency reduction). License: Apache-2.0. |
| **Better Auth** | 1.6.x | Auth (web + CLI device pairing) | **The killer feature: official `deviceAuthorization` plugin implements RFC 8628 OAuth 2.0 Device Authorization Grant out of the box.** That's *exactly* the browser-mediated CLI pairing flow the project needs — CLI calls `device.code`, gets a `user_code` and `verification_uri`, opens browser, user authenticates, CLI polls for token. Also handles email/password, OAuth providers, sessions, rate limits, 2FA, organization scoping. Replaces a typical NextAuth + custom-device-flow stitch-up. Picked over Lucia (which the maintainer paused/sunsetted in 2024-2025). License: MIT. |
| **BullMQ** | 5.76.x | Background jobs | Daily quest generation, leaderboard recompute, achievement evaluation, anti-cheat sweep, friend-feed fanout, donation webhook processing. Redis-streams-based, TypeScript-first, well documented, battle-tested. pg-boss is the Postgres-only alternative and works fine, but since we're already running Redis for leaderboards, BullMQ is free. License: MIT. |
| **SvelteKit** | 2.x (Svelte 5) | Web app framework | Smaller bundles (20-40% lighter than Next), fast SSR, deploy-anywhere adapter system (zero Vercel lock-in — important for self-hosters), excellent DX, Svelte 5 stable since Oct 2024. Picked over Next.js because Next's best features (ISR, PPR, Image Optimization, Middleware) are Vercel-coupled; that conflicts with self-hostable OSS. License: MIT. |
| **Tailwind CSS** | 4.x | Styling | Utility-first, tiny shipped CSS, Oxide engine in v4 is dramatically faster, plays nicely with the retro-component libraries we're layering on top. License: MIT. |
| **8bitcn/ui** | latest | Retro-arcade component library | shadcn/ui port styled in 8-bit/NES.css aesthetic, Tailwind-native, copy-paste components (no runtime dep), MIT. Hits the "retro arcade" requirement directly without us hand-rolling pixel borders for every primitive. Pair with **NES.css** (MIT) for any one-off retro flourishes. License: MIT. |
| **Press Start 2P + VT323** | (Google Fonts) | Pixel typography | Press Start 2P for headings/score popups (canonical NES feel); VT323 for body copy where Press Start 2P would be unreadable. Both Open Font License. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| **postgres** (porsager/postgres) | 3.x | Postgres driver under Drizzle | Faster and lighter than `pg`; Drizzle's recommended Postgres driver. License: Unlicense / public domain. |
| **ioredis** | 5.x | Redis client | BullMQ requires it; also use it directly for leaderboard sorted-set ops. License: MIT. |
| **Zod** | 3.x | Runtime schema validation | Validate every inbound request (helper-module pings, web API calls). Pairs with Hono's `@hono/zod-validator` middleware and Drizzle's `drizzle-zod` schema bridge — one Zod schema = wire validation + DB types + form types. License: MIT. |
| **@hono/zod-validator** | latest | Hono request validation | Drop-in middleware for typed request validation. License: MIT. |
| **drizzle-zod** | latest | Drizzle ↔ Zod bridge | Generate Zod schemas from Drizzle tables. License: Apache-2.0. |
| **commander** or **citty** | 12.x / 0.1.x | CLI parsing in helper module | `commander` for stability, `citty` (from UnJS) for smaller bundle. Pick `citty` for a 10x smaller helper-module install. License: MIT. |
| **conf** (sindresorhus/conf) | 13.x | Helper-module local config (token, prefs) | Stores the OAuth refresh token + user prefs in the standard OS config dir. License: MIT. |
| **undici** | built into Node 22 | HTTP client in the helper module | Native `fetch` is fine for one-shots; use undici Pool/Agent for the batch-uploader so we get keep-alive and bounded concurrency. License: MIT. |
| **p-queue** | 8.x | Helper-module ingest batching | Cap concurrency on the local hook ingest pipe so we never spike during a busy session. License: MIT. |
| **pino** | 9.x | Structured logging (server) | Fastest Node logger, JSON output, plays nicely with Loki/Grafana/Datadog. License: MIT. |
| **OpenTelemetry SDK** | 1.x | Observability | Vendor-neutral traces/metrics; exports to anything (Tempo, Jaeger, Honeycomb, Datadog). Don't lock in a proprietary APM SDK in an OSS project. License: Apache-2.0. |
| **bcrypt-ts** or **argon2** | latest | Password hashing | Better Auth supports both; argon2 preferred for new deploys. Argon2 license: CC0/Apache-2.0. |
| **@hono/sse-helper** or native `streamSSE` | latest | SSE for live leaderboards | Hono ships first-class SSE helpers. License: MIT. |
| **tRPC** | 11.x | (optional) typed client → server | Consider for the SvelteKit ↔ Hono boundary if we want end-to-end types without hand-keeping a client. Skip if REST + Zod is enough. License: MIT. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| **pnpm** | Package manager + monorepo workspaces | Fast, disk-efficient, first-class workspaces. Repo will be a monorepo (`apps/web`, `apps/api`, `packages/cli`, `packages/shared`). |
| **Turborepo** or **Nx** | Monorepo build orchestration | Turborepo for simplicity (it's the lighter touch). |
| **Vitest** | Unit + integration tests | Fast, ESM-first, Vite-powered, drop-in for Jest. |
| **Playwright** | E2E for web app + device-pairing flow | Critical for the browser-mediated pairing flow; need real-browser tests there. |
| **ESLint 9 (flat config) + Prettier 3** | Lint + format | Standard 2026 setup. |
| **GitHub Actions** | CI | OSS-friendly free tier; matrix-test against Node 22 + Postgres 17 + Redis/Valkey. |
| **Docker + Docker Compose** | Local dev + self-host distribution | Ship a `docker-compose.yml` so a self-hoster can `docker compose up` and have Postgres + Redis + API + web running. |
| **dotenv / @t3-oss/env-core** | Env validation | Validate `process.env` at startup so misconfig fails loudly. |

### Helper Module / Local CLI — Detailed Design

| Concern | Choice | Rationale |
|---------|--------|-----------|
| **Language** | TypeScript on Node 22 | Claude Code already requires Node; reusing it adds nothing to the user's machine. Going Go/Rust to ship a single static binary is tempting but doubles toolchain, splits the contributor base, and adds zero functional value when Node is already present. Single-binary path stays open via Node 22's native SEA (`--build-sea`) if we ever want it. |
| **Package** | Published as `@<scope>/cli` on npm + `npx` runnable | `npx @<scope>/cli pair` is the lowest-friction first-run command. Optional global install for users who want a permanent `gsd` (or whatever the final name is) command. |
| **Hook integration** | Settings.json hook entries shell out to the CLI's subcommands | Claude Code's hook system passes JSON over stdin to the configured command. The CLI exposes subcommands like `cli hook session-start`, `cli hook user-prompt-submit`, etc. — same binary, different entry point per hook. |
| **Statusline contract** | The CLI is **not** the statusline. It exposes a `cli stats` (or `cli statusline-fragment`) command that any user's statusline script can call to get current XP / quest progress / streak / rank as JSON or as a pre-rendered ANSI segment. | This is the "statusline-agnostic" requirement made concrete: we provide the data, users compose. |
| **Transport to backend** | HTTPS, batched, fire-and-forget with local queue | Hook events are appended to a local SQLite or JSONL queue file, then a background flusher posts batches every N seconds (or on session end). Offline-tolerant by construction. Uses the OAuth bearer token from device-pairing. |
| **Local store** | `better-sqlite3` (synchronous, fast, single-file) | Ideal for the local outbox and small caches. License: MIT. |
| **Latency budget** | Hooks must return in < 50 ms; statusline fragment in < 20 ms | Achieved by: (a) hook handlers only enqueue, never network; (b) the statusline fragment reads from a local cache that the background flusher refreshes opportunistically. |
| **Single-binary option (later)** | Node 22 `--build-sea` + `esbuild` bundle | Available if/when we want a Node-free install path. Don't ship it in v1 — npm distribution is fine and lets us iterate fast. |

### Auth & Browser Device-Pairing — Detailed Design

The flow uses **OAuth 2.0 Device Authorization Grant (RFC 8628)** via Better Auth's `deviceAuthorization` plugin:

1. User runs `cli pair` in their terminal.
2. CLI calls `POST /device/code` on the backend → receives `device_code`, `user_code` (short, human-typeable), and `verification_uri_complete`.
3. CLI prints the `user_code` and opens `verification_uri_complete` in the user's default browser.
4. Browser hits the backend's `/device` page, user logs in (or signs up), confirms the pairing.
5. CLI has been polling `POST /token` with `grant_type=urn:ietf:params:oauth:grant-type:device_code`. Once the user confirms, the next poll returns an access token + refresh token.
6. CLI stores tokens via `conf` in the OS standard config dir.

This is *exactly* the same UX pattern users know from `gh auth login`, `aws sso login`, `vercel login`, `claude` CLI itself, etc. Because Better Auth ships it as a plugin we don't write the spec ourselves — we configure it.

## Installation

```bash
# Backend (apps/api)
pnpm add hono @hono/node-server @hono/zod-validator
pnpm add drizzle-orm postgres ioredis bullmq
pnpm add better-auth
pnpm add zod pino @opentelemetry/sdk-node
pnpm add -D drizzle-kit @types/node tsx

# Web app (apps/web)
pnpm create svelte@latest
pnpm add -D tailwindcss@next @tailwindcss/vite
pnpm add lucide-svelte
# 8bitcn/ui is copy-paste, NES.css is a single CSS import
pnpm add nes.css

# Helper module / CLI (packages/cli)
pnpm add citty better-sqlite3 conf undici p-queue
pnpm add -D @types/better-sqlite3 esbuild

# Dev / shared
pnpm add -D vitest @playwright/test eslint prettier turbo
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| **Hono** | Fastify | If you specifically want Node-only, schema-driven JSON serialization, and a deeper plugin ecosystem (Fastify's plugin community is bigger). Hono still wins on portability and bundle size. |
| **Hono** | Elysia | If you commit to Bun runtime end-to-end. Elysia + Eden gives the strongest end-to-end TS DX of any framework, but it's Bun-locked and Bun's long-running-process story is still maturing. |
| **PostgreSQL** | SQLite (LiteFS / Turso) | If we wanted edge-first deployment and *very* small scale (<1k users) with no real concurrency. We need BullMQ + leaderboard ranges + concurrent writers; Postgres is the right fit. |
| **Redis / Valkey** | KeyDB / Dragonfly | If memory cost becomes the bottleneck at scale. Both are wire-compatible Redis alternatives. Stick with Valkey for now — it's the Linux Foundation steward fork and the most predictable license story. |
| **Drizzle** | Prisma 7 | If the team prefers a higher-level abstracted API and is willing to accept the codegen step. Prisma 7 (Nov 2025) shrank the bundle dramatically, so the old "Prisma is too heavy" argument is weaker. Still pick Drizzle for SQL-closeness on a leaderboard-heavy workload. |
| **Drizzle** | Kysely | If you want a query builder *only* (no migrations, no schema-as-code). Drizzle gives you both. |
| **Better Auth** | Auth.js (NextAuth) | If you're already on Next.js. Auth.js doesn't ship a first-class device-authorization grant; you'd implement RFC 8628 yourself. |
| **Better Auth** | Lucia | Lucia is effectively in maintenance/sunset mode (the author paused active development in 2024-2025). Don't start new projects on it. |
| **BullMQ** | pg-boss | If you want to *avoid* running Redis and keep Postgres as your only stateful service. We're running Redis anyway for leaderboards, so BullMQ is "free." |
| **SvelteKit** | Next.js 16 | If you specifically need React's hiring pool, the React ecosystem, or you want PPR/ISR. For an OSS, self-hostable, deploy-anywhere project, SvelteKit's adapter model is a better fit. |
| **SvelteKit** | Remix / React Router v7 | If you want React + the Remix data-loading model on a portable adapter. Reasonable choice; SvelteKit just ships smaller. |
| **Server-Sent Events** | WebSockets | If we ever add bidirectional needs (chat, live raid coordination). For v1's read-heavy leaderboard + quest-progress pushes, SSE is simpler, works through proxies, and reconnects automatically. v2 raids may force WS. |
| **Server-Sent Events** | Long polling | Only if a deployment target blocks SSE (rare). Don't pick polling proactively — it's strictly worse. |
| **Node 22** | Bun 1.x | Bun is fast and now Anthropic-backed (acquired Dec 2025), but the helper module *must* run alongside Claude Code on the user's machine. Standardize on Node for one toolchain. Reconsider Bun for the backend specifically once it has 12+ months of long-running-process production data. |
| **Node 22** | Go / Rust for the helper module | Tempting for a static single binary, but it forks the codebase into two languages and Node is already on every Claude Code user's machine. Skip unless we hit a real perf wall (we won't). |
| **Fly.io hosting** | Render | Render has a stronger managed-Postgres story (PITR, read replicas). Pick Render if we want fully-managed DB and fixed monthly pricing. |
| **Fly.io hosting** | Railway | Railway is the fastest "git push and forget" experience. Great for the prototype/MVP phase. Fly wins on global edge and per-VM control. |
| **Fly.io hosting** | Self-hosted VPS (Hetzner + Coolify / Dokploy) | The self-hoster path. Hetzner CX22 ($4/mo) running Coolify can host all three services + Postgres + Redis comfortably for hundreds of users. Document this for forks. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| **Express** | Slower than Hono/Fastify, callback-flavored API, no first-class TS, ecosystem is in maintenance mode for new projects | Hono |
| **Sequelize / TypeORM** | Older patterns, weaker TS, slower release cadence, less idiomatic on Postgres | Drizzle |
| **Prisma 6 and below** | The old Rust query engine inflated bundle and added an out-of-process binary | Prisma 7 if you want Prisma, otherwise Drizzle |
| **Lucia Auth** | Maintainer announced indefinite pause / sunset; not the right base for new projects | Better Auth |
| **NextAuth without device flow** | No first-class RFC 8628 plugin; you'd hand-roll the device-authorization endpoint | Better Auth |
| **Bull (legacy)** | Superseded by BullMQ (same author, complete rewrite, Redis Streams-based) | BullMQ |
| **vercel/pkg** | Public-archived in 2024; no longer maintained | Node 22 native SEA (`--build-sea`) if you need a single binary |
| **MongoDB** | Friend graphs, comments, leaderboard tie-breaks all want SQL joins; SSPL license also creates surprise restrictions for hosted distributions | PostgreSQL |
| **Firebase / Supabase Auth as the only auth** | Firebase is closed; Supabase is OSS-friendly but locks you to their stack and doesn't ship RFC 8628 device flow as a first-class primitive | Better Auth (works on top of any Postgres, including Supabase if you want their DB) |
| **Vercel-only Next.js features** (ISR, Image Optimization, Middleware, PPR) | Tie self-hosters to either Vercel or a non-trivial OpenNext setup | SvelteKit (any-adapter) |
| **GPL / AGPL libraries in the dependency tree** | Forces our distribution to either be GPL/AGPL or to remain MIT but with awkward redistribution caveats | Stick to MIT / Apache-2.0 / BSD / ISC / PostgreSQL / Unlicense / OFL only. **Audit before adding any new dep.** |
| **Redis 7.4+ if you plan to redistribute the binary** | RSALv2/SSPL — fine to depend on, awkward to ship inside a Docker image you publicly distribute | Valkey 8.x (Linux Foundation, BSD-3) — wire-compatible drop-in |
| **Auth.js for the device-pairing flow** | No first-class device-authorization-grant primitive | Better Auth's `deviceAuthorization` plugin |
| **Random "leaderboard" SaaS** | Lock-in; trivial to build with a Redis sorted set | Redis ZADD/ZRANGE/ZREVRANK |

## Stack Patterns by Variant

**If self-hosting on a $5/mo VPS:**
- Single Docker Compose file: api, web, postgres, valkey, caddy reverse proxy
- Skip BullMQ workers as a separate process; run them in the API container
- Sub-1k users fits comfortably on 1 vCPU / 2 GB RAM

**If running the public hosted instance:**
- Fly.io with 2 small machines (api), 1 machine (web), Fly Postgres or Neon, Upstash Valkey/Redis
- Separate worker process for BullMQ (anti-cheat sweeps, leaderboard recompute)
- Cloudflare in front for static asset CDN + DDoS protection (free tier is sufficient)
- Fly's per-region scaling lets us add a second region when we have a global user base

**If a contributor wants a one-command dev environment:**
- `pnpm i && pnpm dev` brings up everything via Docker Compose
- `pnpm db:reset` blows away and re-seeds Postgres with fixture quests + achievements

**If we ever need the helper module as a single binary:**
- `node --build-sea sea-config.json` after esbuild bundles the CLI
- Ships a ~80-100 MB executable per platform (the cost of bundling Node)
- Don't do this in v1 — npm is fine and faster to iterate on

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| Node 22 LTS | Hono 4, Drizzle 0.44+, Better Auth 1.6+, BullMQ 5, SvelteKit 2 | All confirmed compatible. Node 22 LTS support window: until Apr 2027. |
| Drizzle 0.44 + postgres-js 3 | PostgreSQL 14-17 | Pin Postgres ≥ 16 for `MERGE` and recent JSON functions. |
| BullMQ 5.76+ | ioredis 5 | Use ioredis (not node-redis) — it's BullMQ's expected client. |
| Better Auth 1.6 | Drizzle 0.44+ | Better Auth has an official Drizzle adapter; share the same Postgres connection. |
| SvelteKit 2 | Svelte 5 | Required pairing as of late 2024. |
| Tailwind 4 | PostCSS / Vite | Use the Vite plugin (`@tailwindcss/vite`) — it's faster and the recommended path in v4. |
| 8bitcn/ui | Tailwind 4, React or Svelte | Components are copy-paste; install only the deps the components themselves require. |

## License Audit (Critical for OSS Distribution)

| Component | License | Compatible with permissive (MIT/Apache) project? |
|-----------|---------|------|
| Node.js | MIT | Yes |
| TypeScript | Apache-2.0 | Yes |
| Hono | MIT | Yes |
| Drizzle ORM | Apache-2.0 | Yes |
| postgres-js | Unlicense | Yes |
| BullMQ | MIT | Yes |
| Better Auth | MIT | Yes |
| SvelteKit / Svelte | MIT | Yes |
| Tailwind CSS | MIT | Yes |
| 8bitcn/ui | MIT | Yes |
| NES.css | MIT | Yes |
| PostgreSQL | PostgreSQL License (BSD-style) | Yes |
| **Valkey** | **BSD-3** | **Yes** (preferred) |
| Redis (>= 7.4) | RSALv2 / SSPL dual | **Caution** — fine to depend on, awkward to redistribute. Prefer Valkey. |
| ioredis | MIT | Yes |
| Zod | MIT | Yes |
| pino | MIT | Yes |
| OpenTelemetry SDKs | Apache-2.0 | Yes |
| Press Start 2P / VT323 | Open Font License | Yes |

**Project license recommendation:** Apache-2.0 for explicit patent grant, or MIT for maximum simplicity. Either is fine. **Do not** dual-license under anything copyleft. Add a CI check (e.g., `license-checker`) to fail the build if any new dep introduces GPL/AGPL/SSPL.

## Sources

- `/honojs/hono` (Context7) — confirmed Hono is on Web Standards, runs on Node/Bun/Deno/Workers, JSR distribution, Migration guide
- `/drizzle-team/drizzle-orm` (Context7) — confirmed v1.0 line, JIT mappers, current API
- `/better-auth/better-auth` (Context7) — **confirmed `deviceAuthorization` plugin implements RFC 8628**, with full client + server snippets — HIGH confidence
- `/sveltejs/kit` (Context7) — SvelteKit framework metadata
- `/taskforcesh/bullmq` (Context7) — BullMQ confirmed as Redis-streams based, current
- [Better Auth Device Authorization plugin docs](https://better-auth.com/docs/plugins/device-authorization) — the primary auth recommendation
- [Better Auth 1.3 release notes](https://better-auth.com/blog/1-3) — production readiness
- [RFC 8628 — OAuth 2.0 Device Authorization Grant](https://datatracker.ietf.org/doc/html/rfc8628) — the spec our pairing flow implements
- [PostgreSQL 17 release announcement](https://www.postgresql.org/about/news/postgresql-17-released-2936/) — confirmed Sep 2024 release, current
- [Hono 4.12 npm](https://www.npmjs.com/package/hono) — current version verification
- [BullMQ 5.76 release](https://github.com/taskforcesh/bullmq/releases) — current version verification
- [Drizzle ORM v1 roadmap](https://orm.drizzle.team/roadmap) — version trajectory
- [Drizzle vs Prisma comparison (Bytebase)](https://www.bytebase.com/blog/drizzle-vs-prisma/) — MEDIUM
- [Hono vs Express vs Fastify vs Elysia (PkgPulse, 2026)](https://www.pkgpulse.com/guides/hono-vs-express-vs-fastify-vs-elysia-2026) — MEDIUM
- [Next.js vs Remix vs SvelteKit (DEV/Pockit, 2026)](https://dev.to/pockit_tools/nextjs-vs-remix-vs-astro-vs-sveltekit-in-2026-the-definitive-framework-decision-guide-lp5) — MEDIUM
- [Redis Sorted Sets leaderboard tutorial (Redis docs)](https://redis.io/docs/latest/develop/use-cases/leaderboard/nodejs/) — HIGH (official)
- [WorkOS — OAuth Device Authorization Grant CLI guide](https://workos.com/blog/oauth-device-authorization-grant) — MEDIUM
- [Node.js Single Executable Applications API](https://nodejs.org/api/single-executable-applications.html) — HIGH (official)
- [Vercel/pkg public archive notice](https://github.com/vercel/pkg) — confirmed deprecation, HIGH
- [Svelte 5 stable release announcement (Oct 2024)](https://svelte.dev/blog/svelte-5-is-alive) — HIGH (official)
- [Fly.io vs Railway vs Render comparisons](https://blog.elest.io/elestio-vs-railway-vs-render-vs-fly-io-which-platform-actually-fits-your-needs/) — MEDIUM
- [SSE vs WebSockets analysis (RxDB)](https://rxdb.info/articles/websockets-sse-polling-webrtc-webtransport.html) — MEDIUM
- [Bun vs Node.js production analysis 2026](https://strapi.io/blog/bun-vs-nodejs-performance-comparison-guide) — MEDIUM (used to justify staying on Node)
- [NES.css framework](https://nostalgic-css.github.io/NES.css/) — HIGH (official)
- [8bitcn/ui component library](https://www.shadcn.io/template/theorcdev-8bitcn-ui) — MEDIUM

---
*Stack research for: OSS gamification service for Claude Code (web + backend + helper module)*
*Researched: 2026-05-08*

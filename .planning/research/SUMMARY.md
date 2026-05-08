# Project Research Summary

**Project:** Claude Code Gamification Service (working title; directory `GSD-StatusLineGamification` is legacy)
**Domain:** OSS gamification service for Claude Code — distributed system across backend, web app, and local helper module running inside the user's Claude Code environment
**Researched:** 2026-05-08
**Confidence:** HIGH overall. Stack, auth flow, leaderboard primitives, streak/timezone math, gamification psychology, and OAuth pitfalls are all rooted in primary sources or peer-reviewed work. MEDIUM only on long-horizon scaling beyond ~10k users (project explicitly targets hundreds initially) and on a handful of niche UI specifics.

## Executive Summary

This is a three-tier system with one twist: the third tier is not a browser, it's a **local helper running inside the user's Claude Code environment**. The four research files converged tightly on a single recommended shape — TypeScript end-to-end on Node 22 LTS, Hono + Drizzle + Postgres 17 + Valkey 8 + BullMQ + Better Auth on the backend, SvelteKit 2 + Tailwind 4 + 8bitcn/ui on the web, and a thin Node CLI with a SQLite outbox on the user's machine. RFC 8628 (OAuth Device Authorization Grant) — shipped as a first-class Better Auth plugin — is the device-pairing primitive. Valkey ZSETs are the leaderboard primitive. SSE is the live-update primitive. None of those is a guess; each is verified against primary sources.

The architecture has one absolute load-bearing rule: **the helper never asserts game state. It reports observed signals; the backend computes truth.** That single rule lets us be open-source without becoming a free-for-all — anyone can fork the helper, but cheaters can only poison their own input stream, which the server-side anti-cheat sweep catches. Two adjacent rules fall out of it: (1) hooks are fire-and-forget on a strict <50 ms budget — they enqueue to a local SQLite outbox and exit, and (2) the statusline fragment reads only from a local cache. Network is somebody else's problem (a background flusher daemon).

The dominant risks are not technical, they're psychological and social. Overjustification (extrinsic XP killing the intrinsic joy of programming), Goodhart's Law (a "raw activity" leaderboard becoming a token-spam contest), streak anxiety (the Duolingo/Habitica trap), and harassment via real-handle public profiles will sink this product faster than any infra problem. Storm-2372-style device-code phishing on the pairing flow is a serious security risk that must be engineered against from day one. Maintainer burnout and hosting-cost spiral are existential project risks. Every one of these has a known mitigation pattern documented in PITFALLS.md, and every mitigation must ship with the feature it protects — not in a "later polish" pass.

## Stack at a Glance — Locked Choices

| Layer | Choice | Version | Why |
|-------|--------|---------|-----|
| Runtime | Node.js | 22 LTS (until Apr 2027) | Claude Code itself runs on Node; one toolchain backend + helper |
| Language | TypeScript | 5.7+ | End-to-end types; every recommended lib is TS-first |
| Backend HTTP | Hono | 4.12.x | Web Standards, runtime-portable, zero-dep, ships native `streamSSE` |
| ORM | Drizzle | 0.44.x (or 1.0 RC) | TS-native schema, SQL-close, JIT row mappers in 1.0 line |
| Database | PostgreSQL | 17.x | Source of truth for all durable state |
| Cache / queues / leaderboards | **Valkey** | 8.x (BSD-3) | ZSETs are the canonical leaderboard primitive; **Valkey, not Redis** — avoids RSALv2/SSPL redistribution issues |
| Auth | Better Auth | 1.6.x | Ships RFC 8628 `deviceAuthorization` plugin |
| Job queue | BullMQ | 5.76.x | Quest rotation, achievement eval, leaderboard recompute, anti-cheat sweep, feed fanout |
| Web framework | SvelteKit (Svelte 5) | 2.x | 20-40% lighter than Next; deploy-anywhere adapter |
| Styling | Tailwind CSS | 4.x (Oxide) | — |
| UI components | 8bitcn/ui + NES.css | latest | shadcn-port styled 8-bit; copy-paste, no runtime dep |
| Typography | Press Start 2P + VT323 | OFL | Retro arcade aesthetic |
| Local helper store | better-sqlite3 | latest | Synchronous, fast outbox; pure-JS fallback if native build fails (Windows-ARM landmine) |
| CLI parser | citty | 0.1.x | UnJS, ~10x smaller than commander |
| Token store | conf (sindresorhus) | 13.x | OS-standard config dir |
| HTTP client (helper) | undici (built-in) | Node 22 native | Pool/Agent for keep-alive batching |
| Validation | Zod + drizzle-zod + @hono/zod-validator | 3.x | One Zod schema = wire validation + DB types + form types |
| Logging | pino | 9.x | Fastest; **must** have token-redaction transport |
| Observability | OpenTelemetry SDK | 1.x | Vendor-neutral OTLP exporter |
| Test | Vitest + Playwright | latest | Playwright **mandatory** for device-pairing flow |
| CI | GitHub Actions | — | Matrix on Node 22 + Postgres 17 + Valkey + Linux/macOS/Windows/Windows-ARM |
| Hosting (public) | Fly.io + Cloudflare | — | Self-hostable parity via Docker Compose |
| Hosting (self-host) | Hetzner CX22 + Coolify | — | Same Docker Compose as public instance |
| License | Apache-2.0 (preferred) or MIT | — | CI license-checker fails on GPL/AGPL/SSPL |

## Component Map

| Component | Authoritative for | Does NOT own | Stack |
|-----------|-------------------|--------------|-------|
| **Helper CLI** (`apps/cli`) | Local capture of Claude Code signals; local outbox; OAuth token storage on disk; statusline data fragment | Score, XP, quest progress, achievements, rank — **never** | Node 22 + citty + better-sqlite3 + conf, distributed via `npm` / `npx` |
| **Backend HTTP** (`apps/api/http`) | Auth, event ingestion, public read API, device-pairing, SSE fan-out | Long-running compute (delegated to workers) | Hono + Better Auth + Drizzle, single process at v1 |
| **Backend Workers** (`apps/api/workers`) | Quest rotation, achievement eval, leaderboard recompute, anti-cheat sweeps, feed fanout, usage-poll | Real-time request handling | BullMQ workers; same codebase as HTTP, different entry point |
| **Web app** (`apps/web`) | UI state, view composition, SSR, browser-side device-pairing confirm UI | Any business logic | SvelteKit 2 (Svelte 5) on Node adapter |
| **PostgreSQL 17** | All durable state: identities, quests, achievements, friend graph, comments, raw events, rollups | Hot leaderboard ranges, ephemeral session state | — |
| **Valkey 8** | Leaderboard ZSETs, BullMQ queues, rate-limit counters, SSE pub/sub bus, hot caches | Anything that must survive a full restart with zero loss | — |

> **The hard boundary that must not be crossed: the helper CLI never asserts game state. It only reports observed signals.** Every score, XP value, quest progress count, achievement unlock, and rank traces back to a server computation. The CLI caches what the server tells it; it never computes that state itself. This rule is the reason this project can be open-source.

## Wire Protocols

Three pairings, three protocols. All settled.

### 1. Helper CLI ↔ Backend — Batched HTTPS POST + Bearer Token, fire-and-forget via SQLite outbox

REST over HTTPS. Hook handlers append events to a local SQLite outbox in <1 ms and exit. A separate flusher daemon (started on `SessionStart`) batches every 5-30 s, posts with a UUID-v7 `Idempotency-Key`, deletes on 2xx, exponential-backoff on retryable errors. **No network call ever runs inline in a hook.** Endpoints: `POST /v1/events` (the hot path), `GET /v1/me`, `GET /v1/me/quests/today`, `GET /v1/me/cosmetics/active`, `POST /v1/refresh`. Idempotent (UUID v7 dedup), offline-tolerant, bounded concurrency (`p-queue`), bearer auth, no payload signing in v1.

### 2. Web ↔ Backend — REST + SSE

REST for state-changing and one-shot reads, SSE for live pushes. **No GraphQL, no tRPC for v1** (surface area too small to earn the complexity). Hono ships first-class `streamSSE`. Workers `PUBLISH leaderboard:xp:updates "..."` to Valkey; HTTP servers subscribed to that channel forward to connected SSE browser clients — Valkey pub/sub is the bus. Auto-reconnect via browser-native `Last-Event-ID`. WebSockets deferred to v2 raid coordination.

### 3. Browser ↔ Helper for Device Pairing — RFC 8628 indirect via Backend

**OAuth 2.0 Device Authorization Grant.** The browser and CLI never talk directly — both talk to the backend. CLI calls `POST /device/code`, gets `device_code` + `user_code` + `verification_uri_complete`, prints the code and opens the browser. User logs in on the backend's `/device` page, **must re-enter or confirm the user_code** (anti-phishing), confirms. CLI polls `POST /device/token` and gets back access + refresh tokens, stored via `conf` in OS standard config dir. No localhost listener, no port binding, works inside corporate firewalls and SSH sessions.

## Critical Features (Table Stakes, Dependency-Ordered)

1. Email/password + GitHub OAuth signup with reserved-handle list
2. Public real handle with squatting protection, 30-day rename cooldown, handles_history audit table
3. Public profile page at `/u/handle` with privacy toggle (the social hub's hub)
4. Browser-mediated CLI device pairing (RFC 8628 via Better Auth)
5. Helper CLI: `pair`, `stats`, `statusline-fragment`, `status`, `unpair`, hook subcommands with local SQLite outbox + flusher daemon + offline tolerance
6. Event ingest with Zod validation, velocity rate-limits, plausibility checks, idempotency-key dedup, raw `events` table + `daily_user_stats` rollup worker
7. 5 daily quests (3 global tiered + 2 personalized) with **per-user IANA-timezone local-day reset**, real-time progress, completion celebration, easy/medium/hard XP scaling (~1:3:8), 7-day history, **zero rerolls**
8. Lifetime XP + levels (~10% exponential, cap 99), visible XP source attribution everywhere, level-up notification
9. Achievement catalog (~70/30 visible/hidden), tiered (bronze/silver/gold), evaluated on every XP event, unlock celebration
10. Cosmetics tied 1:1 to achievements (no XP shop, no random drops): badges + glyphs (animated 5-10 fps + static fallback) + ≥4 launch themes (Phosphor, Amber, NES, Mono); inventory + equip + loadout sync
11. Streaks with **streak freezes auto-applied**, grace window across midnight, vacation mode, site-issue protection, no guilt notifications
12. Four leaderboards (raw / streak / XP / efficiency) × three windows (week/month/all-time) × two scopes (global + friends), Valkey ZSETs, SSE updates, self-rank highlight, soft floor below position N
13. Social hub: asymmetric follow graph, profile comments **default off** (owner opts in), report + block + mute, kudos, friend feed (last 7 days), bento-style showcase
14. Anti-cheat: server-side delta validation, shadow-ban with **query-layer filtering** (view/RLS, not application-layer), audit log, admin queue, **visible flag + appeal flow** (never silent shadowban)
15. Self-host parity via `docker-compose.yml`, MIT or Apache-2.0 license, donations link
16. Foundation hooks for v2 raids/companions — schema only

## Differentiators

- Statusline-agnostic via helper module + API
- Achievement-only cosmetic economy (no shop, no random drops)
- Four orthogonal leaderboards rewarding different play styles
- Personalized quest pair (1 strength, 1 growth)
- Efficiency leaderboard ranked higher in copy than raw activity
- Honest gamification: visible XP source attribution everywhere
- Retro arcade aesthetic across web *and* statusline
- Open source + self-hostable with public ↔ Docker Compose parity
- Foundation hooks for v2 raids in v1 data model (schema future-ready)

## Anti-Features (Do Not Build)

Random loot drops • XP shop / paid cosmetics • Hard server-side payload signing • Quest rerolls • Public commit-style daily-activity heatmap (GitHub *removed* contribution streaks for being harmful) • Lifetime-only leaderboards • Server-midnight global quest reset • Direct messaging • Public "shame" stats / reverse leaderboards / bottom-N • Mandatory streaks (no freezes) • User-submitted quests • Anonymous handles by default • Push notifications / email digests / streak-loss-warning emails by default • AI-assisted "quest of the day" coaching • Real money cashout / item trading • Statusline lock-in • Mobile native app • Localhost OAuth callback pattern (`http://localhost:PORT/callback`)

## Top Pitfalls to Engineer Against From Day One

1. **Overjustification effect** — Frame XP as informational feedback, not contingent payment. Quests about *how* you used Claude Code, never raw "use it 4 hours." Opt-out from quests/leaderboards (keep cosmetics). Vacation mode. Surprise/hidden achievements over visible checklists.
2. **Goodhart's Law on leaderboards** — "Raw activity" must be a sanity-checked composite. Cap per-window contribution. Detect trivial tokens server-side. Rotate scoring formula quarterly. Position raw board lowest-status.
3. **Streak anxiety (Duolingo/Habitica trap)** — Streak freezes default. Vacation mode. Grace window 3-6 hours after local midnight. Cap meaningful rewards at ~30 days. Never guilt-based notifications.
4. **OAuth Device Code phishing (Storm-2372)** — Always require `user_code` re-entry on verification page. Display rich device context. Cap `user_code` TTL at 10 min. Rate-limit `device.code` issuance per IP and per account. Bind tokens to per-install client identifier. Email user on every new pairing with revocation link. Slow-cook step on first pair. **PKCE S256 + state mandatory.**
5. **Helper crashes/latency hurting Claude Code sessions** — Hooks fire-and-forget on 50 ms hard / 20 ms soft budget. Never network in a hook. Top-level try/catch on every hook entry that always exits 0. Pure-JS fallback for `better-sqlite3`. Cross-platform synthetic monitoring. Backend kill-switch via feature flags.
6. **Anthropic OAuth token leakage from `~/.claude/.credentials.json`** — Helper calls `api.anthropic.com` directly with that token; **never** sends it to our backend. Pino redaction filter. CI grep on `sk-ant-` patterns. No postinstall scripts in helper deps. Treat credentials file as read-only.
7. **Maintainer burnout / single-maintainer abandonment** — Build moderation tools alongside features. Cap public instance at a published number. Self-host parity day one. Document graceful-shutdown plan publicly. Recruit second maintainer early. Donations channel from launch. README explicitly states "hobby project, best-effort response."
8. **Timezone, midnight cluster, DST bugs** — UTC for storage, IANA timezone on user, Temporal API or Luxon for any day-bucket math, grace window 3-6 hours after local midnight, per-user reset (never global cron). DST unit tests on spring-forward and fall-back across 3+ timezones.
9. **Public real-handle harassment surface** — Reserved-handle list (~200 names). Email verification + signup rate-limit per IP/email-domain. Handle-change cooldown 90 days. Comments **default off** until profile owner opts in. No DMs. Block + mute + report. No real-time "active now". Banded colors not raw token counts on public profile. CoC + appeal path.
10. **Anti-cheat false positives destroying trust** — Tell the user when flagged. Visible appeal path with 7-day auto-restore. Confidence-tiered actions. Rate-limit, don't ban. **Never silently shadowban in v1.**

## Recommended Phase Order

### Phase 0: Project Setup, Privacy, and Sustainability Scaffolding
**Rationale:** GDPR/CCPA, license-checker, shutdown plan, hosting-cap declaration, and rate-limit scaffolding are cheaper to build first than to retrofit.
**Delivers:** monorepo (pnpm + Turborepo), license, CI license-checker, CONTRIBUTING + CoC, public shutdown plan, hosting cap, GitHub Sponsors, privacy policy + ToS scaffolding, granular-consent model, retention schedule, Plausible (not GA), Docker Compose for local dev.

### Phase 1: Backend Skeleton + Auth (no game features)
**Rationale:** Nothing else has anywhere to talk to.
**Delivers:** Hono + Drizzle + Postgres 17 + Valkey 8 + BullMQ scaffolding, Better Auth (email/password + GitHub OAuth), `users` + `handles_history`, reserved-handle list, signup rate limits, **pino with token-redaction transport from day one**, OpenTelemetry SDK.

### Phase 2: RFC 8628 Device Authorization Flow
**Rationale:** The CLI is useless without a server that accepts pairings. Build before CLI; smoke-test with curl + browser.
**Delivers:** Better Auth `deviceAuthorization` plugin with **PKCE S256 mandatory + state validation**; `/device` SvelteKit page with `user_code` re-entry + rich device context; 10 min `user_code` TTL; rate-limited `device.code` issuance; per-install client-id binding; email-on-pairing with revocation link; slow-cook first-pair confirmation; `/settings/devices` revocation UI.
**Research flag:** Storm-2372 mitigation specifics in current Better Auth release.

### Phase 3: Event Ingest + Daily Rollup Worker
**Rationale:** Quests/achievements are interpreters over events. Build substrate first. Rate limits + plausibility checks ship here, not later.
**Delivers:** `POST /v1/events` with Zod + idempotency-key + velocity rate-limits + plausibility + UUID-v7; `events` table (monthly partitioning path); `daily_user_stats` rollup worker; `usage-poll` worker for Anthropic OAuth usage API; cross-source corroboration scaffolding.

### Phase 4: Web App Minimum (parallelizable with Phases 2-3)
**Rationale:** Doesn't depend on game features. Team of two can split here.
**Delivers:** SvelteKit 2 + Svelte 5 + Tailwind 4 + 8bitcn/ui + NES.css; Press Start 2P + VT323; **theme schema** (palette + glyph frame format) used by both web and helper; `/`, `/u/[handle]`, `/settings`, `/device` pages; Better Auth client; **profiles `noindex` by default**.

### Phase 5: Helper CLI
**Rationale:** Once `/device/*` and `/v1/events` exist, the CLI is "just" a Node app that calls them. Last point at which the wire protocol can be cheaply changed.
**Delivers:** `cli pair/unpair/status/stats/statusline-fragment`, hook subcommands, SQLite outbox with **pure-JS fallback**, flusher daemon (5s active / 30s idle / immediate on `SessionEnd`), local theme + loadout cache, **top-level try/catch on every hook entry exits 0**, per-hook 50 ms self-killer, remote feature-flag check on startup (kill switch), helper sends `User-Agent: gsd-helper/X.Y.Z`, **never sends Anthropic OAuth token to backend**.
**Verification:** Cross-platform CI on Linux + macOS + Windows + Windows-ARM × Node 20/22; latency budget enforced as CI gate.
**Research flag:** Claude Code hook stability is a moving target; reverify event names/payload via Context7 at planning time.

### Phase 6: Quest Engine
**Rationale:** Proves the rule-DSL on a daily cadence; achievements reuse it.
**Delivers:** `quest_definitions` / `quest_assignments` / `quest_progress` 3-table split; rule-DSL interpreter; `daily-quest-rotate` worker that **sweeps users whose local-day just rolled** (per-user, not global cron); 3 global tiered + 2 personalized; cold-start path (generic personalized for users with <7 days history); easy/medium/hard XP scaling; **zero rerolls**; `/v1/me/quests/today`; quest UI; completion celebration; 7-day history; **grace window 3-6 hours after local midnight**.
**Cross-cutting:** Streak freeze (1 per N completions, cap 2), vacation mode, site-issue admin toggle, "broken streak record" badge.
**Research flag:** quest **rule DSL design** — needs concrete spec.

### Phase 7: Achievements + Cosmetics
**Rationale:** Reuses rule DSL on lifetime cadence. Cosmetic table must exist before achievement seeding (1:1 reference).
**Delivers:** `cosmetics`, `achievement_definitions` (with `cosmetic_id` 1:1) + `achievement_unlocks`; `cosmetic_unlocks` (derived) + `cosmetic_loadouts`; **achievement evaluation on every XP event**; ~70/30 visible/hidden; tiered where applicable; ≥4 launch themes; animated glyph (frame arrays + ANSI, 5-10 fps); static glyph fallback for non-TTY; theme + loadout sync to helper; **don't show "X of Y" prominently**; cosmetic deprecation policy published.
**Research flag:** **animated glyph FPS budget** in non-TTY contexts; theme schema details.

### Phase 8: Leaderboards
**Rationale:** Rank computations depend on rollups populated by quest/achievement workers. Goodhart and bottom-of-leaderboard demotivation must be designed in, not bolted on.
**Delivers:** Valkey ZSETs per `(dimension, window)` — 4 dim × 3 windows; Postgres `leaderboard_snapshots` mirror (top 1,000); weekly keys age out via TTL (no global reset — sidesteps timezone trap); `score-update` worker; `/v1/leaderboards/:dim` + `/v1/sse/leaderboards/:dim`; web UI with **default view = relative cohort, soft-floor below position N, hide leaderboard for new users their first week**, multi-board surfacing emphasizing efficiency, optimistic UI on user's own actions, clear cached-vs-live indicator; tie-break lexicographic on `(score, earlier_achieved_at)`.
**Research flag:** **efficiency leaderboard metric design**. Candidates: `(quests_completed_per_active_session)` or `(useful_token_share = 1 - waste_ratio)`.

### Phase 9: Social Hub
**Rationale:** Comments/follows are independently testable but need real users. Defer moderation surface until rest exists. Real handles + public profiles = harassment surface; full mitigation kit ships *with* the social hub.
**Delivers:** `follows` (asymmetric, Twitter-style), follow/unfollow/block; `profile_comments` with **default-off until owner opts in**, owner controls who, soft-delete, moderation queue, rate-limit (3/60s), profanity wordlist, link auto-flag; report → admin queue + auto-rate-limit heuristics; bento-style showcase; friend feed (last 7 days); kudos; follower-count gating; **no real-time "active now"**; **no DMs**; **no notifications by default** (in-app bell only; email weekly digest opt-in only; quiet hours; RFC 8058 list-unsubscribe).

### Phase 10: Anti-Cheat Hardening + Admin Tools
**Rationale:** Schema/velocity already shipped Phase 3. Cross-source + anomaly sweeps need real data. Appeal flow must ship before any banning logic.
**Delivers:** Cross-source token check worker (Anthropic OAuth usage vs claimed); daily anomaly-sweep worker; `users.shadow_banned` with **query-layer filtering** (view or RLS); audit log; admin anomaly review queue; **visible "we noticed unusual activity" flag + appeal form with 7-day auto-restore**; confidence-tiered actions (log → warn → rate-limit, never silent shadowban); periodic manual-sample audit; published anti-cheat philosophy.

## Cross-Cutting Decisions to Lock Now

- **Theme schema** — palette (ANSI) + glyph frame format, authored in `packages/content/cosmetics/`, consumed by both helper and web. Lock before Phase 7.
- **Timezone semantics** — UTC storage, IANA on user, Temporal API or Luxon, grace window 3-6h after local midnight, per-user reset (never global cron). Locked from Phase 1.
- **Anti-cheat appeal flow** — visible flag + single-click appeal + 7-day auto-restore + no silent shadowban v1. Locked from Phase 3.
- **Hosting cap** — public instance capped at published number (e.g. 5,000 active users). Locked Phase 0.
- **License** — Apache-2.0 (preferred) or MIT. CI license-checker fails on GPL/AGPL/SSPL. Locked Phase 0.
- **API versioning** — `/api/v1/...`; bump only on breaking; keep v1 ≥6 months past v2; helper sends version on every request. Locked Phase 1.
- **Notification policy** — opt-in only, default off, web-only at v1, no guilt copy ever. Locked Phase 0.
- **Cosmetic deprecation policy** — public, written, generous: "we will not remove cosmetics that have been earned." Locked Phase 7.
- **Shutdown plan** — public, 90-day notice, full export, transfer or graceful close. Locked Phase 0.
- **Token-handling rule** — Anthropic OAuth token never reaches our backend. Pino redaction filter installed before any logger touches tokens. Locked Phase 1.
- **Helper hard rule** — never asserts game state; only reports observed signals. Locked Phase 0 architecture doc.
- **Reserved-handle list** — published, audited at launch and quarterly. Locked Phase 1.
- **Data retention** — raw events 90 days, aggregated indefinite, account until deletion. Locked Phase 0.
- **Self-host parity** — public instance and Docker Compose run from exact same image. Locked Phase 0.

## Open Questions Deferred to Phase-Specific Research

- **Efficiency leaderboard metric** (Phase 8 planning)
- **Quest rule DSL design** (Phase 6 planning)
- **Animated glyph FPS budget** in non-TTY contexts (Phase 7 planning)
- **Anti-cheat thresholds** — initial in Phase 3, refined in Phase 10
- **Personalization signal weighting** (Phase 6 planning)
- **Whether comments ship in v1 or defer to v1.1** (Phase 9 kickoff)
- **Streak repair (XP-debt within 48h)** — ship in v1 or wait until users churn at first streak loss (end of Phase 6)
- **TimescaleDB** — only at tens of thousands of users (milestone boundary)

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All libraries verified via Context7; license audit complete; version compatibility verified |
| Features | HIGH | Table stakes from peer-reviewed prior art; anti-features rejected on documented evidence; MEDIUM only on dev-tool-specific personalization signals |
| Architecture | HIGH | Component boundaries and wire protocols are textbook for the constraints; data model concrete and Drizzle-ready; build order falls out of dependency graph; MEDIUM only on long-horizon scaling beyond 10k users |
| Pitfalls | HIGH | Critical pitfalls all rooted in primary sources (RFC 8628/9700, peer-reviewed gamification literature, real-world incidents) |

**Overall confidence:** HIGH.

# Roadmap: Claude Code Gamification Service

**Created:** 2026-05-08
**Granularity:** fine
**Mode:** yolo
**Structure:** Horizontal layers (foundation → ingest substrate → game features → social → hardening)
**v1 requirements covered:** 154 / 154

## Overview

The journey starts with project sustainability scaffolding (license, privacy, shutdown plan, hosting cap) so the OSS posture and data-handling rules are real before any code touches them. Phase 1 stands up the backend skeleton with auth and the token-redaction logger so nothing else has to retrofit those. Phase 2 adds RFC 8628 device pairing because the helper is useless without a server that can pair it. Phase 3 builds the event-ingest substrate (raw events, idempotency, plausibility, daily rollups, Anthropic usage cache) — the data layer every later phase interprets. Phase 4 brings up the web app shell with the shared theme schema (parallelizable with 2-3). Phase 5 ships the helper CLI now that `/device/*` and `/v1/events` exist. Phases 6-7 layer the game loop on top of the substrate (quests/XP/streaks, then achievements/cosmetics with the rule DSL reused). Phase 8 turns aggregated state into rankings (Valkey ZSETs, SSE, Goodhart-resistant copy). Phase 9 adds the social hub with full moderation kit shipped alongside it. Phase 10 hardens anti-cheat with cross-source corroboration, anomaly sweeps, and the visible-flag-plus-appeal flow before any banning logic is wired up. The ordering follows `research/SUMMARY.md` § "Recommended Phase Order" exactly because the dependency graph leaves no slack.

## Phases

- [x] **Phase 0: Project Setup, Privacy, and Sustainability Scaffolding** - Monorepo, license, OSS docs, privacy/ToS, retention model, public shutdown plan, Docker Compose parity (completed 2026-05-09)
- [ ] **Phase 1: Backend Skeleton + Auth** - Hono + Drizzle + Postgres + Valkey + BullMQ scaffolding with Better Auth (email/password + GitHub) and reserved-handle squat protection
- [ ] **Phase 2: RFC 8628 Device Authorization Flow** - Browser-mediated CLI pairing with PKCE, user_code re-entry, rich device context, email-on-pair, revocation UI
- [ ] **Phase 3: Event Ingest + Daily Rollup Worker** - `POST /v1/events` with idempotency, velocity limits, plausibility checks, raw events table, daily rollups, Anthropic usage cache
- [ ] **Phase 4: Web App Shell** - SvelteKit 2 + Tailwind 4 + 8bitcn/ui shell with shared theme schema, profile/settings/device pages, noindex by default
- [ ] **Phase 5: Helper CLI** - `pair`/`unpair`/`status`/`stats`/`statusline-fragment` + hook subcommands, SQLite outbox with pure-JS fallback, flusher daemon, kill switch
- [ ] **Phase 6: Quest Engine + XP + Streaks** - 5 daily quests (3 global tiered + 2 personalized) with per-user IANA-timezone reset, XP attribution, level curve, streak freezes, vacation mode
- [ ] **Phase 7: Achievements + Cosmetics** - ~70/30 visible/hidden achievement catalog tied 1:1 to badges/glyphs/themes, on-event evaluation, loadout sync to helper
- [ ] **Phase 8: Leaderboards** - 4 dimensions × 3 windows × 2 scopes via Valkey ZSETs with SSE updates, soft-floor cohort UI, Goodhart-resistant raw-activity composite
- [ ] **Phase 9: Social Hub** - Asymmetric follows, opt-in profile comments with full moderation kit, kudos, friend feed, bento showcase, weekly-digest opt-in
- [ ] **Phase 10: Anti-Cheat Hardening + Admin Tools** - Cross-source corroboration, anomaly sweeps, query-layer shadow-ban, audit log, visible-flag-plus-appeal flow

## Phase Details

### Phase 0: Project Setup, Privacy, and Sustainability Scaffolding
**Goal**: Establish the OSS posture, legal/privacy ground truth, and self-host parity before any product code is written, so every later phase inherits the right defaults.
**Depends on**: Nothing (first phase)
**Requirements**: FND-01, FND-02, FND-03, FND-04, FND-05, FND-06, FND-07, FND-08, PRIV-01, PRIV-02, PRIV-03, PRIV-04, PRIV-05
**Success Criteria** (what must be TRUE):
  1. Repo carries an Apache-2.0 (or MIT) `LICENSE`, `CONTRIBUTING.md`, and a published Code of Conduct, and the README states the maintenance posture and links donations
  2. CI fails any pull request that introduces a GPL/AGPL/SSPL/RSALv2 transitive dependency
  3. `docker compose up` from a clean clone boots the same container images the public instance will run, with no extra setup steps
  4. Privacy policy, ToS, hosting-cap declaration, retention schedule, and 90-day shutdown plan are committed under `docs/legal/` and reachable from the (placeholder) web app footer
  5. Granular-consent model is documented (event capture, public leaderboards, email digests as separate consents) and Plausible (not GA) is the only analytics provider in scope
**Plans**: 4 plans
- [x] 00-01-PLAN.md - Repo Charter & CI (LICENSE, CoC, CONTRIBUTING, SECURITY, .gitignore, .editorconfig, license-check + DCO workflows, PR/issue templates) - FND-01, FND-02, FND-03
- [x] 00-02-PLAN.md - Self-Host Parity (docker-compose.yml with Postgres 17 + Valkey 8 + Mailpit, .env.example, scripts/verify-phase-0.sh) - FND-08
- [x] 00-03-PLAN.md - Legal & Privacy & Ops Docs (privacy-policy, terms-of-service, retention-schedule, hosting-cap, shutdown-plan, dns) - FND-04, FND-05, PRIV-01..05
- [x] 00-04-PLAN.md - Sustainability + Monorepo + Architecture (README, root package.json, pnpm-workspace.yaml, turbo.json, 8 workspace stubs, reserved-handles.json, docs/architecture/00-overview.md) - FND-06, FND-07
**Risks (PITFALLS)**:
- Pitfall 7: Maintainer burnout — hosting cap, shutdown plan, donations, and "hobby project" framing must ship here, not "later"
- Pitfall 6: Token-handling rule must be written into the architecture doc here even though it's enforced in Phase 1 logging

### Phase 1: Backend Skeleton + Auth
**Goal**: Stand up the backend service with identity, handles, and the redaction-aware logger so every later phase has somewhere to talk to and nothing accidentally leaks tokens.
**Depends on**: Phase 0
**Requirements**: AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05, AUTH-06, AUTH-07, IDENT-01, IDENT-02, IDENT-03, IDENT-04, IDENT-05, IDENT-06, IDENT-07, IDENT-08
**Success Criteria** (what must be TRUE):
  1. User can sign up with email/password (with verification email + password reset) or GitHub OAuth and the session survives a browser refresh
  2. Signup is rate-limited per IP and per email domain, and the reserved-handle list (~200 names) blocks impersonation at registration
  3. Handle changes enforce a 30-day cooldown and append a row to `handles_history`; `/u/{handle}` resolves and shows banded usage indicators (no raw token counts), with a per-profile public/unlisted toggle and `noindex` headers by default
  4. Account deletion is self-service and removes raw events within the documented retention window
  5. Pino is wired with the token-redaction transport and OpenTelemetry SDK is exporting traces — no log line emits an `sk-ant-*` token, and CI greps the build for that substring (this gate is from INGEST-10 but installed here)
**Plans**: TBD
**UI hint**: yes
**Risks (PITFALLS)**:
- Pitfall 6: Anthropic OAuth token leakage — Pino redaction filter installed before any handler logs anything
- Pitfall 9: Real-handle harassment surface — reserved-handle list, signup rate-limits, banded indicators, handle-change cooldown all ship in this phase
- Pitfall 8: Timezone semantics — store UTC, attach IANA on user, lock Temporal/Luxon for any day-bucket math from this phase forward

### Phase 2: RFC 8628 Device Authorization Flow
**Goal**: Make it possible to bind a local install to an account through a phishing-resistant browser flow before any CLI exists, smoke-tested with curl plus the browser.
**Depends on**: Phase 1
**Requirements**: PAIR-01, PAIR-02, PAIR-03, PAIR-04, PAIR-05, PAIR-06, PAIR-07, PAIR-08, PAIR-09, PAIR-10
**Success Criteria** (what must be TRUE):
  1. A `curl POST /device/code` returns a `device_code`, `user_code`, and `verification_uri_complete`; PKCE S256 + state are validated and rejected if missing
  2. The `/device` SvelteKit page requires the user to re-enter or confirm the `user_code`, displays User-Agent / OS / install id / requested scopes, and runs a slow-cook delay on first pair
  3. `user_code` TTL is capped at 10 minutes and `device.code` issuance is rate-limited per IP and per account
  4. Issued access tokens are bound to a per-install client identifier, an email is sent on every successful new pairing with a one-click revocation link, and `/settings/devices` lists active devices with revocation
**Plans**: TBD
**UI hint**: yes
**Risks (PITFALLS)**:
- Pitfall 4: OAuth Device Code phishing (Storm-2372) — the entire mitigation kit (user_code re-entry, rich context, TTL cap, rate limits, slow-cook, email-on-pair, per-install binding, PKCE+state) is concentrated here
- **Open question (deferred research):** Storm-2372 mitigation specifics in current Better Auth release — resolve at Phase 2 plan-check

### Phase 3: Event Ingest + Daily Rollup Worker
**Goal**: Build the durable substrate that quests, achievements, leaderboards, and anti-cheat all interpret — the raw event stream, daily rollups, and Anthropic usage cache.
**Depends on**: Phase 1
**Requirements**: INGEST-01, INGEST-02, INGEST-03, INGEST-04, INGEST-05, INGEST-06, INGEST-07, INGEST-08, INGEST-09 (logger tag here; install was Phase 1)
**Success Criteria** (what must be TRUE):
  1. `POST /v1/events` accepts batched events validated by Zod, deduplicates on UUID-v7 `Idempotency-Key`, and rejects requests missing the key
  2. Server-side velocity rate limits (per user, per device) and plausibility checks (impossible-delta rejection) run before any event is persisted
  3. Captured signals cover token usage rolling windows + lifetime totals, session length, messages sent, context efficiency, `/clear` and `/compact` events, and plugin/MCP installs
  4. Raw `events` table persists with a monthly partitioning path provisioned, and the `daily_user_stats` rollup worker materializes per-user-per-day aggregates on schedule
  5. The `usage-poll` worker caches results from `https://api.anthropic.com/api/oauth/usage` (5h/7d windows) per user, and a cross-source corroboration scaffold logs claimed-vs-cached deltas (without acting yet — actions arrive in Phase 10)
**Plans**: TBD
**Risks (PITFALLS)**:
- Pitfall 6: Anthropic OAuth token never reaches our backend; the `usage-poll` worker must call Anthropic with the user's token only via the helper's local path — clarify in plan-check
- INGEST-10 / CI grep gate on `sk-ant-` was already installed in Phase 1; reverify here when ingestion handles real payloads
- **Open question (deferred research):** Initial anti-cheat thresholds (refined in Phase 10) — first cut decided at Phase 3 plan-check

### Phase 4: Web App Shell
**Goal**: Stand up the SvelteKit web app with the locked theme schema and the read-only pages the rest of the project will plug game features into.
**Depends on**: Phase 1 (parallelizable with Phases 2-3)
**Requirements**: BRAND-01, BRAND-03
**Success Criteria** (what must be TRUE):
  1. SvelteKit 2 + Svelte 5 + Tailwind 4 + 8bitcn/ui + NES.css shell renders the retro arcade aesthetic with Press Start 2P + VT323 typography
  2. `/`, `/u/[handle]`, `/settings`, and `/device` pages exist as authenticated routes wired to Better Auth; profiles emit `noindex` headers by default
  3. The shared theme schema (palette + glyph frame format) is authored in `packages/content/cosmetics/` and consumed by both the web app and (later) the helper from a single source
  4. The web app boots from the same `docker-compose.yml` as the backend with no separate setup
**Plans**: TBD
**UI hint**: yes
**Risks (PITFALLS)**:
- Pitfall 9: Real-handle harassment — `noindex` defaults and banded indicators must be present in the profile shell from this phase
- Theme-schema lock-in: any drift between web and helper later is caused by skipping the single-source rule here

### Phase 5: Helper CLI
**Goal**: Ship the local CLI that captures Claude Code signals into a SQLite outbox and posts them to the backend without ever blocking a hook or asserting game state.
**Depends on**: Phase 2, Phase 3
**Requirements**: HELPER-01, HELPER-02, HELPER-03, HELPER-04, HELPER-05, HELPER-06, HELPER-07, HELPER-08, HELPER-09, HELPER-10, HELPER-11, HELPER-12, HELPER-13, BRAND-02
**Success Criteria** (what must be TRUE):
  1. `npm i -g` (or `npx`) installs the helper, and `pair`, `unpair`, `status`, `stats`, `statusline-fragment`, plus hook subcommands all work on Linux + macOS + Windows + Windows-ARM under Node 20 and Node 22 in CI
  2. Hook subcommands write to the local SQLite outbox in <50ms (hard) / <20ms (soft) and always exit 0; a top-level try/catch on every hook entry guarantees no error ever propagates into the Claude Code session
  3. The flusher daemon batches outbox entries every 5s active / 30s idle and immediately on `SessionEnd`; every request carries `User-Agent: gsd-helper/{version}`
  4. Helper renders a statusline fragment in the project's retro arcade aesthetic, exposes a documented data API for users to wire into any statusline, and never asserts game state — only reports observed signals
  5. Helper checks a remote feature flag on startup (kill switch), provides a pure-JS fallback when `better-sqlite3` native build fails, and never sends the Anthropic OAuth token (`~/.claude/.credentials.json`) to the backend
**Plans**: TBD
**UI hint**: yes
**Risks (PITFALLS)**:
- Pitfall 5: Helper crashes/latency hurting Claude Code sessions — fire-and-forget budget, try/catch-exit-0, pure-JS fallback, kill switch all required in this phase
- Pitfall 6: Anthropic OAuth token leakage — usage calls go local-only; backend never sees the token
- Pitfall 4: Per-install client identifier from Phase 2 must be respected when storing tokens via `conf`
- **Open question (deferred research):** Claude Code hook stability is a moving target — reverify event names/payloads via Context7 at Phase 5 plan-check

### Phase 6: Quest Engine + XP + Streaks
**Goal**: Deliver the daily game loop: 5 quests per user with per-user-timezone rotation, XP attribution and levels, and streak mechanics that don't induce anxiety.
**Depends on**: Phase 3, Phase 5
**Requirements**: QUEST-01, QUEST-02, QUEST-03, QUEST-04, QUEST-05, QUEST-06, QUEST-07, QUEST-08, QUEST-09, QUEST-10, QUEST-11, QUEST-12, QUEST-13, XP-01, XP-02, XP-03, XP-04, XP-05, STREAK-01, STREAK-02, STREAK-03, STREAK-04, STREAK-05, STREAK-06
**Success Criteria** (what must be TRUE):
  1. Each user receives 5 daily quests (3 global tiered easy/medium/hard at a ~1:3:8 XP ratio + 2 personalized: 1 strength, 1 growth-area), with a cold-start path delivering generic personalized quests for users with <7 days history, and zero rerolls
  2. The `daily-quest-rotate` worker rotates assignments per user at the user's IANA-local-day boundary (never a global cron) with a 3-6 hour grace window after local midnight; quest progress is visible via `GET /v1/me/quests/today` and the web app, completion triggers a celebration in both web and helper output, and 7-day quest history is browsable
  3. Lifetime XP is tracked per user, levels follow a ~10% exponential curve capped at 99, every XP gain attributes its source ("Completed quest: Send 25 messages — +10 XP"), and XP is awarded only by the server (never asserted by the helper)
  4. Streaks count consecutive days with at least one daily-quest completion, streak freezes auto-apply (1 per N completions, capped at 2 banked), vacation mode pauses without breaking, and a site-issue admin toggle protects active streaks during incidents
  5. No guilt-based notifications are sent for streak loss, and a "broken streak record" badge is awarded for surpassing a previous streak length
**Plans**: TBD
**UI hint**: yes
**Risks (PITFALLS)**:
- Pitfall 1: Overjustification — quests must be about *how* Claude Code is used (efficiency, context discipline, plugin diversity), never raw "use it 4 hours"; XP framed as informational record, not wage
- Pitfall 3: Streak anxiety (Duolingo/Habitica trap) — freezes default, vacation mode, grace window, no guilt notifications, cap meaningful streak rewards by ~30 days
- Pitfall 8: Timezone, midnight cluster, DST bugs — DST unit tests on spring-forward and fall-back across 3+ timezones are a phase exit gate
- **Open questions (deferred research):** quest **rule DSL design** and **personalization signal weighting** — both resolved at Phase 6 plan-check
- **Open question (deferred research):** whether streak repair (XP-debt within 48h) ships in v1 or waits — decision logged at end of Phase 6

### Phase 7: Achievements + Cosmetics
**Goal**: Layer the long-horizon reward track on top of XP events: achievements that unlock 1:1 cosmetics consumed identically by web and helper.
**Depends on**: Phase 6
**Requirements**: ACHIEVE-01, ACHIEVE-02, ACHIEVE-03, ACHIEVE-04, ACHIEVE-05, ACHIEVE-06, ACHIEVE-07, ACHIEVE-08, COSM-01, COSM-02, COSM-03, COSM-04, COSM-05, COSM-06, COSM-07
**Success Criteria** (what must be TRUE):
  1. Achievement catalog is seeded with a documented ~70% visible / 30% hidden mix, tiered (bronze/silver/gold) where applicable, with each achievement linked 1:1 to exactly one cosmetic in the schema (no orphaned cosmetics, no cosmetics earnable any other way)
  2. Achievement evaluation runs on every XP-affecting event (no nightly batch), unlocks trigger a celebration in both the web app and helper output, and the progress UI does not display a prominent "X of Y" total
  3. Launch ships at least 4 themes (Phosphor, Amber, NES, Mono) and animated glyph variants at 5-10 fps with a static fallback for non-TTY contexts; theme + loadout selections sync from the web app to the helper so unlocks change what the user actually sees
  4. The cosmetic deprecation policy is published guaranteeing earned cosmetics are never revoked, and the "broken streak record" badge from Phase 6 is integrated into the achievement catalog
**Plans**: TBD
**UI hint**: yes
**Risks (PITFALLS)**:
- Pitfall 1: Overjustification — surprise/hidden achievements outperform visible checklists; the 30% hidden share is a deliberate motivation-preservation lever
- Cosmetic deprecation policy is load-bearing for trust; must be published *with* the launch, not later
- **Open question (deferred research):** **animated glyph FPS budget** in non-TTY contexts (terminals without 24-bit color, Windows Terminal vs. iTerm2 vs. plain ConPTY) — resolved at Phase 7 plan-check

### Phase 8: Leaderboards
**Goal**: Turn aggregated state into rankings across four orthogonal dimensions with live updates and Goodhart-resistant copy that doesn't shame the bottom of the board.
**Depends on**: Phase 6, Phase 7
**Requirements**: LEADER-01, LEADER-02, LEADER-03, LEADER-04, LEADER-05, LEADER-06, LEADER-07, LEADER-08, LEADER-09, LEADER-10, LEADER-11, LEADER-12, LEADER-13, LEADER-14
**Success Criteria** (what must be TRUE):
  1. Four leaderboard dimensions (raw activity, streaks, quest XP, efficiency) × three windows (this week, this month, all-time) × two scopes (global + friends-only) all return correct, sane data through `GET /v1/leaderboards/{dim}`, with rankings computed from Valkey ZSETs and a Postgres `leaderboard_snapshots` mirror of the top 1,000
  2. Window keys age out via TTL (no global server-midnight reset), tie-break is lexicographic on `(score, earlier_achieved_at)`, and the raw-activity dimension uses a sanity-checked composite that caps per-window contribution and detects trivial tokens
  3. The SSE endpoint `/v1/sse/leaderboards/{dim}` pushes live rank updates and the user's own actions reflect optimistically with a clear cached-vs-live indicator
  4. The web UI default view shows a relative cohort with a soft floor below position N (no public bottom-of-list), new users have leaderboards hidden for their first week, and the efficiency leaderboard is positioned more prominently than raw activity in copy and layout
  5. Leaderboards are public by default and tied to the user's real handle
**Plans**: TBD
**UI hint**: yes
**Risks (PITFALLS)**:
- Pitfall 2: Goodhart's Law — composite raw-activity score, per-window contribution caps, trivial-token detection, quarterly formula rotation policy, and "raw" board ranked lowest-status in copy must all ship together; bolting any one on later kills credibility
- Pitfall 1: Overjustification — soft-floor cohort UI, hide-leaderboard-for-new-users, and efficiency-over-raw layout are motivation-preservation levers (not just UX preferences)
- **Open question (deferred research):** **efficiency leaderboard metric design** (candidates: `quests_completed_per_active_session` vs `useful_token_share = 1 - waste_ratio`) — resolved at Phase 8 plan-check before any score is published

### Phase 9: Social Hub
**Goal**: Build the social layer (follows, comments, kudos, friend feed, showcase) with the full moderation kit shipped *with* the features, not after.
**Depends on**: Phase 7, Phase 8
**Requirements**: SOC-01, SOC-02, SOC-03, SOC-04, SOC-05, SOC-06, SOC-07, SOC-08, SOC-09, SOC-10, SOC-11, SOC-12, SOC-13, SOC-14
**Success Criteria** (what must be TRUE):
  1. Asymmetric follow graph supports follow / unfollow / block; block and mute are immediate and irreversible without explicit unblock; there are no real-time "active now" indicators and no direct messaging
  2. Profile comments are off by default until the owner opts in, the owner controls who can comment (followers / mutual follows / disabled), comments are soft-deleted, rate-limited (max 3 per 60s), screened against a profanity wordlist, and link-containing comments are auto-flagged for owner review
  3. Users can react with kudos to other profiles' achievements, the friend feed surfaces friends' achievements and milestones from the last 7 days, and a bento-style showcase lets users pin badges and glyphs to their profile
  4. The report flow forwards to an admin moderation queue and auto-applies a temporary rate-limit on the reported account; notifications are off by default with in-app bell only at v1, email digests are weekly opt-in with quiet hours and RFC 8058 list-unsubscribe
  5. Schema includes foundation hooks for v2 raid coordination (data model only) — `RAID-04` is satisfied by `SOC-14` here
**Plans**: TBD
**UI hint**: yes
**Risks (PITFALLS)**:
- Pitfall 9: Real-handle harassment surface — comments-default-off, no DMs, no "active now", report+block+mute, profanity wordlist, link auto-flag, follower-count gating all ship in this phase
- Pitfall 7: Maintainer burnout — moderation tools must ship alongside the features that need them; admin queue is a phase-exit gate, not a follow-up
- **Open question (deferred research):** whether comments ship in v1 or defer to v1.1 — decided at Phase 9 kickoff

### Phase 10: Anti-Cheat Hardening + Admin Tools
**Goal**: Add cross-source corroboration, anomaly sweeps, query-layer shadow-ban, and the visible-flag-plus-appeal flow before any banning logic touches a real user.
**Depends on**: Phase 8, Phase 9
**Requirements**: CHEAT-01, CHEAT-02, CHEAT-03, CHEAT-04, CHEAT-05, CHEAT-06, CHEAT-07, CHEAT-08, CHEAT-09, CHEAT-10, CHEAT-11
**Success Criteria** (what must be TRUE):
  1. Server-side delta validation (from Phase 3) is reverified, the cross-source corroboration worker actively compares claimed token usage against the cached Anthropic OAuth usage API, and the daily anomaly-sweep worker flags statistical outliers
  2. Shadow-ban is enforced at the query layer (view or RLS), not the application layer; an audit log records every anti-cheat action with the rule that fired; an admin anomaly review queue lists pending actions for human review
  3. Affected users see a visible "we noticed unusual activity" flag with a single-click appeal form; appeals auto-restore after 7 days unless an admin explicitly upholds the action
  4. Confidence-tiered actions are wired (log → warn → rate-limit, never silent shadowban in v1) and the published anti-cheat philosophy document is live
  5. Helper-side anti-cheat work induces zero perceivable performance or UX cost in the user's Claude Code session (synthetic-monitoring CI gate from Phase 5 still passes)
**Plans**: TBD
**UI hint**: yes
**Risks (PITFALLS)**:
- Pitfall 10: Anti-cheat false positives destroying trust — visible flag, appeal flow, 7-day auto-restore, never silent shadowban in v1 are all required before any actioning logic is enabled
- Pitfall 2: Goodhart's Law — anomaly thresholds tuned together with the Phase 8 raw-activity composite
- **Open question (deferred research):** refined anti-cheat thresholds (initial cut from Phase 3) — resolved at Phase 10 plan-check

## Progress

**Execution Order:** Phases execute in numeric order: 0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10 (decimal phases inserted in numeric order if added later)

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 0. Project Setup, Privacy, and Sustainability Scaffolding | 4/4 | Complete    | 2026-05-09 |
| 1. Backend Skeleton + Auth | 0/TBD | Not started | - |
| 2. RFC 8628 Device Authorization Flow | 0/TBD | Not started | - |
| 3. Event Ingest + Daily Rollup Worker | 0/TBD | Not started | - |
| 4. Web App Shell | 0/TBD | Not started | - |
| 5. Helper CLI | 0/TBD | Not started | - |
| 6. Quest Engine + XP + Streaks | 0/TBD | Not started | - |
| 7. Achievements + Cosmetics | 0/TBD | Not started | - |
| 8. Leaderboards | 0/TBD | Not started | - |
| 9. Social Hub | 0/TBD | Not started | - |
| 10. Anti-Cheat Hardening + Admin Tools | 0/TBD | Not started | - |

## Traceability Summary

Every v1 requirement maps to exactly one phase. Zero unmapped, zero duplicates.

| Requirement range | Count | Phase | Notes |
|-------------------|-------|-------|-------|
| FND-01 → FND-08 | 8 | Phase 0 | OSS scaffolding + self-host parity |
| PRIV-01 → PRIV-05 | 5 | Phase 0 | Privacy/ToS/retention/analytics/redaction policy. Note: PRIV-05 (logger redaction) is *policy* in Phase 0 and *installed* in Phase 1 alongside Pino |
| AUTH-01 → AUTH-07 | 7 | Phase 1 | Email/password + GitHub OAuth, verification, reset, session, rate limits, deletion |
| IDENT-01 → IDENT-08 | 8 | Phase 1 | Real handle, reserved list, cooldown, history, profile route, visibility toggle, noindex, banded indicators |
| PAIR-01 → PAIR-10 | 10 | Phase 2 | RFC 8628 device flow + Storm-2372 mitigations |
| INGEST-01 → INGEST-10 | 10 | Phase 3 | Ingest, idempotency, rate limits, plausibility, partitioned events, rollups, usage poll, redaction transport, CI grep gate (latter two installed in Phase 1, owned by Phase 3 functionally) |
| BRAND-01, BRAND-03 | 2 | Phase 4 | Web aesthetic + shared theme schema |
| HELPER-01 → HELPER-13 | 13 | Phase 5 | CLI, hooks, outbox, flusher, kill switch, fallback, cross-platform, never-asserts-state |
| BRAND-02 | 1 | Phase 5 | Helper retro ANSI fragment |
| QUEST-01 → QUEST-13 | 13 | Phase 6 | 5 daily quests + per-user reset + grace + zero rerolls + 7-day history |
| XP-01 → XP-05 | 5 | Phase 6 | Lifetime XP, exponential curve, source attribution, server-only awards |
| STREAK-01 → STREAK-06 | 6 | Phase 6 | Counts, freezes, vacation, site-issue toggle, IANA tz, no guilt |
| ACHIEVE-01 → ACHIEVE-08 | 8 | Phase 7 | ~70/30 catalog, tiers, on-event eval, 1:1 cosmetic, deprecation policy, broken-streak-record badge |
| COSM-01 → COSM-07 | 7 | Phase 7 | Badges/glyphs/themes, animated frames, ≥4 launch themes, shared schema, inventory + loadout sync, achievement-only |
| LEADER-01 → LEADER-14 | 14 | Phase 8 | 4 dim × 3 windows × 2 scopes, ZSETs, snapshots, TTL, SSE, soft floor, new-user hide, efficiency-prominent, optimistic UI, tie-break, Goodhart-resistant raw composite |
| SOC-01 → SOC-14 | 14 | Phase 9 | Follows, opt-in comments, kudos, feed, showcase, moderation kit, no DMs/active-now, opt-in digests, raid foundation hooks |
| CHEAT-01 → CHEAT-11 | 11 | Phase 10 | Cross-source, anomaly sweep, query-layer shadow-ban, audit, admin queue, visible flag + appeal, tiered actions, philosophy doc |
| **Total** | **154** | **Phases 0-10** | **154 / 154 mapped, 0 unmapped, 0 duplicates** |

## Cross-Cutting Concerns

Locked decisions from `research/SUMMARY.md` § "Cross-Cutting Decisions to Lock Now". Each is tagged with the phase that first enforces it; later phases inherit and must not violate.

| Decision | First enforced in | Notes |
|----------|-------------------|-------|
| **Helper hard rule** — never asserts game state; only reports observed signals | Phase 0 (architecture doc) → Phase 5 (code enforcement) | HELPER-11 is the code-review gate |
| **License** — Apache-2.0 (preferred) or MIT; CI license-checker fails on GPL/AGPL/SSPL | Phase 0 | FND-01 / FND-02 |
| **Hosting cap** — public instance capped at a published number with overflow policy | Phase 0 | FND-04 |
| **Shutdown plan** — public, 90-day notice, full export, transfer-or-graceful-close | Phase 0 | FND-05 |
| **Self-host parity** — public instance and Docker Compose run from the same image | Phase 0 | FND-08 |
| **Notification policy** — opt-in only, default off, web-only at v1, no guilt copy | Phase 0 (policy) → Phase 9 (implementation) | SOC-13, STREAK-06 |
| **Data retention** — raw events 90 days; aggregates indefinite; account until deletion | Phase 0 (policy) → Phase 1 (deletion path) → Phase 3 (events table) | PRIV-03, AUTH-07, INGEST-06 |
| **Token-handling rule** — Anthropic OAuth token never reaches our backend; Pino redaction filter installed before any logger touches tokens | Phase 0 (policy) → Phase 1 (Pino) → Phase 5 (helper enforcement) | PRIV-05, INGEST-09, INGEST-10, HELPER-12 |
| **Reserved-handle list** — published, audited at launch and quarterly | Phase 1 | IDENT-02 |
| **Timezone semantics** — UTC storage, IANA on user, Temporal/Luxon, grace 3-6h, per-user reset never global cron | Phase 1 (storage shape) → Phase 6 (rotation worker) | STREAK-05, QUEST-07, QUEST-13 |
| **API versioning** — `/api/v1/...`; bump only on breaking; v1 ≥ 6 months past v2; helper sends version on every request | Phase 1 → Phase 5 (User-Agent) | HELPER-07 |
| **Anti-cheat appeal flow** — visible flag + single-click appeal + 7-day auto-restore + no silent shadowban in v1 | Phase 3 (policy in audit log shape) → Phase 10 (UI + worker) | CHEAT-07, CHEAT-08, CHEAT-09, CHEAT-11 |
| **Theme schema** — palette (ANSI) + glyph frame format authored in `packages/content/cosmetics/`, consumed by both web and helper | Phase 4 (web consumption) → Phase 5 (helper consumption) → Phase 7 (full set) | COSM-04 |
| **Cosmetic deprecation policy** — public, written, generous: earned cosmetics never removed | Phase 7 | ACHIEVE-08 |

## Open Questions Deferred to Phase-Specific Research

These are tracked in `research/SUMMARY.md` § "Open Questions Deferred to Phase-Specific Research" and surface as research flags during plan-check for the indicated phase.

| Open question | Resolves at | Why deferred |
|---------------|-------------|--------------|
| Storm-2372 mitigation specifics in current Better Auth release | **Phase 2** plan-check | Better Auth releases move faster than this roadmap; reverify at planning time |
| Claude Code hook event names / payloads | **Phase 5** plan-check | Hook surface is a moving target — Context7 reverify required before wire shape is locked |
| Quest **rule DSL design** (how to express "send N messages with context >70% green") | **Phase 6** plan-check | Concrete spec pending; depends on what events Phase 3 actually captures |
| Personalization signal weighting (which signals identify "skill the user shows" vs "growth area") | **Phase 6** plan-check | Needs >7 days of real ingest data to calibrate; cold-start path covers users below that threshold |
| Whether streak repair (XP-debt within 48h) ships in v1 | **End of Phase 6** | Decision depends on observed churn at first streak loss; placeholder STREAK-V2-01 in v2 list |
| **Animated glyph FPS budget** in non-TTY contexts | **Phase 7** plan-check | Terminal-capability matrix (Windows Terminal, iTerm2, ConPTY, plain xterm) needs verification |
| **Efficiency leaderboard metric design** (`quests_completed_per_active_session` vs `useful_token_share = 1 - waste_ratio`) | **Phase 8** plan-check | Must be locked before any score is publicly visible |
| Whether comments ship in v1 or defer to v1.1 | **Phase 9** kickoff | Moderation cost vs social value tradeoff; revisit after Phase 8 social signals |
| Refined anti-cheat thresholds (initial cut at Phase 3, refined here) | **Phase 10** plan-check | Needs real distributions from Phases 6-8 before tuning |
| TimescaleDB — only at tens of thousands of users | Milestone boundary, not a phase | Out of v1 scope; explicitly flagged in research summary |

## Possible Scope Risks

Items I considered while validating coverage and want to flag *without* auto-adding (per instructions, v1 scope is frozen). Surfacing them so the orchestrator can decide:

1. **Helper auto-update / version-check UX is implicit, not explicit.** HELPER-07 sends a User-Agent and HELPER-08 has a kill switch, but there is no v1 requirement for surfacing "your helper is N versions behind, please update." If the kill switch fires, users may be left guessing. Worth confirming this is intentional v2.
2. **Email infrastructure is implied across multiple phases (verification, password reset, pairing notice, weekly digest) but no single requirement names the email provider, deliverability posture, or DMARC/DKIM setup.** Likely a Phase 1 plan-check concern.
3. **Admin tooling beyond the moderation queue and anomaly review queue is not specified.** Account merging, manual badge grants, support tooling — none are in v1. May surface as gaps at Phase 9 / 10 review.
4. **There is no v1 requirement for OpenAPI / typed-client generation,** even though Drizzle + Zod make it nearly free. Worth a Phase 1 plan-check decision (ship now vs defer).
5. **Backup/restore and disaster-recovery posture for Postgres + Valkey are not in v1.** PRIV-03 mandates retention but doesn't address durability. The shutdown-plan export path (FND-05) is the closest analogue. Worth flagging at Phase 0 plan-check.

None of these block roadmap acceptance — flagging only.

---
*Roadmap created: 2026-05-08*
*Source: PROJECT.md + REQUIREMENTS.md + research/SUMMARY.md (recommended phase order locked)*
*Granularity: fine (11 phases, including Phase 0)*

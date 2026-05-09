# Requirements: Claude Code Gamification Service

**Defined:** 2026-05-08
**Core Value:** Make daily Claude Code usage feel less transactional and more rewarding, through honest gamification of the workflow signals users already generate.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Project Foundation & Sustainability

- [x] **FND-01**: Codebase is published under a permissive OSS license (Apache-2.0 preferred, MIT acceptable)
- [x] **FND-02**: CI fails any pull request that introduces a GPL/AGPL/SSPL/RSALv2 transitive dependency
- [x] **FND-03**: Repository ships with `CONTRIBUTING.md` and a published Code of Conduct
- [x] **FND-04**: Public hosted instance enforces a published user-count cap with a documented overflow policy
- [x] **FND-05**: Public shutdown plan documents 90-day notice window and full data export path
- [x] **FND-06**: Donations channel (GitHub Sponsors or equivalent) is linked from the README and web app footer
- [x] **FND-07**: README explicitly states maintenance posture (hobby project, best-effort response)
- [x] **FND-08**: `docker-compose.yml` boots a self-hosted instance from the same images as the public instance

### Authentication

- [ ] **AUTH-01**: User can sign up with email and password
- [ ] **AUTH-02**: User can sign up / log in with GitHub OAuth
- [ ] **AUTH-03**: User receives email verification after email/password signup
- [ ] **AUTH-04**: User can reset password via email link
- [ ] **AUTH-05**: User session persists across browser refresh
- [ ] **AUTH-06**: Signup is rate-limited per IP and per email domain to deter mass-account abuse
- [ ] **AUTH-07**: Account deletion is self-service and removes raw events within the documented retention window

### Identity & Profiles

- [ ] **IDENT-01**: User chooses a public real handle at signup (Twitch-style)
- [ ] **IDENT-02**: Reserved-handle list (~200 names) blocks impersonation of platform/famous identities at registration time
- [ ] **IDENT-03**: Handle changes enforce a 30-day cooldown
- [ ] **IDENT-04**: `handles_history` audit table records every handle change with timestamp
- [ ] **IDENT-05**: Public profile page is reachable at `/u/{handle}` showing badges, stats, achievements, and leaderboard standings
- [ ] **IDENT-06**: Profile owner can toggle profile visibility (public / unlisted)
- [ ] **IDENT-07**: Profile pages emit `noindex` headers by default
- [ ] **IDENT-08**: Profile displays banded indicators (color tiers) rather than raw token counts to limit doxxing of usage volume

### Device Pairing (Onboarding)

- [ ] **PAIR-01**: CLI initiates device pairing via RFC 8628 OAuth Device Authorization Grant
- [ ] **PAIR-02**: PKCE S256 + state parameter are mandatory on every device-code request
- [ ] **PAIR-03**: `/device` web page requires user to re-enter or confirm the `user_code` (anti-phishing)
- [ ] **PAIR-04**: `/device` page displays rich device context (User-Agent, OS, install id, requested scopes)
- [ ] **PAIR-05**: `user_code` time-to-live is capped at 10 minutes
- [ ] **PAIR-06**: `device.code` issuance is rate-limited per IP and per account
- [ ] **PAIR-07**: First-time pair includes a slow-cook confirmation step (delay before activation)
- [ ] **PAIR-08**: User receives an email on every successful new pairing with a one-click revocation link
- [ ] **PAIR-09**: User can list and revoke active devices from `/settings/devices`
- [ ] **PAIR-10**: Issued tokens are bound to a per-install client identifier

### Helper / Local Integration

- [ ] **HELPER-01**: Helper module is published as an npm package installable via `npm i -g` or `npx`
- [ ] **HELPER-02**: Helper exposes commands: `pair`, `unpair`, `status`, `stats`, `statusline-fragment`, plus hook subcommands
- [ ] **HELPER-03**: Hook subcommands write to a local SQLite outbox in <50 ms (hard) / <20 ms (soft) and return exit code 0
- [ ] **HELPER-04**: Every hook entry has a top-level try/catch that always exits 0, never propagating errors into the Claude Code session
- [ ] **HELPER-05**: Helper provides a pure-JS fallback when `better-sqlite3` native build fails (e.g., Windows-ARM)
- [ ] **HELPER-06**: A flusher daemon batches outbox entries to the backend (5s active / 30s idle / immediate on `SessionEnd`)
- [ ] **HELPER-07**: All requests to the backend carry a `User-Agent: gsd-helper/{version}` header
- [ ] **HELPER-08**: Helper checks a remote feature flag on startup and can be remotely disabled (kill switch)
- [ ] **HELPER-09**: Helper exposes a documented data API for users to wire into any statusline implementation
- [ ] **HELPER-10**: Helper renders a statusline fragment in the project's retro arcade aesthetic for users who choose to use it
- [ ] **HELPER-11**: Helper never asserts game state — only reports observed signals (architectural rule, enforced by code review)
- [ ] **HELPER-12**: Helper never sends the Anthropic OAuth token (`~/.claude/.credentials.json`) to the backend
- [ ] **HELPER-13**: Helper supports Linux, macOS, Windows, and Windows-ARM under Node 20 and Node 22 in CI

### Event Ingestion & Signal Capture

- [ ] **INGEST-01**: `POST /v1/events` accepts batched events with Zod schema validation
- [ ] **INGEST-02**: Every request requires an `Idempotency-Key` (UUID v7) for safe retry deduplication
- [ ] **INGEST-03**: Server enforces velocity rate limits per user and per device
- [ ] **INGEST-04**: Server applies plausibility checks (rejects impossible deltas) before persisting events
- [ ] **INGEST-05**: Captured signals include token usage rolling windows + lifetime totals, session length, messages sent, context efficiency, `/clear` and `/compact` events, and plugin/MCP installs
- [ ] **INGEST-06**: Raw `events` table persists with monthly partitioning path provisioned
- [ ] **INGEST-07**: A `daily_user_stats` rollup worker materializes per-user-per-day aggregates
- [ ] **INGEST-08**: A `usage-poll` worker caches results from `https://api.anthropic.com/api/oauth/usage` (5h/7d windows) on the user's behalf
- [ ] **INGEST-09**: Pino logger ships with a token-redaction transport from day one (no raw OAuth tokens in logs)
- [ ] **INGEST-10**: CI grep gate fails the build on any commit containing an `sk-ant-` substring

### Quests

- [ ] **QUEST-01**: Each user receives 5 daily quests (3 global tiered + 2 personalized)
- [ ] **QUEST-02**: 3 global quests are tiered easy / medium / hard and identical for every user that day
- [ ] **QUEST-03**: 1 personalized quest builds on a skill the user already shows
- [ ] **QUEST-04**: 1 personalized quest pushes a documented growth area
- [ ] **QUEST-05**: Quests award XP only — no badges or cosmetic drops
- [ ] **QUEST-06**: Easy / medium / hard XP scaling follows roughly a 1:3:8 ratio (e.g., 10 / 25 / 100 XP)
- [ ] **QUEST-07**: Quest assignments rotate per user at the user's local-day boundary (per-user IANA timezone, never a global cron)
- [ ] **QUEST-08**: Cold-start path delivers generic personalized quests for users with fewer than 7 days of history
- [ ] **QUEST-09**: Quests support zero rerolls (deliberate scarcity)
- [ ] **QUEST-10**: Quest progress is visible via the helper API and the web app
- [ ] **QUEST-11**: Quest completion triggers a celebration animation in the web app and a status update in the helper output
- [ ] **QUEST-12**: 7-day quest history is visible to the user
- [ ] **QUEST-13**: Grace window of 3-6 hours after the user's local midnight before previous-day quests are closed

### XP & Leveling

- [ ] **XP-01**: Lifetime XP is tracked per user and visible on the public profile
- [ ] **XP-02**: Levels follow a roughly 10% exponential curve, capped at 99
- [ ] **XP-03**: Every XP gain attributes its source (e.g., "Completed quest: Send 25 messages — +10 XP")
- [ ] **XP-04**: Level-up triggers a one-time celebration in the web app
- [ ] **XP-05**: XP is awarded only by the server, never asserted by the helper

### Achievements

- [ ] **ACHIEVE-01**: Achievement catalog is seeded at launch with a documented mix of approximately 70% visible / 30% hidden
- [ ] **ACHIEVE-02**: Tiered achievements use bronze / silver / gold tiers where applicable
- [ ] **ACHIEVE-03**: Achievement evaluation runs on every XP-affecting event (no nightly batch for unlocks)
- [ ] **ACHIEVE-04**: Each achievement is linked 1:1 to exactly one cosmetic reward in the schema
- [ ] **ACHIEVE-05**: Achievement unlock triggers a celebration in the web app and the helper output
- [ ] **ACHIEVE-06**: Achievement progress UI does not display a prominent "X of Y" total to avoid completionist anxiety
- [ ] **ACHIEVE-07**: A "broken streak record" badge is awarded for surpassing a previous streak length
- [ ] **ACHIEVE-08**: A published cosmetic deprecation policy guarantees earned cosmetics are never revoked

### Cosmetics

- [ ] **COSM-01**: Cosmetics include three types: badges, glyphs, and themes
- [ ] **COSM-02**: Glyphs support animated variants at 5-10 fps with a static fallback for non-TTY contexts
- [ ] **COSM-03**: Launch ships with at least 4 themes (Phosphor, Amber, NES, Mono)
- [ ] **COSM-04**: Theme schema (palette + glyph frame format) is consumed by both helper and web from a single source
- [ ] **COSM-05**: Users have an inventory + equip + loadout view in the web app
- [ ] **COSM-06**: Loadout selections sync to the helper so unlocks actually change what the user sees locally
- [ ] **COSM-07**: Cosmetics are only awarded by achievements (no XP shop, no random drops, no purchases)

### Streaks

- [ ] **STREAK-01**: Streak counts consecutive days the user completed at least one daily quest
- [ ] **STREAK-02**: Streak freezes are auto-applied to forgive a missed day (1 freeze per N completions, capped at 2 banked)
- [ ] **STREAK-03**: Vacation mode pauses streak tracking without breaking it
- [ ] **STREAK-04**: Site-issue admin toggle protects all active streaks during incidents
- [ ] **STREAK-05**: Streak math uses the user's IANA timezone with the configured grace window
- [ ] **STREAK-06**: System sends no guilt-based notifications about streak loss

### Leaderboards

- [ ] **LEADER-01**: Four leaderboard dimensions exist: raw activity, streaks, quest XP, efficiency
- [ ] **LEADER-02**: Each dimension exposes three windows: this week, this month, all-time
- [ ] **LEADER-03**: Each dimension exposes two scopes: global and friends-only
- [ ] **LEADER-04**: Rankings are computed from Valkey ZSETs with a Postgres `leaderboard_snapshots` mirror of the top 1,000
- [ ] **LEADER-05**: Window keys age out via TTL rather than a global server-midnight reset
- [ ] **LEADER-06**: Public read endpoint `GET /v1/leaderboards/{dim}` returns the requested window/scope
- [ ] **LEADER-07**: SSE endpoint `/v1/sse/leaderboards/{dim}` pushes live rank updates
- [ ] **LEADER-08**: Web UI default view shows a relative cohort with a soft floor below position N (no public bottom-of-list)
- [ ] **LEADER-09**: New users have leaderboards hidden for their first week
- [ ] **LEADER-10**: Efficiency leaderboard is positioned more prominently than raw activity in copy and layout
- [ ] **LEADER-11**: User's own actions reflect optimistically with a clear cached-vs-live indicator
- [ ] **LEADER-12**: Tie-break is lexicographic on `(score, earlier_achieved_at)`
- [ ] **LEADER-13**: Leaderboards are public by default and tied to the user's real handle
- [ ] **LEADER-14**: Raw-activity dimension uses a sanity-checked composite (caps per-window contribution; detects trivial tokens) to resist Goodhart's Law

### Social Hub

- [ ] **SOC-01**: Asymmetric follow graph (Twitter-style) supports follow / unfollow / block
- [ ] **SOC-02**: Profile comments are off by default until the profile owner opts in
- [ ] **SOC-03**: Comment owner can choose who is allowed to comment (followers / mutual follows / disabled)
- [ ] **SOC-04**: Users can react with kudos to other profiles' achievements
- [ ] **SOC-05**: Friend feed surfaces friends' achievements and milestones from the last 7 days
- [ ] **SOC-06**: Bento-style showcase lets users pin badges and glyphs to their profile
- [ ] **SOC-07**: Comments are soft-deleted, rate-limited (max 3 per 60s), and screened against a profanity wordlist
- [ ] **SOC-08**: Comments containing links are automatically flagged for owner review
- [ ] **SOC-09**: Block and mute actions are immediate and irreversible without explicit unblock
- [ ] **SOC-10**: Report flow forwards to an admin moderation queue and auto-applies a temporary rate-limit on the reported account
- [ ] **SOC-11**: No real-time "active now" presence indicators
- [ ] **SOC-12**: No direct messaging
- [ ] **SOC-13**: Notifications are off by default, in-app bell only at v1; email digests are weekly opt-in with quiet hours and RFC 8058 list-unsubscribe
- [ ] **SOC-14**: Schema includes foundation hooks for v2 raid coordination (data model only)

### Anti-Cheat

- [ ] **CHEAT-01**: Server-side delta validation rejects impossible deltas at ingestion
- [ ] **CHEAT-02**: Cross-source corroboration worker compares claimed token usage against the cached Anthropic OAuth usage API
- [ ] **CHEAT-03**: Daily anomaly-sweep worker flags statistical outliers
- [ ] **CHEAT-04**: Shadow-ban is enforced at the query layer (view or RLS), not the application layer
- [ ] **CHEAT-05**: Audit log records every anti-cheat action with the rule that fired
- [ ] **CHEAT-06**: Admin anomaly review queue lists pending actions for human review
- [ ] **CHEAT-07**: Visible "we noticed unusual activity" flag is shown to the affected user with a single-click appeal form
- [ ] **CHEAT-08**: Appeals auto-restore after 7 days unless an admin explicitly upholds the ban
- [ ] **CHEAT-09**: Confidence-tiered actions: log → warn → rate-limit, never silent shadowban in v1
- [ ] **CHEAT-10**: Anti-cheat induces zero perceivable performance or UX cost in the user's Claude Code session
- [ ] **CHEAT-11**: Anti-cheat philosophy document is published publicly

### Privacy & Data Handling

- [x] **PRIV-01**: Privacy policy and Terms of Service are linked from every page footer
- [x] **PRIV-02**: Granular consent model: users consent separately to event capture, public leaderboards, and email digests
- [x] **PRIV-03**: Raw events retention is 90 days; aggregates may be retained indefinitely
- [x] **PRIV-04**: Public hosted instance uses Plausible (or equivalent privacy-respecting analytics), never Google Analytics
- [x] **PRIV-05**: All API tokens and sensitive headers are redacted in logs

### Visual Identity

- [ ] **BRAND-01**: Web app uses a retro arcade aesthetic (pixel/ASCII art, 8-bit palette, score-popup feel)
- [ ] **BRAND-02**: Helper output uses a matching retro arcade aesthetic in segmented ANSI form
- [ ] **BRAND-03**: Themes are interchangeable across web and helper through the shared theme schema

## v2 Requirements

Deferred to a future release. Tracked but not in the current roadmap.

### Cooperative Raids

- **RAID-01**: Community-wide goal events with shared progress meter
- **RAID-02**: Real-time raid coordination via WebSockets
- **RAID-03**: Raid-specific cosmetic rewards
- **RAID-04**: Foundation hooks present in v1 schema (delivered as `SOC-14`)

### Companions

- **COMP-01**: Persistent statusline creature that grows with the user
- **COMP-02**: Companion evolution tied to long-horizon usage milestones
- **COMP-03**: Companion theme integration with cosmetic loadouts

### Streak Repair

- **STREAK-V2-01**: Optional XP-debt streak repair within 48 hours of a missed day (ship if streak loss drives churn)

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Quest designer / community-submitted quests | Moderation surface area too large for v1 |
| Mobile native app | Web-first; native client deferred indefinitely |
| Paid cosmetic store / subscription tier | Every cosmetic earned through achievements; OSS + donations model |
| Random loot drops | Every cosmetic must trace to an achievement story |
| XP shop | Removes the need to balance an XP economy |
| Hard server-side payload signing | Only adopt if zero-friction; v1 tolerates some gaming |
| Lifetime-only leaderboards | Shuts out new users; LEADER-02 windows mitigate |
| Public commit-style daily-activity heatmap | GitHub removed contribution streaks for being harmful |
| Direct messaging | Inbox abuse surface too large for v1 |
| Public "shame" stats / reverse leaderboards | Violates non-guilt design principle |
| Mandatory streaks (no freezes) | Streak anxiety; STREAK-02 mandatory |
| Push notifications / streak-loss-warning emails by default | Default-off; opt-in only |
| AI-assisted "quest of the day" coaching | Out of v1 scope; risk of overjustification |
| Real money cashout / item trading | Legal and abuse surface |
| Statusline lock-in | Helper module exposes data; users keep their own statusline |
| Localhost OAuth callback (`http://localhost:PORT/callback`) | Use RFC 8628 device flow instead |
| Anonymous handles by default | Real-handle identity is a deliberate product decision |

## Traceability

Which phases cover which requirements. Populated during roadmap creation. Pre-mapping below reflects research/SUMMARY.md phase recommendations and will be confirmed by the roadmap step.

| Requirement | Phase | Status |
|-------------|-------|--------|
| FND-01 → FND-08 | Phase 0 | Pending |
| AUTH-01 → AUTH-07 | Phase 1 | Pending |
| IDENT-01 → IDENT-08 | Phase 1 | Pending |
| PRIV-01 → PRIV-05 | Phase 0 | Pending |
| PAIR-01 → PAIR-10 | Phase 2 | Pending |
| INGEST-01 → INGEST-10 | Phase 3 | Pending |
| BRAND-01, BRAND-03 | Phase 4 | Pending |
| HELPER-01 → HELPER-13 | Phase 5 | Pending |
| BRAND-02 | Phase 5 | Pending |
| QUEST-01 → QUEST-13 | Phase 6 | Pending |
| XP-01 → XP-05 | Phase 6 | Pending |
| STREAK-01 → STREAK-06 | Phase 6 | Pending |
| ACHIEVE-01 → ACHIEVE-08 | Phase 7 | Pending |
| COSM-01 → COSM-07 | Phase 7 | Pending |
| LEADER-01 → LEADER-14 | Phase 8 | Pending |
| SOC-01 → SOC-14 | Phase 9 | Pending |
| CHEAT-01 → CHEAT-11 | Phase 10 | Pending |

**Coverage:**
- v1 requirements: 154 total
- Mapped to phases: 154
- Unmapped: 0 (pending roadmap confirmation)

---
*Requirements defined: 2026-05-08*
*Last updated: 2026-05-08 after initial definition*

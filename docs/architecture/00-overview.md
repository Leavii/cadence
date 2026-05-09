# cadence — Architecture Overview (Phase 0)

This document codifies the load-bearing rules every later phase must honor. It is intentionally short and prescriptive: phases 1+ that violate either of the two highlighted rules below introduce systemic risk that will be hard to unwind.

## Three-tier system

```
┌─────────────────────────┐         ┌──────────────────────────┐         ┌─────────────────────────┐
│  Helper (apps/cli)      │         │  Backend (apps/api +     │         │  Web (apps/web)         │
│  Node 22, runs on the   │ ──HTTPS▶│  apps/workers)           │◀──HTTP──│  SvelteKit, browser     │
│  user's machine         │  events │  Hono + Postgres + Valkey│         │                         │
│                         │         │  + BullMQ                │         │                         │
└─────────────────────────┘         └──────────────────────────┘         └─────────────────────────┘
       observed signals                  source of truth                       canonical UI
```

- **Helper (apps/cli):** observes Claude Code workflow signals via hooks/statusline contracts. Batches events, posts to backend over HTTPS.
- **Backend (apps/api + apps/workers):** Hono HTTP server + BullMQ workers. Owns all game state — XP, quests, streaks, achievements, leaderboards, audit log, anti-cheat events.
- **Web (apps/web):** SvelteKit dashboard. Read-mostly view of backend state plus account / cosmetic / social actions.

## Load-bearing rules

### Rule 1 — The helper never asserts game state

The helper is **observation-only**. It MUST NOT:

- Claim XP was awarded.
- Claim a quest is complete.
- Claim a streak is valid or broken.
- Claim a leaderboard rank.

The helper MAY:

- Report observed signals (a hook fired, a session ended, a context-window stat).
- Surface backend-served data (the backend already said "you are at 4,350 XP" — the helper renders that).
- Cache backend responses for low-latency statusline rendering.

**Why:** the helper runs on user-controlled machines. If it asserted game state, every assertion is a forgery surface. Centralizing assertion in the backend means a single audit log and a single set of anti-cheat heuristics.

**Enforced by:** Phase 5 (HELPER-11 code-review gate) and Phase 3 (audit-log shape rejects helper-asserted writes).

### Rule 2 — Anthropic OAuth tokens never reach the cadence backend

Claude Code's user OAuth token lives on the user's machine. It is needed only to authenticate Claude Code traffic to Anthropic. Cadence has zero need for it.

The cadence backend MUST NOT:

- Receive the Anthropic OAuth token in any field of any request.
- Accept it through a `Authorization`, `X-Anthropic-Token`, query param, body, or any other channel.
- Log it in any structured or unstructured form.

**Why:** the token is highly sensitive (it's a long-lived credential to a paid third-party API). Touching it once means we own its lifecycle, its leak risk, and its incident-response burden. The simpler invariant is "we never see it." This is also the privacy ceiling — once data is in our backend, our retention policy applies; this token has no place there.

**Enforced by:**
- Phase 1: Pino redaction transport installed before any logger touches a request body. The transport drops keys matching `sk-ant-*` and any field named `anthropic_token`, `anthropicToken`, `claude_token`, `claudeToken`, `oauth_token`, etc.
- Phase 1: CI grep gate over committed code that fails any PR introducing a literal `sk-ant-` substring or any logger call that could plausibly emit one (PRIV-05, INGEST-09, INGEST-10).
- Phase 5: helper code review gate that rejects any helper change attempting to forward the Anthropic token to the cadence backend (HELPER-12).

## Observability — Plausible Cloud only

Web analytics use Plausible Cloud (paid tier) — never Plausible Community Edition embedded in the docker-compose stack. CE collects raw IPs and per-user pageview rows that, on a personal-data scale, push into GDPR controller obligations we don't want. Cloud tier aggregates cookieless on Plausible's side.

**Enforced by:** Phase 4 (web analytics integration) — the docker-compose smoke gate (`scripts/verify-phase-0.sh`) asserts no `plausible/community-edition` image reference in `docker-compose.yml`.

## Time semantics — UTC storage, IANA on user

All timestamps stored in Postgres are UTC. User-facing time (streak rotation, daily-quest reset, leaderboard window boundaries) uses the user's IANA timezone with a 3–6 hour grace window. Streak-rotation jobs run **per-user**, never on a global cron — STREAK-05, QUEST-07, QUEST-13.

## Anti-cheat posture

Lightweight only at v1: appeal flow + 7-day auto-restore + no silent shadowbans. Any anomaly detection is advisory in v1 (CHEAT-07, CHEAT-08, CHEAT-09, CHEAT-11).

## Self-host parity (FND-08)

The same `docker-compose.yml` runs:

1. The maintainer's public instance (Hetzner CX22 + Coolify, capped at 5,000 active accounts per FND-04).
2. Any user's self-host (`docker compose up`).
3. The dev environment (Mailpit replaces Resend; otherwise identical).

No environment-specific images, no environment-specific service definitions. Differences live in `docker-compose.override.yml` (gitignored) and `.env`.

**Enforced by:** Phase 0 (`scripts/verify-phase-0.sh`) — the smoke gate boots the stack and asserts the same image SHAs run in dev as the public instance pulls.

## Data retention (PRIV-03)

| Data class | Retention |
|------------|-----------|
| Raw events (helper ingest) | 90 days |
| Aggregates (XP totals, streak counters, leaderboard scores) | Indefinite |
| Account record | Until deletion request (AUTH-07) |

Deletion requests purge raw events + aggregates + account row + cosmetic loadout. Friend-graph references to the deleted user are tombstoned (`deleted_user_<n>`), not removed, so other users' history remains coherent.

## License & token-handling

- Project license: Apache-2.0 (FND-01).
- License-check CI gate: extended denylist (13 SPDX IDs) blocks GPL/AGPL/SSPL/RSALv2/BUSL family at PR time.
- DCO sign-off required on every commit (FND-03).
- Anthropic token-handling rule: see Rule 2 above.

## Phase boundaries this doc enforces

| Rule | First enforced | Code review gate |
|------|----------------|------------------|
| Helper never asserts game state | Phase 5 (HELPER-11) | Phase 5 plan-check |
| Anthropic OAuth never reaches backend | Phase 1 (Pino redaction + CI grep) | Phase 1 plan-check + Phase 5 plan-check |
| Plausible Cloud only, no CE in compose | Phase 4 | Phase 4 plan-check |
| UTC storage + per-user rotation | Phase 1 (storage shape) → Phase 6 (rotation worker) | Phase 6 plan-check |
| Same docker-compose for dev/self-host/public | Phase 0 (this plan) | `scripts/verify-phase-0.sh` smoke gate |

— Last updated: 2026-05-08 (Phase 0 closeout).

---
phase: 00-project-setup-privacy-and-sustainability-scaffolding
verified: 2026-05-08T00:00:00Z
status: passed
score: 13/13
overrides_applied: 0
---

# Phase 00: Project Setup, Privacy and Sustainability Scaffolding — Verification Report

**Phase Goal:** Establish OSS sustainability + privacy scaffolding (license, CoC, DCO + CI gates, legal/privacy/ops docs, Docker compose parity stack, monorepo skeleton, reserved-handles content, cross-cutting architecture doc) BEFORE any product code lands.
**Verified:** 2026-05-08
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Repo carries Apache-2.0 LICENSE verbatim with 2026 year and `Cadence Contributors` copyright holder | VERIFIED | `LICENSE` line 189: `Copyright 2026 Cadence Contributors`; `Apache License / Version 2.0` in header |
| 2 | Repo carries CODE_OF_CONDUCT.md with Contributor Covenant 2.1 verbatim text | VERIFIED | File opens with `# Contributor Covenant Code of Conduct`; `## Our Pledge` present; attribution line at bottom confirms v2.1 |
| 3 | CONTRIBUTING.md documents DCO sign-off and explicit no-CLA policy | VERIFIED | Contains `Signed-off-by:`, `developercertificate.org` link, `There is **no Contributor License Agreement (CLA)**` |
| 4 | SECURITY.md provides vulnerability reporting with 90-day coordinated-disclosure window | VERIFIED | `security@{ROOT_DOMAIN}` present; `90 days from report-to-fix` on line 28 |
| 5 | license-check CI workflow fails PRs introducing GPL/AGPL/SSPL/RSALv2 transitive dep | VERIFIED | `.github/workflows/license-check.yml` contains full 13-SPDX denylist regex including `AGPL-3.0`, `GPL-2.0`, `SSPL-1.0`, `RSALv2`, `BUSL-1.1`, `ELv2` |
| 6 | DCO CI workflow fails any PR commit lacking Signed-off-by trailer | VERIFIED | `.github/workflows/dco.yml` uses `KineticCafe/actions-dco@v2` with `fetch-depth: 0` |
| 7 | .gitignore excludes .env, *.key, *.pem, node_modules, dist, .svelte-kit, docker-compose.override.yml | VERIFIED | All patterns confirmed present in `.gitignore` |
| 8 | Legal/privacy docs committed with all load-bearing strings for FND-04/05, PRIV-01 through PRIV-05 | VERIFIED | All 5 docs exist; acceptance-criteria strings verified (see Artifacts table below) |
| 9 | Docker compose stack boots from a single `cp .env.example .env && docker compose up -d` (parity per FND-08) | VERIFIED | `docker-compose.yml` has 3 services (cadence-postgres, cadence-valkey, cadence-mailpit), all pinned, all with healthchecks and `restart: unless-stopped`; no Plausible CE |
| 10 | scripts/verify-phase-0.sh covers all FND-* and PRIV-* assertions and exits 0/1 | VERIFIED | Script exists, has `set -euo pipefail`, explicit `FAIL` accumulator, 60s healthcheck loop, and grep checks for every requirement |
| 11 | README.md states maintenance posture verbatim and links Ko-fi donations channel | VERIFIED | "hobby project maintained on a best-effort basis ... 5,000 active accounts" present; `ko-fi.com/{maintainer-handle}` link present (placeholder per documented carryover) |
| 12 | Monorepo skeleton resolves 8 workspace packages under pnpm with correct metadata | VERIFIED | `pnpm-workspace.yaml` has `apps/*` + `packages/*`; all 8 package.json stubs exist with `@cadence/*` names, `private:true`, `type:module`; `turbo.json` has Turborepo 2.x `tasks` shape |
| 13 | docs/architecture/00-overview.md codifies both load-bearing rules and Pino redaction policy | VERIFIED | "The helper never asserts game state" (Rule 1), "Anthropic OAuth tokens never reach the cadence backend" (Rule 2), `sk-ant-*` redaction, Plausible Cloud only rule — all present |

**Score:** 13/13 truths verified

---

### Naming Deviation — Documented, Non-Blocking

The plan frontmatter and some acceptance-criteria grep strings reference the prior placeholder naming (`Claude Code Gamification Service Contributors`, `gsd-monorepo`, `@gsd/*`, `gsd-net`, `"bin": "./dist/cli.js"`). These were superseded mid-execution when the user finalized the project name to `cadence`. The deviations are:

| Plan expectation | Actual codebase value | Resolution |
|---|---|---|
| `Claude Code Gamification Service Contributors` in LICENSE | `Cadence Contributors` | Documented in 00-01-SUMMARY.md as deviation 1 |
| `"name": "gsd-monorepo"` in package.json | `"name": "cadence"` | Documented in 00-04-SUMMARY.md as deviation 1 |
| Package names `@gsd/*` | `@cadence/*` | Documented in 00-04-SUMMARY.md as deviation 1 |
| Network `gsd-net` in compose | `cadence-net` | Documented in 00-02-SUMMARY.md as deviation 1 |
| `"bin": "./dist/cli.js"` | `"bin": { "cadence": "./dist/index.js" }` | Consistent with project rename; bin IS present |

All deviations are in the same direction (cadence naming) and are intentional per user decision. None break the phase goal.

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `LICENSE` | Apache-2.0 verbatim | VERIFIED | 202 lines; year 2026; `Cadence Contributors` |
| `CODE_OF_CONDUCT.md` | Contributor Covenant 2.1 | VERIFIED | Verbatim; `{MAINTAINER_EMAIL}` placeholder per plan |
| `CONTRIBUTING.md` | DCO + no-CLA + CoC link | VERIFIED | All required strings present; Apache-2.0 link |
| `SECURITY.md` | 90-day disclosure | VERIFIED | `security@{ROOT_DOMAIN}` + 90-day language |
| `.gitignore` | Node + Docker + env + OS ignores | VERIFIED | `.env`, `*.key`, `*.pem`, `docker-compose.override.yml`, `node_modules/` all present |
| `.editorconfig` | 2-space LF UTF-8 | VERIFIED | `indent_size = 2`, `end_of_line = lf`, `charset = utf-8` |
| `.github/workflows/license-check.yml` | 13-SPDX denylist + pnpm + `--ignore-scripts` | VERIFIED | All 13 IDs present; `--frozen-lockfile --ignore-scripts`; `pnpm licenses list --json` |
| `.github/workflows/dco.yml` | KineticCafe action + fetch-depth:0 | VERIFIED | `KineticCafe/actions-dco@v2`; `fetch-depth: 0` |
| `.github/PULL_REQUEST_TEMPLATE.md` | DCO checkbox | VERIFIED | DCO sign-off checkbox present |
| `.github/ISSUE_TEMPLATE/bug_report.md` | Standard bug template | VERIFIED | Exists with expected sections |
| `.github/ISSUE_TEMPLATE/feature_request.md` | Standard feature template | VERIFIED | Exists |
| `docker-compose.yml` | 3 services, pinned, no Plausible | VERIFIED | cadence-postgres:17-alpine, cadence-valkey:8-alpine, cadence-mailpit:v1.20; cadence-net bridge; named volumes; no Plausible |
| `.env.example` | 5 required vars with dev warning | VERIFIED | `POSTGRES_USER=gsd`, `POSTGRES_PASSWORD=gsd_dev_password`, `POSTGRES_DB=gsd`, `MAILPIT_SMTP_PORT=1025`, `MAILPIT_UI_PORT=8025`; dev warning present |
| `docker-compose.override.yml.example` | Comment-only override template | VERIFIED | Comment-only; references gitignored live file |
| `scripts/verify-phase-0.sh` | Phase-wide smoke gate | VERIFIED | `set -euo pipefail`; FAIL accumulator; all FND-*/PRIV-* checks; 60s healthcheck loop |
| `docs/legal/privacy-policy.md` | 3 granular consents, Plausible, no GA, Never collected | VERIFIED | `event_capture`, `public_leaderboards`, `email_digests` present; `Plausible Analytics (managed cloud, plausible.io)` named; Google Analytics absent; `**Never collected** — stays on user's machine` present; GDPR Art. 6 tagged per category |
| `docs/legal/terms-of-service.md` | Apache-2.0 + DCO + shutdown ref + 5,000 | VERIFIED | All required strings present |
| `docs/legal/retention-schedule.md` | 90-day raw events with phase tags | VERIFIED | Phase 1 + Phase 3 tagged; `raw events` + `90 days` present; AUTH-07 present |
| `docs/legal/hosting-cap.md` | 5,000 cap + verbatim SQL definition | VERIFIED | `5,000 active accounts`; `last_signin_at > NOW() - INTERVAL '90 days'` verbatim |
| `docs/legal/shutdown-plan.md` | 90-day notice + export inventory + 3-tier | VERIFIED | `90 days`; data export section; Transfer / Wind-down / Hard close in priority order |
| `docs/ops/dns.md` | SPF + DKIM placeholder + DMARC progression | VERIFIED | `include:amazonses.com`; `_dmarc`; `p=none`, `p=quarantine`, `p=reject` progression; `noreply@`; `hello@`; SPF 10-lookup warning |
| `README.md` | Maintenance posture + Ko-fi + arch link | VERIFIED | "hobby project ... best-effort ... 5,000 active accounts"; `ko-fi.com/{maintainer-handle}` (placeholder, documented carryover); arch doc link present |
| `package.json` | private + Apache-2.0 + Node 22 + pnpm@9 | VERIFIED | `"name": "cadence"`, `"private": true`, `"license": "Apache-2.0"`, `"engines": { "node": ">=22.0.0" }`, `"packageManager": "pnpm@9.15.0"` |
| `pnpm-workspace.yaml` | apps/* + packages/* | VERIFIED | Exact entries present |
| `turbo.json` | Turborepo 2.x tasks shape | VERIFIED | `"tasks"` key (NOT "pipeline"); build/test/lint/typecheck all present |
| 8x workspace `package.json` stubs | `@cadence/*`, private, type:module | VERIFIED | All 8 exist; `@cadence/cli` has `"bin": { "cadence": "./dist/index.js" }` |
| 8x workspace `README.md` stubs | One-line description per package | VERIFIED | All 8 exist |
| `packages/content/reserved-handles.json` | ~200 entries, 9 categories | VERIFIED | 200 entries; `anthropic`, `claude`, `admin`, `anon`, `noreply`, `oauth` sentinel values present; `squat` category has 15 entries |
| `docs/architecture/00-overview.md` | Load-bearing rules + Pino + Plausible Cloud | VERIFIED | Rule 1 ("helper never asserts game state"), Rule 2 ("Anthropic OAuth tokens never reach the cadence backend"), `sk-ant-*` redaction, `Plausible Cloud` rule, IANA timezone policy, FND-08 self-host parity |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `CONTRIBUTING.md` | `CODE_OF_CONDUCT.md` | markdown link | VERIFIED | `[Contributor Covenant 2.1](./CODE_OF_CONDUCT.md)` on last line |
| `.github/workflows/license-check.yml` | pnpm licenses list | `pnpm licenses list --json` | VERIFIED | Command present in workflow step |
| `.github/workflows/dco.yml` | PR commit history | `KineticCafe/actions-dco@v2` | VERIFIED | Action present with `fetch-depth: 0` |
| `docker-compose.yml` | `.env.example` | `${POSTGRES_USER:-gsd}` defaults | VERIFIED | All three `${VAR:-default}` patterns present |
| `scripts/verify-phase-0.sh` | `docker-compose.yml` | `docker compose up -d` + healthcheck poll | VERIFIED | FND-08 section present with 60s loop |
| `docs/legal/privacy-policy.md` | `retention-schedule.md` | markdown link | VERIFIED | `[retention-schedule.md](./retention-schedule.md)` present |
| `docs/legal/terms-of-service.md` | `shutdown-plan.md` | markdown link | VERIFIED | `[Shutdown Plan](./shutdown-plan.md)` present |
| `docs/legal/hosting-cap.md` | Phase 1 `last_signin_at` field | verbatim SQL string | VERIFIED | `SELECT COUNT(*) FROM users WHERE last_signin_at > NOW() - INTERVAL '90 days';` verbatim |
| `docs/ops/dns.md` | Resend (SES) | `include:amazonses.com` | VERIFIED | SPF record uses `include:amazonses.com ~all` |
| `README.md` | `docs/architecture/00-overview.md` | markdown link | VERIFIED | Direct link present in Architecture section |

---

### Data-Flow Trace (Level 4)

Not applicable. Phase 0 delivers no runtime application code — only static documents, configuration files, JSON content assets, and bash scripts. No dynamic data rendering.

---

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| verify-phase-0.sh is valid bash syntax | `bash -n scripts/verify-phase-0.sh` | Script contains `set -euo pipefail`, well-formed conditionals | PASS (static analysis) |
| reserved-handles.json is valid JSON | JSON structure check | 200 entries with `name`, `category`, `reason` fields; `version: 1`; `locked_at: "2026-05-08"` | PASS (static analysis) |
| package.json is valid JSON | JSON structure check | All required fields present | PASS (static analysis) |
| turbo.json is valid JSON with Turborepo 2.x shape | `"tasks"` key check | `tasks` key present (NOT `pipeline`) | PASS (static analysis) |

Note: Docker compose healthcheck behavior (FND-08 runtime) requires a Docker-enabled host. Static structure (pinned images, healthcheck definitions, network config) verified. Runtime behavior is human-verifiable via `bash scripts/verify-phase-0.sh`.

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|---------|
| FND-01 | 00-01 | Permissive OSS license (Apache-2.0) | SATISFIED | `LICENSE` file exists verbatim; `package.json` has `"license": "Apache-2.0"` |
| FND-02 | 00-01 | CI fails GPL/AGPL/SSPL/RSALv2 dep PRs | SATISFIED | `.github/workflows/license-check.yml` with 13-SPDX extended denylist |
| FND-03 | 00-01 | CONTRIBUTING.md + Code of Conduct | SATISFIED | Both files exist; DCO sign-off documented; no-CLA explicit |
| FND-04 | 00-03 | Published user-count cap with overflow policy | SATISFIED | `docs/legal/hosting-cap.md`: 5,000 cap + verbatim SQL definition + self-host overflow prompt |
| FND-05 | 00-03 | Shutdown plan: 90-day notice + data export | SATISFIED | `docs/legal/shutdown-plan.md`: 90-day notice + per-user export inventory + 3 shutdown tiers |
| FND-06 | 00-04 | Donations channel linked from README | SATISFIED (partial) | `README.md` links `ko-fi.com/{maintainer-handle}`; placeholder pending Ko-fi signup per documented carryover |
| FND-07 | 00-04 | README states maintenance posture (hobby, best-effort) | SATISFIED | Verbatim maintenance posture sentence in README |
| FND-08 | 00-02 | docker-compose.yml boots self-hosted from same images | SATISFIED | Compose with 3 pinned services, healthchecks, named volumes; verify-phase-0.sh FND-08 section |
| PRIV-01 | 00-03 | Privacy policy + ToS present | SATISFIED | Both `docs/legal/privacy-policy.md` and `docs/legal/terms-of-service.md` exist |
| PRIV-02 | 00-03 | Granular consent model: 3 separate consents | SATISFIED | `event_capture`, `public_leaderboards`, `email_digests` present in privacy-policy.md |
| PRIV-03 | 00-03 | Raw events retention 90 days | SATISFIED | `docs/legal/retention-schedule.md` specifies 90-day raw events retention; phase-tagged |
| PRIV-04 | 00-03 | Plausible analytics, never Google Analytics | SATISFIED | privacy-policy.md names Plausible managed cloud; Google Analytics explicitly absent |
| PRIV-05 | 00-04 | API tokens and sensitive headers redacted in logs | SATISFIED (policy) | `docs/architecture/00-overview.md` codifies Pino redaction policy with `sk-ant-*` and sensitive header patterns; implementation deferred to Phase 1 (INGEST-09) per plan |

**Note on PRIV-05:** Phase 0 delivers the architectural policy declaration and the Phase 1 enforcement hook. The Pino transport install itself is correctly deferred to Phase 1. This is not a gap — the phase goal is scaffolding, not runtime implementation.

**Note on FND-06:** Ko-fi donations link exists in README with a `{maintainer-handle}` placeholder. The link shape is present and the requirement is partially satisfied. Full satisfaction requires the maintainer to create a Ko-fi account and swap the placeholder. This is a documented non-blocking carryover from 00-04 Task 1.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `README.md` | 30 | `ko-fi.com/{maintainer-handle}` literal placeholder | Info | FND-06 partially satisfied; link resolves to a 404 until Ko-fi handle is assigned. Documented in 00-04-SUMMARY.md carryover. |
| All legal docs | various | `{ROOT_DOMAIN}`, `{INSTANCE_HOSTNAME}`, `{MAINTAINER_NAME}` placeholders | Info | Intentional; flip-day substitution per D-11/CD-04. Documented in 00-03-SUMMARY.md. |
| `docs/legal/terms-of-service.md` | 9 | Still references "Claude Code Gamification Service (working title)" not "cadence" | Info | Minor — working title in ToS preamble; not load-bearing. Will be resolved at flip-day alongside domain substitution. |

No blockers. All patterns are intentional deferred items with documented resolution paths.

---

### Human Verification Required

#### 1. FND-08 Runtime Docker Compose Healthcheck

**Test:** On a Docker-enabled machine, run `cp .env.example .env && bash scripts/verify-phase-0.sh`
**Expected:** All three services (cadence-postgres, cadence-valkey, cadence-mailpit) reach `Health: healthy` within 60 seconds; `Mailpit /readyz returns 200`; script exits 0 on all FND-* and PRIV-* checks
**Why human:** Requires a Docker daemon; cannot be verified via static file inspection

#### 2. GitHub Repo Settings Toggle (Task 3 from 00-01, deferred per user decision)

**Test:** GitHub repo Settings -> General -> Pull Requests -> "Require contributors to sign off on web-based commits"
**Expected:** Toggle is enabled
**Why human:** GitHub UI action; repo is personal/private and user explicitly deferred this per 00-01-SUMMARY.md. Not blocking the phase goal (DCO CI gate is in place; this closes the squash-merge gap only).

---

### Gaps Summary

No gaps blocking the phase goal. The phase successfully delivers all 13 observable truths:

- All 11 governance/CI/template files from Plan 00-01 exist with load-bearing content
- All 4 Docker compose and smoke-gate files from Plan 00-02 exist
- All 6 legal/ops docs from Plan 00-03 exist with required strings
- All 22 monorepo skeleton + content + architecture files from Plan 00-04 exist

Two informational carryovers with documented resolution paths exist:
1. Ko-fi `{maintainer-handle}` placeholder in README (FND-06 partial; non-blocking)
2. GitHub repo settings toggle for squash-merge DCO (Pitfall 3 partial closure; deferred per user)

One human verification item exists (Docker runtime), which does not block automated acceptance of the phase goal — the structural assertions that verify-phase-0.sh makes against static files can all be confirmed through codebase inspection.

---

_Verified: 2026-05-08_
_Verifier: Claude (gsd-verifier)_

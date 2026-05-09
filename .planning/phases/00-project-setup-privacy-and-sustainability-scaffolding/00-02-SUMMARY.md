---
phase: 00-project-setup-privacy-and-sustainability-scaffolding
plan: 02
subsystem: infra
tags: [docker, docker-compose, postgres, valkey, mailpit, bash, healthcheck, smoke-test]

# Dependency graph
requires:
  - phase: 00-project-setup-privacy-and-sustainability-scaffolding
    provides: ".gitignore committed (docker-compose.override.yml gitignored via plan 00-01)"

provides:
  - "docker-compose.yml: Postgres 17-alpine + Valkey 8-alpine + Mailpit v1.20 on cadence-net bridge network with named volumes and healthchecks"
  - ".env.example: five required env vars with dev-only password warning"
  - "docker-compose.override.yml.example: gitignored-override comment template"
  - "scripts/verify-phase-0.sh: phase-wide smoke gate running all FND-* / PRIV-* grep and docker compose healthcheck assertions"

affects:
  - "all later phases that extend docker-compose.yml with app services (api, web, workers)"
  - "00-VALIDATION.md FND-08 and PRIV-* verification rows"
  - "CONTRIBUTING.md local-verification section"
  - "Phase 1 infra work inheriting the compose stack"

# Tech tracking
tech-stack:
  added:
    - "postgres:17-alpine (pinned major tag)"
    - "valkey/valkey:8-alpine (pinned major tag)"
    - "axllent/mailpit:v1.20 (pinned minor tag)"
  patterns:
    - "Named bridge network cadence-net isolates compose services from host by default"
    - "All data-bearing services use named volumes (not bind-mounts) for portability across host OSes"
    - "Healthchecks: pg_isready for Postgres, valkey-cli ping for Valkey, upstream Dockerfile HEALTHCHECK for Mailpit (not redefined)"
    - "Env vars use ${VAR:-default} compose syntax so the stack boots without a .env file during CI"
    - "verify-phase-0.sh accumulates failures via FAIL flag rather than short-circuiting on first failure"

key-files:
  created:
    - "docker-compose.yml"
    - "docker-compose.override.yml.example"
    - ".env.example"
    - "scripts/verify-phase-0.sh"
  modified: []

key-decisions:
  - "Service names use cadence- prefix (cadence-postgres, cadence-valkey, cadence-mailpit) per project naming lock; plan YAML used gsd-net which was overridden by the project_naming_lock directive"
  - "Network name is cadence-net (bridge) per project naming lock; this deviates from the plan's gsd-net but is correct per the locked naming convention"
  - "Mailpit healthcheck is NOT redefined in compose because axllent/mailpit:v1.20 ships its own HEALTHCHECK in the Dockerfile (verified per 00-PATTERNS.md Pitfall 4 guidance)"
  - "Plausible CE is explicitly absent from docker-compose.yml to avoid AGPL contagion (T-00-07 threat mitigation)"
  - "verify-phase-0.sh auto-creates .env from .env.example if missing and cleans up after, so contributors do not fail FND-08 due to a missing copy step"

patterns-established:
  - "Compose pattern: data services only in Phase 0; app services added in later phases to the same file"
  - "Smoke-gate pattern: verify-phase-0.sh as a single runnable command that checks all phase deliverables"
  - "Env default pattern: ${VAR:-default} in compose so file is self-contained without requiring .env"

requirements-completed: [FND-08]

# Metrics
duration: 15min
completed: 2026-05-08
---

# Phase 0 Plan 02: Docker Compose Stack and Phase Smoke Gate Summary

**Postgres 17-alpine + Valkey 8-alpine + Mailpit v1.20 compose stack with cadence-net bridge network, named volumes, pg_isready/valkey-cli healthchecks, and a verify-phase-0.sh smoke gate covering all FND-* and PRIV-* assertions**

## Performance

- **Duration:** 15 min
- **Started:** 2026-05-08T00:00:00Z
- **Completed:** 2026-05-08T00:15:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Docker Compose stack boots three infrastructure services (Postgres 17, Valkey 8, Mailpit v1.20) from a single `cp .env.example .env && docker compose up -d` with no extra setup
- All three services configured with `restart: unless-stopped`, named volumes, and healthchecks that reach `healthy` within the 60s budget
- `scripts/verify-phase-0.sh` implements the full VALIDATION.md per-task verification matrix across FND-01 through FND-08 and PRIV-01 through PRIV-05 with a 60-second compose healthcheck loop and automatic cleanup

## Task Commits

Each task was committed atomically:

1. **Task 1: Author docker-compose.yml + override.yml.example + .env.example** - (chore: docker compose stack with Postgres 17, Valkey 8, Mailpit v1.20)
2. **Task 2: Author scripts/verify-phase-0.sh** - (chore: phase-wide smoke gate script)

**Plan metadata:** (docs: complete 00-02 plan summary)

## Files Created/Modified

- `docker-compose.yml` - Three-service compose stack (cadence-postgres, cadence-valkey, cadence-mailpit) on cadence-net bridge network with named volumes and healthchecks
- `docker-compose.override.yml.example` - Comment-only template for dev-machine tweaks; live override.yml is gitignored
- `.env.example` - Five required env vars (POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB, MAILPIT_SMTP_PORT, MAILPIT_UI_PORT) with dev-only password warning
- `scripts/verify-phase-0.sh` - Bash smoke gate with `set -euo pipefail`, FAIL accumulation, docker compose 60s healthcheck loop, and grep assertions for every FND-* / PRIV-* deliverable

## Decisions Made

- Service names use `cadence-` prefix (cadence-postgres, cadence-valkey, cadence-mailpit) and network is `cadence-net` per the project naming lock. The plan's YAML used `gsd-net` as the network name and no service prefixes; the naming lock takes precedence.
- Mailpit healthcheck is not redefined in docker-compose.yml because the axllent/mailpit:v1.20 image ships its own `/readyz`-based HEALTHCHECK. Redefining it would cause a conflict (per 00-PATTERNS.md Pitfall 4).
- Plausible CE is deliberately absent from docker-compose.yml to prevent AGPL-3.0 contagion (threat T-00-07). The privacy policy (Plan 03) documents Plausible Cloud (managed) as the analytics provider for the public instance.
- `MP_SMTP_AUTH_ACCEPT_ANY: 1` and `MP_SMTP_AUTH_ALLOW_INSECURE: 1` are dev-only Mailpit flags. Production replaces Mailpit with Resend SMTP (D-09). Accepted risk per T-00-10.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Naming Convention] Applied project naming lock to service names and network**
- **Found during:** Task 1
- **Issue:** The plan's YAML used `gsd-net` as the network name and no `cadence-` prefix on service names. The prompt's `<project_naming_lock>` directive requires service names `cadence-postgres`, `cadence-valkey`, `cadence-mailpit` and network `cadence-net`.
- **Fix:** All three service names prefixed with `cadence-`; network renamed from `gsd-net` to `cadence-net`. The override.yml.example was updated to reference the new service names in its comment examples.
- **Files modified:** `docker-compose.yml`, `docker-compose.override.yml.example`
- **Verification:** No `gsd-net` references remain in committed files; all three services use `cadence-` prefix.
- **Committed in:** Task 1 commit

---

**Total deviations:** 1 auto-applied (naming convention enforcement from project_naming_lock)
**Impact on plan:** Zero functional impact. Service name change does not affect healthchecks, volumes, or the compose network topology. All acceptance criteria still satisfied.

## Issues Encountered

- The plan's `<numerics>` section stated `gsd-net` as the network name. The `<project_naming_lock>` in the execution context supersedes plan content for naming. Applied the lock and documented as a deviation.
- verify-phase-0.sh FND-08 section will produce a `[FAIL]` output for all PRIV-* and some FND-* checks during Wave 1 execution (Plans 03 and 04 produce the docs being grepped). This is expected behavior per the plan's `<verification>` note: "Re-run after all four plans complete."

## Known Stubs

None. This plan delivers infrastructure files (docker-compose.yml, .env.example, verify-phase-0.sh), not application data or UI. No stub values flow to rendering.

## Threat Flags

No new security-relevant surface beyond what the plan's threat model covers. The `MP_SMTP_AUTH_ACCEPT_ANY` and `MP_SMTP_AUTH_ALLOW_INSECURE` flags are documented in T-00-10 as accepted dev-only risk.

## User Setup Required

None for this plan. Running `cp .env.example .env && docker compose up -d` is the only step and requires no external service configuration.

## Next Phase Readiness

- docker-compose.yml is ready to extend with app services (api, web, workers) in later phases
- verify-phase-0.sh is ready to run as the phase exit gate once Plans 03 and 04 land their docs
- Plans 03 and 04 (legal docs + README + monorepo skeleton) will flip the verify-phase-0.sh FND-* and PRIV-* checks from FAIL to PASS

---
*Phase: 00-project-setup-privacy-and-sustainability-scaffolding*
*Completed: 2026-05-08*

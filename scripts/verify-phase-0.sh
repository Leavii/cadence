#!/usr/bin/env bash
# scripts/verify-phase-0.sh
# Phase 0 smoke gate -- runs grep + healthcheck assertions for every FND-* / PRIV-* deliverable.
# Exit 0 = phase deliverables structurally correct.
# Exit 1 = at least one assertion failed (the failing line is printed).
#
# Referenced by: CONTRIBUTING.md (contributors run before pushing) and /gsd-verify-work.
# Source: derived from 00-VALIDATION.md per-task verification matrix and 00-RESEARCH.md lines 1106-1124.

set -euo pipefail

FAIL=0
log_pass() { printf "  [PASS] %s\n" "$1"; }
log_fail() { printf "  [FAIL] %s\n" "$1"; FAIL=1; }
section()  { printf "\n=== %s ===\n" "$1"; }

# ---------------------------------------------------------------------------
# FND-01: Apache-2.0 LICENSE present and verbatim
# ---------------------------------------------------------------------------
section "FND-01 License"
[ -f LICENSE ] && grep -q "Apache License" LICENSE && grep -q "Version 2.0" LICENSE \
  && log_pass "LICENSE is Apache-2.0 verbatim" \
  || log_fail "LICENSE missing or not Apache-2.0"

# ---------------------------------------------------------------------------
# FND-03: CONTRIBUTING.md + CODE_OF_CONDUCT.md present and load-bearing
# ---------------------------------------------------------------------------
section "FND-03 Contributing + Code of Conduct"
[ -f CONTRIBUTING.md ] && grep -q "Signed-off-by" CONTRIBUTING.md \
  && log_pass "CONTRIBUTING.md exists with DCO sign-off" \
  || log_fail "CONTRIBUTING.md missing or no Signed-off-by reference"
[ -f CODE_OF_CONDUCT.md ] && grep -q "Contributor Covenant" CODE_OF_CONDUCT.md \
  && log_pass "CODE_OF_CONDUCT.md is Contributor Covenant" \
  || log_fail "CODE_OF_CONDUCT.md missing or wrong template"

# ---------------------------------------------------------------------------
# FND-02 (CI): license-check + DCO workflows present
# ---------------------------------------------------------------------------
section "FND-02 CI workflows"
[ -f .github/workflows/license-check.yml ] && grep -q "AGPL-3.0" .github/workflows/license-check.yml \
  && log_pass "license-check workflow exists with AGPL-3.0 in denylist" \
  || log_fail "license-check workflow missing or denylist incomplete"
[ -f .github/workflows/dco.yml ] && grep -q "actions-dco" .github/workflows/dco.yml \
  && log_pass "DCO workflow exists" \
  || log_fail "DCO workflow missing"

# ---------------------------------------------------------------------------
# FND-04: hosting-cap.md (5,000 active accounts; 90-day definition)
# ---------------------------------------------------------------------------
section "FND-04 Hosting cap"
if [ -f docs/legal/hosting-cap.md ]; then
  grep -Eq "5,?000" docs/legal/hosting-cap.md \
    && log_pass "hosting-cap.md mentions 5,000 cap" \
    || log_fail "hosting-cap.md missing 5,000 cap"
  grep -q "90 days" docs/legal/hosting-cap.md \
    && log_pass "hosting-cap.md mentions 90-day active definition" \
    || log_fail "hosting-cap.md missing 90-day active definition"
  grep -q "last_signin_at" docs/legal/hosting-cap.md \
    && log_pass "hosting-cap.md cites SQL definition (last_signin_at)" \
    || log_fail "hosting-cap.md missing SQL definition (Pitfall 8)"
else
  log_fail "docs/legal/hosting-cap.md missing"
fi

# ---------------------------------------------------------------------------
# FND-05: shutdown-plan.md (90-day notice + data export)
# ---------------------------------------------------------------------------
section "FND-05 Shutdown plan"
if [ -f docs/legal/shutdown-plan.md ]; then
  grep -q "90 days\|90-day" docs/legal/shutdown-plan.md \
    && log_pass "shutdown-plan.md mentions 90-day notice" \
    || log_fail "shutdown-plan.md missing 90-day notice"
  grep -iq "data export" docs/legal/shutdown-plan.md \
    && log_pass "shutdown-plan.md mentions data export" \
    || log_fail "shutdown-plan.md missing data export commitment"
else
  log_fail "docs/legal/shutdown-plan.md missing"
fi

# ---------------------------------------------------------------------------
# FND-06: README links donations channel
# ---------------------------------------------------------------------------
section "FND-06 Donations link in README"
if [ -f README.md ]; then
  grep -Eq "ko-fi\.com|opencollective\.com" README.md \
    && log_pass "README links Ko-fi or OpenCollective" \
    || log_fail "README missing donations link"
else
  log_fail "README.md missing"
fi

# ---------------------------------------------------------------------------
# FND-07: README states maintenance posture
# ---------------------------------------------------------------------------
section "FND-07 Maintenance posture"
if [ -f README.md ]; then
  grep -Eiq "best-effort|hobby project" README.md \
    && log_pass "README states maintenance posture" \
    || log_fail "README missing 'best-effort' / 'hobby project' wording"
else
  log_fail "README.md missing"
fi

# ---------------------------------------------------------------------------
# PRIV-01: privacy-policy.md + terms-of-service.md present
# ---------------------------------------------------------------------------
section "PRIV-01 Privacy policy + ToS"
[ -f docs/legal/privacy-policy.md ] \
  && log_pass "docs/legal/privacy-policy.md exists" \
  || log_fail "docs/legal/privacy-policy.md missing"
[ -f docs/legal/terms-of-service.md ] \
  && log_pass "docs/legal/terms-of-service.md exists" \
  || log_fail "docs/legal/terms-of-service.md missing"

# ---------------------------------------------------------------------------
# PRIV-02: Granular consent model (3 separate consents)
# ---------------------------------------------------------------------------
section "PRIV-02 Granular consent model"
if [ -f docs/legal/privacy-policy.md ]; then
  for kind in event_capture public_leaderboards email_digests; do
    grep -q "$kind" docs/legal/privacy-policy.md \
      && log_pass "privacy-policy.md names consent: $kind" \
      || log_fail "privacy-policy.md missing consent: $kind"
  done
else
  log_fail "privacy-policy.md missing -- cannot verify consents"
fi

# ---------------------------------------------------------------------------
# PRIV-03: retention-schedule.md (90-day raw events)
# ---------------------------------------------------------------------------
section "PRIV-03 Retention schedule"
if [ -f docs/legal/retention-schedule.md ]; then
  grep -q "90 days" docs/legal/retention-schedule.md \
    && log_pass "retention-schedule.md mentions 90 days" \
    || log_fail "retention-schedule.md missing 90-day retention"
  grep -iq "raw events" docs/legal/retention-schedule.md \
    && log_pass "retention-schedule.md names raw events" \
    || log_fail "retention-schedule.md missing 'raw events' tag"
else
  log_fail "docs/legal/retention-schedule.md missing"
fi

# ---------------------------------------------------------------------------
# PRIV-04: Plausible (NOT Google Analytics)
# ---------------------------------------------------------------------------
section "PRIV-04 Analytics provider"
if [ -f docs/legal/privacy-policy.md ]; then
  grep -iq "plausible" docs/legal/privacy-policy.md \
    && log_pass "privacy-policy.md names Plausible" \
    || log_fail "privacy-policy.md missing Plausible reference"
  if grep -iq "google analytics" docs/legal/privacy-policy.md; then
    log_fail "privacy-policy.md references Google Analytics (PRIV-04 violation)"
  else
    log_pass "privacy-policy.md does NOT reference Google Analytics"
  fi
fi

# ---------------------------------------------------------------------------
# PRIV-05: Architecture doc codifies redaction rule
# ---------------------------------------------------------------------------
section "PRIV-05 Redaction policy"
if [ -f docs/architecture/00-overview.md ]; then
  grep -iq "redact" docs/architecture/00-overview.md \
    && log_pass "architecture overview mentions redaction" \
    || log_fail "architecture overview missing redaction rule"
  grep -iq "token" docs/architecture/00-overview.md \
    && log_pass "architecture overview mentions token redaction" \
    || log_fail "architecture overview missing token reference"
else
  log_fail "docs/architecture/00-overview.md missing"
fi

# ---------------------------------------------------------------------------
# FND-08: docker compose up boots cleanly
# ---------------------------------------------------------------------------
section "FND-08 docker compose parity"
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  if [ ! -f .env ] && [ -f .env.example ]; then
    cp .env.example .env
    CREATED_ENV=1
  else
    CREATED_ENV=0
  fi
  if docker compose up -d >/dev/null 2>&1; then
    HEALTHY=0
    for i in $(seq 1 60); do
      # Count services that are healthy. Three services in compose; require all three.
      COUNT=$(docker compose ps --format json 2>/dev/null \
        | (jq -s '.' 2>/dev/null || echo "[]") \
        | jq -r '[.[] | select(.Health == "healthy")] | length' 2>/dev/null || echo 0)
      if [ "${COUNT:-0}" -ge 3 ]; then
        HEALTHY=1
        break
      fi
      sleep 1
    done
    if [ "$HEALTHY" = "1" ]; then
      log_pass "All 3 compose services healthy within 60s"
      if curl -fsS http://localhost:8025/readyz >/dev/null 2>&1; then
        log_pass "Mailpit /readyz returns 200"
      else
        log_fail "Mailpit /readyz unreachable on port 8025"
      fi
    else
      log_fail "Compose services did not all reach healthy in 60s"
      docker compose ps || true
    fi
    docker compose down >/dev/null 2>&1 || true
  else
    log_fail "docker compose up -d failed"
  fi
  if [ "$CREATED_ENV" = "1" ]; then
    rm -f .env
  fi
else
  log_fail "Docker not available -- cannot run FND-08 healthcheck (run on a Docker-enabled host)"
fi

section "Summary"
if [ "$FAIL" = "0" ]; then
  printf "All Phase 0 checks passed.\n"
  exit 0
else
  printf "At least one Phase 0 check failed -- see [FAIL] lines above.\n"
  exit 1
fi

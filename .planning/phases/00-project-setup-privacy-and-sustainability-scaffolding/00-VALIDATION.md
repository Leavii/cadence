---
phase: 0
slug: project-setup-privacy-and-sustainability-scaffolding
status: planned
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-08
updated: 2026-05-08
---

# Phase 0 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `00-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | GitHub Actions workflows + shell-based assertions (Phase 0 ships no app code; Vitest lands in Phase 1, Playwright in Phase 2) |
| **Config file** | `.github/workflows/license-check.yml`, `.github/workflows/dco.yml`, `scripts/verify-phase-0.sh` |
| **Quick run command** | `pnpm licenses:check` (license workflow's core command — local equivalent of CI license-check) |
| **Full suite command** | `bash scripts/verify-phase-0.sh` (runs grep-based doc-existence checks for every FND-* / PRIV-* + 60s `docker compose up` healthcheck loop + tears down) |
| **Estimated runtime** | ~75 seconds (60s compose health window + ~15s grep + teardown) |

---

## Sampling Rate

- **After every task commit:** Run `pnpm licenses:check` if any deps changed; otherwise the task's own `<verify>` block (already grep-based) is the feedback signal
- **After every plan wave:** Run `bash scripts/verify-phase-0.sh` (full smoke gate)
- **Before `/gsd-verify-work`:** Full `verify-phase-0.sh` must exit 0; both CI workflows must be green on a fresh PR
- **Max feedback latency:** ~75 seconds

---

## Per-Task Verification Map

> One row per task across the four PLAN.md files. The full `<automated>` command lives in each plan's `<verify>` block; this matrix is the index. `Status` is the live phase-execution state (set during execute-phase, not at planning time).

| Task ID | Plan | Wave | Type | Requirement | Threat Ref | Verifies | Test Type | Automated Command (summary; full body in plan) | Status |
|---------|------|------|------|-------------|------------|----------|-----------|------------------------------------------------|--------|
| 00-01-01 | 00-01 | 1 | auto | FND-01, FND-03 | T-supply-chain-license, T-contributor-provenance | LICENSE / CoC / CONTRIBUTING / SECURITY / .gitignore / .editorconfig present + canonical content | smoke (grep) | `[ -f LICENSE ] && grep -q "Apache License" LICENSE && grep -q "Version 2.0" LICENSE && [ -f CODE_OF_CONDUCT.md ] && grep -q "Contributor Covenant" CODE_OF_CONDUCT.md && [ -f CONTRIBUTING.md ] && grep -q "Signed-off-by" CONTRIBUTING.md && [ -f SECURITY.md ] && [ -f .gitignore ] && [ -f .editorconfig ]` | ⬜ pending |
| 00-01-02 | 00-01 | 1 | auto | FND-02, FND-03 | T-supply-chain-license, T-contributor-provenance | license-check + DCO workflows installed; denylist contains all 13 SPDX IDs (GPL/AGPL/SSPL/RSALv2 + BUSL-1.1/ELv2/Confluent-Community-1.0/MariaDB-BSL-1.1) | integration (workflow syntax + denylist regex) | `[ -f .github/workflows/license-check.yml ] && [ -f .github/workflows/dco.yml ] && grep -q "AGPL" .github/workflows/license-check.yml && grep -q "actions-dco" .github/workflows/dco.yml` | ⬜ pending |
| 00-01-03 | 00-01 | 1 | checkpoint:human-action (blocking) | FND-03 | T-contributor-provenance (squash-merge DCO bypass) | GitHub repo "Require sign-off on web-based commits" toggle ON | manual (GitHub repo settings dashboard) | n/a — human verifies in dashboard | ⬜ pending |
| 00-02-01 | 00-02 | 1 | auto | FND-08 | T-agpl-contagion (no Plausible CE), secrets-in-git | docker-compose.yml + .env.example + override.yml.example present; pinned image tags (Postgres 17-alpine, Valkey 8-alpine, Mailpit v1.20); compose syntax valid | smoke + integration | `[ -f docker-compose.yml ] && [ -f .env.example ] && docker compose config --quiet && grep -q "postgres:17" docker-compose.yml && grep -q "valkey/valkey:8" docker-compose.yml && grep -q "axllent/mailpit" docker-compose.yml` | ⬜ pending |
| 00-02-02 | 00-02 | 1 | auto | FND-08 | (full-phase smoke) | scripts/verify-phase-0.sh exists, executable, exits 0 on a populated phase tree | integration (60s compose healthcheck loop + grep matrix) | `[ -x scripts/verify-phase-0.sh ] && bash scripts/verify-phase-0.sh` (NOTE: this is the phase-exit gate; expected to FAIL during Wave 1 and PASS only after all 4 plans land) | ⬜ pending |
| 00-03-01 | 00-03 | 1 | checkpoint:human-verify (blocking) | PRIV-01 | T-policy-drift, international-transfer | Maintainer answers EU-resident yes/no; Task 2 receives the right template variant | manual (planning-time gate) | n/a — human answers; gates Task 2 | ⬜ pending |
| 00-03-02 | 00-03 | 1 | auto | PRIV-01, PRIV-02, PRIV-03, PRIV-04 | T-policy-drift, T-oauth-leak (declaration) | privacy-policy / terms-of-service / retention-schedule present with: 3 granular consents (event_capture / public_leaderboards / email_digests), Plausible named (no GA), 90-day raw events retention, Anthropic-OAuth-never-collected line | smoke (grep) | `[ -f docs/legal/privacy-policy.md ] && [ -f docs/legal/terms-of-service.md ] && [ -f docs/legal/retention-schedule.md ] && grep -q event_capture docs/legal/privacy-policy.md && grep -q public_leaderboards docs/legal/privacy-policy.md && grep -q email_digests docs/legal/privacy-policy.md && grep -q "plausible.io" docs/legal/privacy-policy.md && ! grep -qi "google analytics" docs/legal/privacy-policy.md && grep -q "90 days" docs/legal/retention-schedule.md` | ⬜ pending |
| 00-03-03 | 00-03 | 1 | auto | FND-04, FND-05, PRIV-04 | T-shutdown-no-export, T-email-spoof | hosting-cap (5,000 active per D-06 + 90-day signin definition) + shutdown-plan (90-day notice + per-user data export) + dns (SPF include:amazonses.com, DKIM TXT placeholder, DMARC p=none progression) | smoke (grep) | `[ -f docs/legal/hosting-cap.md ] && [ -f docs/legal/shutdown-plan.md ] && [ -f docs/ops/dns.md ] && grep -q "5,000" docs/legal/hosting-cap.md && grep -q "90 days" docs/legal/shutdown-plan.md && grep -q "data export" docs/legal/shutdown-plan.md && grep -q "amazonses.com" docs/ops/dns.md && grep -q "_dmarc" docs/ops/dns.md` | ⬜ pending |
| 00-03-04 | 00-03 | 1 | checkpoint:human-action (non-blocking) | FND-04 (domain part of mail config) | T-email-spoof | Maintainer purchases domain via Cloudflare Registrar; dns.md placeholders flipped to live values | manual (registrar dashboard) | n/a — human verifies in dns.md after purchase | ⬜ pending |
| 00-04-01 | 00-04 | 1 | checkpoint:human-action (non-blocking) | FND-06 | T-shutdown-no-export (donations channel), maintainer-burnout | Maintainer creates Ko-fi account; README badge link updated from placeholder | manual (Ko-fi signup) | n/a — Task 2 handles all three response cases (Ko-fi handle / OpenCollective / placeholder) | ⬜ pending |
| 00-04-02 | 00-04 | 1 | auto | FND-06, FND-07 | (donations + maintenance posture) | README states maintenance posture (best-effort / hobby project), links donations, mentions hosting cap; root package.json + pnpm-workspace.yaml + turbo.json valid | smoke (grep) + integration (pnpm parse) | `[ -f README.md ] && grep -q "best-effort" README.md && grep -q "hobby project" README.md && grep -q "5,000" README.md && [ -f package.json ] && [ -f pnpm-workspace.yaml ] && [ -f turbo.json ] && python -c "import json; json.load(open('package.json'))"` | ⬜ pending |
| 00-04-03 | 00-04 | 1 | auto | FND-07 (workspace skeleton scaffolding) | reserved-handle impersonation | 8 workspace stubs (apps/{api,web,cli,workers}/.gitkeep + package.json + README.md; packages/{db,content,shared,ui}/.gitkeep + package.json + README.md); reserved-handles.json count in 180-220 band, 9-category structure | smoke + JSON validation | `for d in apps/api apps/web apps/cli apps/workers packages/db packages/content packages/shared packages/ui; do [ -f $d/package.json ] && [ -f $d/README.md ]; done && [ -f packages/content/reserved-handles.json ] && python -c "import json; d=json.load(open('packages/content/reserved-handles.json')); assert 180 <= len(d) <= 220, len(d)"` | ⬜ pending |
| 00-04-04 | 00-04 | 1 | auto | PRIV-05 | T-oauth-leak, helper-asserts-state, T-agpl-contagion (rule restated) | docs/architecture/00-overview.md exists; codifies "helper never asserts game state", "Anthropic OAuth token never reaches backend", token-redaction rule for Phase 1 logging, no-Plausible-CE-bundle rule | smoke (grep) | `[ -f docs/architecture/00-overview.md ] && grep -qi "helper never asserts" docs/architecture/00-overview.md && grep -qi "Anthropic.*OAuth" docs/architecture/00-overview.md && grep -qi "redact" docs/architecture/00-overview.md && grep -qi "token" docs/architecture/00-overview.md` | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

These artifacts are *created by the phase itself*. Listed so the planner allocates tasks for them and the checker confirms coverage.

- [x] `.github/workflows/license-check.yml` — pnpm licenses denylist (covered by 00-01-02)
- [x] `.github/workflows/dco.yml` — `KineticCafe/actions-dco@v2` (covered by 00-01-02)
- [x] `scripts/verify-phase-0.sh` — grep + healthcheck smoke loop (covered by 00-02-02)
- [x] `CONTRIBUTING.md` documents how to run `verify-phase-0.sh` locally (covered by 00-01-01 + cross-references 00-02-02 output)
- [ ] Three CI fixture PRs to prove the workflows actually function end-to-end:
  - PR adding a known-AGPL package → license-check must FAIL
  - PR with a missing-signoff commit → DCO check must FAIL
  - PR adding a permissive package, signed-off → both must PASS
  *(Not allocated to a Phase 0 task — see "Manual-Only Verifications" below. Tracked as a follow-up at first-PR-after-phase or as a small Phase 1 prequel chore.)*

`wave_0_complete: false` until the three fixture PRs are exercised against the live workflows.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| First-deploy parity on Hetzner CX22 + Coolify (same `docker-compose.yml` boots identically) | FND-08 (parity claim) | Requires a real VM + Coolify install; not reproducible in CI without infra cost | Provision throwaway Hetzner CX22 → install Coolify → point at this repo's `docker-compose.yml` → confirm Postgres / Valkey / Mailpit reach `healthy` in ≤120s. One-time confirmation; documented in `docs/ops/deploy-coolify.md`. (Resolved Open Question 2 in 00-RESEARCH.md.) |
| CI fixture PRs prove license-check + DCO actually block on bad inputs | FND-02, FND-03 | Requires a live PR against the actual repo; cannot be exercised at planning time | After 00-01-02 lands and repo is on GitHub, open three throwaway PRs against a fixture branch: (a) add `agpl-3.0`-licensed test dep → license-check must FAIL; (b) author a commit without `Signed-off-by:` → DCO must FAIL; (c) add a permissive dep + signoff → both PASS. Close all three after verifying. (Plan-checker Warning #4.) |
| Resend domain DKIM/DMARC records propagate after DNS goes live | PRIV-04-related (sender-identity scaffolding); FND-04 mail flow | Requires owning the production domain and waiting for DNS TTL (Phase 0 only commits the *records*, not the live DNS) | At domain-buy time (00-03-04): enter records from `docs/ops/dns.md` into registrar; run `dig TXT _dmarc.{domain}` + `dig TXT {selector}._domainkey.{domain}` after TTL; confirm `mail-tester.com` score ≥ 9/10. |
| Privacy-policy / ToS legal review | PRIV-01, PRIV-02 | Clean-room template; legal review deferred per CD-04 | Defer to visibility-flip / launch (Phase 9). Phase 0 ships the template as committed-good-faith draft. |
| Docker-less CI runner downgrade for `verify-phase-0.sh` | FND-08 verification (Plan-checker Warning #3) | Script `log_fail`s on Docker-unavailable runners, which would create false-red gates on doc-grep-only CI lanes | When wiring `verify-phase-0.sh` into CI, run it only on Docker-enabled jobs OR split the script's docker-block into a separate workflow lane. Document the chosen split in `CONTRIBUTING.md`. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify (auto tasks) or are typed as checkpoints with explicit human-verify steps (4 checkpoint tasks). Verified by plan-checker Dimension 8a.
- [x] Sampling continuity: no 3 consecutive auto tasks without automated verify. Verified by plan-checker Dimension 8c.
- [x] Wave 0 covers all MISSING references (license-check + DCO workflows + verify-phase-0.sh + CONTRIBUTING.md cross-link).
- [x] No watch-mode flags.
- [x] Feedback latency < 90s.
- [x] `nyquist_compliant: true` set in frontmatter.
- [ ] `wave_0_complete: true` — flip after CI fixture PRs exercise the live workflows successfully (post-execute-phase, before `/gsd-verify-work` final sign-off).

**Approval:** plan-checker pass pending re-verification (this rewrite addresses Blocker #2 from the first checker run).

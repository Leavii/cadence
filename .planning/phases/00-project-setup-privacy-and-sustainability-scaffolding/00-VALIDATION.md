---
phase: 0
slug: project-setup-privacy-and-sustainability-scaffolding
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-08
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

- **After every task commit:** Run `pnpm licenses:check` if any deps changed; otherwise the task's own grep-based acceptance is the feedback signal
- **After every plan wave:** Run `bash scripts/verify-phase-0.sh` (full smoke gate)
- **Before `/gsd-verify-work`:** Full `verify-phase-0.sh` must exit 0; both CI workflows must be green on a fresh PR
- **Max feedback latency:** ~75 seconds

---

## Per-Task Verification Map

> Populated by the planner during Step 8. One row per task in any PLAN.md, mapped back to its FND-* / PRIV-* requirement and the grep / curl / shell assertion that proves it.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| _populated by planner_ | | | | | | | | | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

These are the test/CI artifacts the *phase itself* creates (not preconditions). Listed here so the planner allocates tasks for them and the checker can confirm coverage.

- [ ] `.github/workflows/license-check.yml` — pnpm licenses denylist (GPL/AGPL/SSPL/RSALv2 + defensive BUSL-1.1/ELv2/Confluent-Community-1.0/MariaDB-BSL-1.1) → covers FND-02
- [ ] `.github/workflows/dco.yml` — `KineticCafe/actions-dco@v2` (no GitHub-App install, gates PR commits not merge commit) → covers DCO enforcement (D-03)
- [ ] `scripts/verify-phase-0.sh` — grep + healthcheck smoke loop for every FND-* / PRIV- requirement
- [ ] Three fixture PRs (created once workflows are merged; can live as sample diffs in `docs/contributing/ci-fixtures/`):
  - PR adding a known-AGPL package → license-check must FAIL
  - PR with a missing-signoff commit → DCO check must FAIL
  - PR adding a permissive package, signed-off → both must PASS
- [ ] `CONTRIBUTING.md` documents how to run `verify-phase-0.sh` locally before pushing

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| First-deploy parity on Hetzner CX22 + Coolify (same `docker-compose.yml` boots identically) | FND-08 (parity claim) | Requires a real VM + Coolify install; not reproducible in CI without infra cost | Provision throwaway Hetzner CX22 → install Coolify → point at this repo's `docker-compose.yml` → confirm Postgres/Valkey/Mailpit reach `healthy` in ≤120s. One-time confirmation; documented in `docs/ops/deploy-coolify.md`. (Open Question 2 in RESEARCH.md.) |
| Resend domain DKIM/DMARC records propagate after DNS goes live | PRIV-04 (analytics scope) related; sender-identity scaffolding | Requires owning the production domain and waiting for DNS TTL (Phase 0 only commits the *records*, not the live DNS) | At domain-buy time: enter records from `docs/ops/dns.md` into registrar; run `dig TXT _dmarc.{domain}` + `dig TXT {selector}._domainkey.{domain}` after TTL; confirm `mail-tester.com` score ≥ 9/10. |
| Privacy-policy / ToS legal review | PRIV-01, PRIV-02 | Clean-room template; legal review deferred per CD-04 | Defer to visibility-flip / launch (Phase 9). Phase 0 ships the template as committed-good-faith draft. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies (filled by planner)
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify (checker confirms)
- [ ] Wave 0 covers all MISSING references (CI workflows + verify-phase-0.sh)
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter (after planner + checker pass)

**Approval:** pending

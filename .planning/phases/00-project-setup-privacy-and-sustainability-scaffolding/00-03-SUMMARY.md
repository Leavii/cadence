---
phase: 00-project-setup-privacy-and-sustainability-scaffolding
plan: "03"
subsystem: legal-and-ops-docs
tags: [privacy, legal, dns, gdpr, oss-sustainability]
dependency_graph:
  requires: []
  provides:
    - docs/legal/privacy-policy.md
    - docs/legal/terms-of-service.md
    - docs/legal/retention-schedule.md
    - docs/legal/hosting-cap.md
    - docs/legal/shutdown-plan.md
    - docs/ops/dns.md
  affects:
    - Phase 1 (users.last_signin_at field name locked by hosting-cap.md)
    - Phase 1 (AUTH-07 account deletion flow references retention-schedule.md)
    - Phase 3 (events-cleanup worker references 90-day retention rule)
    - Phase 5 (helper-never-sends-Anthropic-token rule referenced in privacy-policy.md)
    - Phase 9 (legal review of all docs at flip-day per CD-04)
    - Phase 9 (D-14 naming finalization: replace {ROOT_DOMAIN} placeholders)
tech_stack:
  added: []
  patterns:
    - "Clean-room legal doc authoring: adapt Plausible/Standard Ebooks templates, lawyer review at flip-day"
    - "Pitfall 7 mitigation: tag every retention rule with implementing phase"
    - "Pitfall 8 mitigation: single verbatim SQL definition for 'active' user (last_signin_at)"
    - "Pitfall 9 mitigation: per-user data export inventory committed before any code runs"
key_files:
  created:
    - docs/legal/privacy-policy.md
    - docs/legal/terms-of-service.md
    - docs/legal/retention-schedule.md
    - docs/legal/hosting-cap.md
    - docs/legal/shutdown-plan.md
    - docs/ops/dns.md
  modified: []
decisions:
  - "Task 1 (EU-residency gate): maintainer confirmed non-EU, United States"
  - "Art. 27 placeholder added to privacy-policy.md: will appoint EU representative if GDPR Art. 27 thresholds are crossed"
  - "Hetzner DE host + US controller = international transfer of EU-subject data; SCC-based safeguard placeholder added, flagged for legal review at flip-day"
  - "Task 4 (domain purchase): deferred to flip-day per D-14/D-11; {ROOT_DOMAIN} placeholders remain throughout all docs"
metrics:
  duration: "~20 minutes"
  completed: "2026-05-08"
  tasks_completed: 3
  tasks_total: 4
  files_created: 6
  files_modified: 0
---

# Phase 00 Plan 03: Legal, Privacy, and Ops Docs Summary

**One-liner:** Six legal/ops docs committed with GDPR-aligned privacy policy (granular consent + US controller + Art. 27 placeholder), Apache-2.0 ToS with DCO inbound clause, phase-tagged retention schedule, verbatim D-06 SQL hosting-cap definition, 90-day shutdown notice + per-user data-export inventory, and SPF/DKIM/DMARC DNS records ready for flip-day substitution.

## Tasks

| Task | Name | Status | Commit | Files |
|------|------|--------|--------|-------|
| 1 | Maintainer EU-residency confirmation | Pre-resolved (non-EU: United States) | N/A (gate, not artifact) | N/A |
| 2 | Author privacy-policy.md + terms-of-service.md + retention-schedule.md | Complete | see below | 3 files |
| 3 | Author hosting-cap.md + shutdown-plan.md + dns.md | Complete | see below | 3 files |
| 4 | Domain purchase (checkpoint:human-action) | Deferred — carryover to flip-day | N/A | N/A |

## Task 1: EU-Residency Gate (Pre-Resolved)

**Decision:** non-EU: United States

Applied to `docs/legal/privacy-policy.md`:
- Controller declaration: `{MAINTAINER_NAME}, United States`
- Added GDPR Art. 27 placeholder sentence under "Who we are": "If we cross GDPR Art. 27 thresholds (offering services to EU data subjects at scale, monitoring EU subjects' behavior), we will appoint an EU representative."
- Added international-transfer note under "Where we host": Hetzner DE (EU) + US controller = EU-to-US data transfer; SCC-based safeguard placeholder; flagged for legal review at flip-day per CD-04.

**This starting assumption is recorded here so Phase 9 legal review knows the basis.**

## Task 2: Privacy, ToS, Retention (Docs Created)

### docs/legal/privacy-policy.md
- Clean-room adaptation of Plausible's policy + GDPR.eu template (per CD-04)
- Controller: `{MAINTAINER_NAME}, United States` (non-EU decision applied)
- 3 granular consents named: `event_capture`, `public_leaderboards`, `email_digests`
- Plausible Analytics (managed cloud, plausible.io) explicitly named as the only analytics provider
- Google Analytics: absent (PRIV-04 negative met)
- Anthropic OAuth token row: "Never collected -- stays on user's machine"
- Lawful basis tagged per GDPR Art. 6 for each data category
- Retention column links to retention-schedule.md

### docs/legal/terms-of-service.md
- Hobby-project disclaimer with 5,000-account cap reference
- Apache-2.0 inbound = outbound (DCO, no CLA)
- References developercertificate.org
- Cross-references: shutdown-plan.md, retention-schedule.md, privacy-policy.md
- Anti-cheat section and account-deletion path documented

### docs/legal/retention-schedule.md
- Verbatim from RESEARCH.md Example 6
- Every row tags the implementing phase (Pitfall 7 mitigation)
- 90-day raw events retention (events-cleanup BullMQ worker, Phase 3)
- Indefinite aggregates
- Account deletion (AUTH-07) section with 90-day handle cooldown

## Task 3: Hosting Cap, Shutdown Plan, DNS (Docs Created)

### docs/legal/hosting-cap.md
- 5,000 active account cap (D-06)
- Verbatim SQL definition: `SELECT COUNT(*) FROM users WHERE last_signin_at > NOW() - INTERVAL '90 days';`
- Pitfall 8 mitigation: single source of truth for "active" user definition
- Cap-overflow: waitlist + `docker compose up` self-host prompt (D-07)

### docs/legal/shutdown-plan.md
- 90-day notice commitment (all channels + one-time email)
- Per-user data export inventory: profile, achievements, cosmetics, level + lifetime XP, last 90 days raw events, quest history, comments authored, friend graph rows
- 3-tier shutdown options in priority order: Transfer, Wind-down, Hard close
- Self-hosters unaffected (Apache-2.0 guarantees forks)
- Pitfall 9 mitigation: export inventory committed before any code runs; export endpoint flagged as post-Phase-0 backlog

### docs/ops/dns.md
- SPF: `v=spf1 include:amazonses.com ~all` on `send.{ROOT_DOMAIN}`
- MX placeholder for Resend/SES bounce handling
- DKIM: placeholder shape (Resend issues actual keys at domain-add)
- DMARC: 3-step progression `p=none -> p=quarantine -> p=reject` over 30+ days
- From-address policy: `noreply@` (transactional) + `hello@` (replyable) per D-12
- Pitfall 6 reference: SPF 10-DNS-lookup limit warning for future second mail provider

## Task 4: Domain Purchase (Carryover)

**Status:** Deferred to flip-day

Domain purchase is blocked on final project naming (D-14 defers naming to Phase 9 launch readiness). The docs are authored with `{ROOT_DOMAIN}` placeholders throughout. When the domain is purchased:

1. Replace all `{ROOT_DOMAIN}` occurrences in: `docs/legal/privacy-policy.md`, `docs/legal/terms-of-service.md`, `docs/legal/hosting-cap.md`, `docs/legal/shutdown-plan.md`, `docs/ops/dns.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `README.md`
2. Add the domain to Cloudflare Registrar (per CD-02) with WHOIS privacy and 2FA
3. Add the Resend domain, obtain actual DKIM selectors and public keys, update `docs/ops/dns.md`
4. Configure DNS with the committed SPF/DKIM/DMARC records

This is a single-PR substitution after domain purchase. **Action inherited by Phase 9 (naming finalization / flip-day).**

## Placeholders Pending Flip-Day Substitution

| Placeholder | Files | Resolution |
|-------------|-------|------------|
| `{ROOT_DOMAIN}` | privacy-policy.md, terms-of-service.md, hosting-cap.md (self-host docs link), shutdown-plan.md, dns.md | Domain purchase + naming finalization (Phase 9 / D-14) |
| `{INSTANCE_HOSTNAME}` | privacy-policy.md, terms-of-service.md | Same as ROOT_DOMAIN (or subdomain for API vs web) |
| `{MAINTAINER_NAME}` | privacy-policy.md, terms-of-service.md | Maintainer confirms public display name at flip-day |
| `{SELECTOR}` / `{PUBLIC_KEY}` | dns.md | Resend issues at domain-add time |
| `{REGION}` | dns.md | Resend dashboard (e.g., us-east-1 or eu-west-1) |
| `{link}` | hosting-cap.md (self-host link) | Self-host docs URL once domain is live |

## Items Flagged for Phase 9 Legal Review

Per CD-04, lawyer review is deferred to visibility-flip / launch:

1. **Privacy policy controller declaration** — confirm US-based controller with Hetzner DE processing meets SCC requirements for EU data subjects
2. **GDPR Art. 27 representative** — if public-instance EU user count crosses threshold at launch, appoint EU representative before going public
3. **Governing law (ToS)** — currently placeholder "United States law applies"; lock to specific state (e.g., California or maintainer's state)
4. **SCC transfer mechanism** — confirm specific SCC clauses (2021 EU SCCs, controller-to-processor or controller-to-controller) apply to Hetzner CX22 relationship

## Deviations from Plan

None -- plan executed as written. Task 1 was pre-resolved per orchestrator instruction; Task 4 is a documented carryover.

**All 6 docs created verbatim from RESEARCH.md examples with only the following intentional additions:**
- Non-EU Art. 27 language in privacy-policy.md (per pre-resolved Task 1)
- International-transfer / SCC note in privacy-policy.md (required by non-EU controller + EU host)
- SPF lookup limit (Pitfall 6) warning block in dns.md (plan says "Pitfall 6 reference: SPF 10-DNS-lookup limit warning" is required in acceptance criteria)
- `{MAINTAINER_COUNTRY}` placeholder replaced with literal `United States` per Task 1 resolution

## Threat Flags

None. All docs are static Markdown with no network endpoints, auth paths, or data collection of their own. Threats T-00-12 through T-00-17 from the plan's threat model are mitigated by the doc content as specified.

## Self-Check

### Files exist
- docs/legal/privacy-policy.md: CREATED
- docs/legal/terms-of-service.md: CREATED
- docs/legal/retention-schedule.md: CREATED
- docs/legal/hosting-cap.md: CREATED
- docs/legal/shutdown-plan.md: CREATED
- docs/ops/dns.md: CREATED

### Acceptance criteria spot-check (by content review)
- event_capture in privacy-policy.md: PRESENT
- public_leaderboards in privacy-policy.md: PRESENT
- email_digests in privacy-policy.md: PRESENT
- plausible.io in privacy-policy.md: PRESENT
- Google Analytics in privacy-policy.md: ABSENT (PRIV-04 negative)
- "Never collected" in privacy-policy.md: PRESENT
- Art. 6 / GDPR in privacy-policy.md: PRESENT
- Apache-2.0 in terms-of-service.md: PRESENT
- shutdown-plan.md reference in terms-of-service.md: PRESENT
- developercertificate.org in terms-of-service.md: PRESENT
- "hobby project" in terms-of-service.md: PRESENT
- 5,000 in terms-of-service.md: PRESENT
- "90 days" in retention-schedule.md: PRESENT
- "raw events" in retention-schedule.md: PRESENT
- Phase 1 in retention-schedule.md: PRESENT
- Phase 3 in retention-schedule.md: PRESENT
- AUTH-07 in retention-schedule.md: PRESENT
- 5,000 in hosting-cap.md: PRESENT
- "90 days" in hosting-cap.md: PRESENT
- last_signin_at in hosting-cap.md: PRESENT
- INTERVAL in hosting-cap.md: PRESENT
- docker compose up / self-host in hosting-cap.md: PRESENT
- "90 days" / "90-day" in shutdown-plan.md: PRESENT
- "data export" in shutdown-plan.md: PRESENT
- Transfer in shutdown-plan.md: PRESENT
- wind-down in shutdown-plan.md: PRESENT
- Self-hosters in shutdown-plan.md: PRESENT
- Profile in shutdown-plan.md: PRESENT
- achievements in shutdown-plan.md: PRESENT
- include:amazonses.com in dns.md: PRESENT
- _dmarc in dns.md: PRESENT
- DKIM in dns.md: PRESENT
- noreply@ in dns.md: PRESENT
- hello@ in dns.md: PRESENT
- p=none / p=quarantine / p=reject in dns.md: PRESENT
- SPF lookup limit / 10 in dns.md: PRESENT

## Self-Check: PASSED

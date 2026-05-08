# Phase 0: Project Setup, Privacy, and Sustainability Scaffolding - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-08
**Phase:** 0-project-setup-privacy-and-sustainability-scaffolding
**Areas discussed:** License + Code of Conduct, Public hosting target & user cap, Email & operational dependencies, Repository host & final branding

---

## License + Code of Conduct

### License pick

| Option | Description | Selected |
|--------|-------------|----------|
| Apache-2.0 (Recommended) | Explicit patent grant; protects users + contributors from patent claims; SUMMARY.md preferred | ✓ |
| MIT | Shorter, simpler, no patent grant; most common in JS/TS OSS | |
| Apache-2.0 with NOTICE | Apache-2.0 plus NOTICE file for third-party attributions | |

**User's choice:** Apache-2.0 (Recommended)

### Code of Conduct text

| Option | Description | Selected |
|--------|-------------|----------|
| Contributor Covenant 2.1 (Recommended) | De facto OSS standard; drop in unmodified | ✓ |
| Contributor Covenant 2.1 + custom enforcement appendix | Same text plus project-specific reporting/SLA | |
| Citizen Code of Conduct 2.3 | Alternative focused on identity-based protections | |

**User's choice:** Contributor Covenant 2.1 (Recommended)

### Contribution gate

| Option | Description | Selected |
|--------|-------------|----------|
| DCO sign-off only (Recommended) | `Signed-off-by:` line on every commit; CI checks; no paperwork | ✓ |
| CLA via CLA Assistant bot | Each contributor signs CLA once; higher friction; useful if relicensing anticipated | |
| No gate — just license + CoC | Implicit acceptance via PR; lowest friction; weaker if disputed | |

**User's choice:** DCO sign-off only (Recommended)

### Copyright attribution

| Option | Description | Selected |
|--------|-------------|----------|
| `Copyright (c) {year} {Project} Contributors` (Recommended) | Single project-style attribution; no per-file authors | ✓ |
| No copyright header in source files | Rely solely on root LICENSE | |
| Per-file authors header | Each contributor adds name when modifying; heavy maintenance | |

**User's choice:** Project-style header (Recommended)

---

## Public hosting target & user cap

### Hosting provider

| Option | Description | Selected |
|--------|-------------|----------|
| Hetzner CX22 + Coolify (Recommended) | ~$5-15/mo; same Docker Compose as self-host = parity for free | ✓ |
| Fly.io + Cloudflare | ~$30-100/mo; better global edge; Fly machines diverge from pure Docker Compose | |
| Render + Cloudflare | Simpler PaaS UI than Fly; free tier spins down (bad for SSE) | |
| Defer hosting decision to launch | Phase 0 ships Docker Compose only; pick provider at Phase 9 | |

**User's choice:** Hetzner CX22 + Coolify (Recommended)

### User cap

| Option | Description | Selected |
|--------|-------------|----------|
| 5,000 active accounts (Recommended) | Active = signed in within 90 days; comfortable on Hetzner CX22 | ✓ |
| 1,000 active accounts | Conservative; lets you monitor real load | |
| 10,000 active accounts | Generous; signals confidence; bigger blast radius if lowered | |
| Cap deferred — "best-effort, see status page" | No hard number; weaker shutdown-discipline signal | |

**User's choice:** 5,000 active accounts (Recommended)

### Cap-overflow policy

| Option | Description | Selected |
|--------|-------------|----------|
| Waitlist + self-host link prominent (Recommended) | Converts overflow into self-host adoption | ✓ |
| First-come / hard-stop signups | Cleaner UX; shuts the door entirely | |
| Soft-cap — keep accepting, slow features | Service degrades gracefully; risky for budget | |

**User's choice:** Waitlist + self-host link prominent (Recommended)

### Region target

| Option | Description | Selected |
|--------|-------------|----------|
| Single region, EU or US (Recommended) | One region; small payloads tolerate cross-Atlantic latency; matches scale | ✓ |
| Single US region only | Optimizes for likely-largest early pool | |
| Multi-region from day 1 | Significant ops work; almost certainly premature | |

**User's choice:** Single region, EU or US (Recommended) — defaulting to EU per Hetzner choice

---

## Email & operational dependencies

### Email provider (public instance)

| Option | Description | Selected |
|--------|-------------|----------|
| Resend (Recommended) | Generous free tier (3k/mo); excellent React Email integration; SMTP fallback | ✓ |
| Postmark | Industry-leader transactional; smaller free tier ($15/mo for 10k) | |
| AWS SES | Cheapest at scale; highest ops burden (warm-up, sandbox-out) | |
| SMTP-only (BYO) | Just SMTP_URL env var; lowest lock-in, highest setup friction | |

**User's choice:** Resend (Recommended) — self-host instances still get SMTP_URL env var

### Local-dev mail catcher

| Option | Description | Selected |
|--------|-------------|----------|
| Mailpit in docker-compose (Recommended) | Catches outbound mail; web UI on :8025; modern MailHog fork | ✓ |
| MailHog in docker-compose | Older, less actively maintained | |
| Console-log emails only | Lighter compose stack; worse dev UX | |

**User's choice:** Mailpit in docker-compose (Recommended)

### Domain & sender identity

| Option | Description | Selected |
|--------|-------------|----------|
| Buy domain in Phase 0; sender = noreply@{domain} (Recommended) | DKIM/DMARC must work for Phase 1 verification emails | ✓ |
| Defer domain to Phase 1; use provider sandbox sender | Pushes cost out; verification email blocked until domain lands | |
| Use a personal domain + subdomain | Free if already owned; mixes project + personal identity | |

**User's choice:** Buy domain in Phase 0 (Recommended)

### From-address policy

| Option | Description | Selected |
|--------|-------------|----------|
| noreply@ for transactional, hello@ for support (Recommended) | Standard split; hello@ replyable | ✓ |
| Single hello@ for everything (replyable) | Friendlier; risks reply-triage burden | |
| Per-purpose addresses (verify@, pair@, security@…) | Cleanest categorization; overkill at hobby scale | |

**User's choice:** noreply + hello pattern (Recommended)

---

## Repository host & final branding

### Repo host

| Option | Description | Selected |
|--------|-------------|----------|
| GitHub (Recommended) | Where Claude Code users are; GHA + Sponsors integration | ✓ |
| Codeberg | OSS-aligned community Gitea; weaker discovery; immature Forgejo Actions | |
| GitHub primary + Codeberg mirror | Auto-mirror via GHA; minor extra ops; doesn't relocate audience | |
| Self-hosted Gitea on the same VPS | Fully independent; way more ops; near-zero discovery | |

**User's choice:** GitHub (Recommended)

### Project naming

| Option | Description | Selected |
|--------|-------------|----------|
| Stay on working title until Phase 9 launch readiness (Recommended) | Naming under pressure produces worse names | ✓ |
| Pick a name now via short brainstorm | Forces clarity early; risks regret-pick | |
| Crowdsource via GitHub Discussions after launch | Slowest; most democratic | |

**User's choice:** Stay on working title (Recommended)

### Repo visibility

| Option | Description | Selected |
|--------|-------------|----------|
| Public from the very first commit (Recommended) | Aligns with OSS-from-day-one posture | |
| Private during Phase 0-1, public at Phase 2 | Polish privately; reveal once auth + pairing exists | |
| Private until v1 launch (Phase 9) | Marketing-heavy; SaaS-launch playbook | |
| **(User-typed override)** Keep private until I am ready to make public | No fixed phase; maintainer flips when ready | ✓ |

**User's choice:** Custom — "I will keep it private until I am ready to make it public"
**Notes:** User explicitly diverged from the recommendation. CONTEXT.md D-15 records this as a USER OVERRIDE so downstream agents respect it. Knock-on: GitHub Sponsors won't function on a private repo, so donations channel for Phase 0 falls to Ko-fi or OpenCollective (see Claude's Discretion CD-01).

### Repo DR / mirror

| Option | Description | Selected |
|--------|-------------|----------|
| GitHub native + tag-based release backups in S3/R2 (Recommended) | GitHub primary; tag-based git-bundle uploads; simple ops | |
| No mirror at v1 | Rely on GitHub uptime; defer DR until maintainer-bus-factor concern | ✓ |
| Continuous mirror to Codeberg / GitLab.com | Push-on-every-commit; solid DR; SSH key bookkeeping | |

**User's choice:** No mirror at v1

---

## Claude's Discretion

- **CD-01 (donations channel):** GitHub Sponsors needs a public profile/repo; D-15 keeps the repo private. Set up Ko-fi or OpenCollective for Phase 0 (works without a public repo) and add GitHub Sponsors at the visibility flip. README + (placeholder) web app footer link to whichever donations destination is live.
- **CD-02 (domain registrar):** Cloudflare Registrar (at-cost pricing, free WHOIS privacy) as default unless maintainer overrides.
- **CD-03 (reserved-handle list authoring):** ~200 reserved names defined as `packages/content/reserved-handles.json` in Phase 0 even though enforcement is Phase 1.
- **CD-04 (privacy-policy / ToS authoring approach):** Start from a permissive-OSS template (Plausible / Standard Ebooks style); flag for legal review at the visibility flip / launch.

## Deferred Ideas

- Final product name — Phase 9 launch readiness
- Repo visibility flip date — maintainer's call, not phase-bound
- GitHub Sponsors activation — deferred to flip-day
- DR mirror to second host — deferred until maintainer-bus-factor concern arises
- Multi-region hosting — deferred to a post-v1 milestone
- Per-purpose email addresses (`verify@`, `pair@`, `security@`, etc.) — deferred until volume justifies it
- Legal review of privacy policy / ToS — deferred to visibility-flip / launch

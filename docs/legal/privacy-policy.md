<!--
This privacy policy is a clean-room adaptation of Plausible's published policy + GDPR.eu template
per CD-04. Lawyer review deferred to visibility-flip / launch (see 00-RESEARCH.md Open Question 1).
Placeholders {ROOT_DOMAIN}, {INSTANCE_HOSTNAME}, {MAINTAINER_NAME}, {MAINTAINER_COUNTRY} are
filled at domain-buy / flip-day.
-->

# Privacy Policy

**Effective:** 2026-05-08 • **Instance:** {INSTANCE_HOSTNAME} • **Controller:**
{MAINTAINER_NAME}, United States • **Contact:** privacy@{ROOT_DOMAIN}

> This is the privacy policy for the public hosted instance. Self-hosted
> instances inherit this template but the controller, contact, and infrastructure
> sections will differ — self-hosters MUST update those sections before deploying.

## Who we are

{MAINTAINER_NAME} runs this service as a hobby project. We are the data
controller (GDPR Art. 4). We have no Data Protection Officer (volume below
threshold per GDPR Art. 37); contact above.

We are based in the United States. If we cross GDPR Art. 27 thresholds (offering
services to EU data subjects at scale, monitoring EU subjects' behavior), we will
appoint an EU representative.

## What data we process

| Data | Source | Lawful basis (GDPR Art. 6) | Retention |
|------|--------|----------------------------|-----------|
| Email + password hash | Signup | Contract (Art. 6(1)(b)) | Until account deletion |
| Public handle | Signup | Contract; legitimate interest | Until account deletion + 90-day cooldown |
| Workflow events (token counts, session length, etc.) | Helper module | **Granular consent (Art. 6(1)(a))** — separate consent toggle `event_capture` | 90 days raw, indefinite aggregated (see [retention-schedule.md](./retention-schedule.md)) |
| Public leaderboard rank + cosmetics | Computed | **Granular consent** — separate toggle `public_leaderboards` | While consented |
| Email digest opt-in | Settings | **Granular consent** — separate toggle `email_digests` | While consented |
| Anthropic OAuth token | **Never collected** — stays on user's machine | n/a | n/a |

## Where we host

Public instance: Hetzner GmbH (Falkenstein, Germany — EU). Because the controller
is based in the United States and data is processed on EU infrastructure (Hetzner
DE), personal data of EU subjects may be subject to international transfer from the
EU to the United States. We rely on Standard Contractual Clauses (SCCs) as the
transfer safeguard. This safeguard will be reviewed and confirmed at flip-day per
CD-04 legal review.

## Your rights

GDPR Arts. 15-22: access, rectification, erasure, restriction, portability,
objection, withdraw-consent. Email privacy@{ROOT_DOMAIN}. We respond within 30
days. To file a complaint: your local Data Protection Authority (in DE: BfDI).

## Analytics

The public instance uses **Plausible Analytics (managed cloud, plausible.io)**.
Plausible is cookie-free and does not collect personal data. See
plausible.io/data-policy for their data flows. **Plausible is the only
third-party analytics provider in scope.** No Google Analytics, no Facebook
Pixel, no behavioral tracking.

## Cookies

We use a single first-party session cookie (Better Auth, HttpOnly, SameSite=Lax)
required for login. No third-party cookies. Plausible does not use cookies.

## Granular consent

You consent separately to:
1. **`event_capture`** — event capture from the helper module
2. **`public_leaderboards`** — public leaderboard participation
3. **`email_digests`** — email digests

Each can be withdrawn independently in `/settings/privacy`. Withdrawal stops
collection going forward; existing aggregated data may be retained per
[retention-schedule.md](./retention-schedule.md).

## Changes to this policy

Material changes are emailed to all users 30 days before they take effect.

## Contact

privacy@{ROOT_DOMAIN}

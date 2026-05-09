<!--
Terms of Service. Clean-room adaptation per CD-04 (Plausible/Standard Ebooks/Codeberg style).
Placeholders {ROOT_DOMAIN}, {MAINTAINER_NAME} filled at flip-day. Legal review deferred to
visibility-flip / launch.
-->

# Terms of Service

**Effective:** 2026-05-08 - **Instance:** {INSTANCE_HOSTNAME} - **Service:** Claude Code Gamification Service (working title)

> These Terms apply to the public hosted instance. Self-hosted instances inherit this template
> but operate under the self-hoster's own terms.

## Service description

Claude Code Gamification Service is an open-source gamification layer for Claude Code users.
A web app, backend, and helper module turn workflow signals (token usage, sessions, context
efficiency, hook events) into quests, achievements, leaderboards, and cosmetic unlocks.

## Maintenance posture

This is a hobby project maintained on a best-effort basis. Issues and PRs are welcomed but not
guaranteed a response within any specific timeframe. The public hosted instance is capped at
5,000 active accounts; if that fills up, please run your own instance under the
[Apache-2.0 license](../../LICENSE). See `docs/legal/hosting-cap.md` for the cap definition.

## Account

You agree to:
- Provide accurate information at signup.
- Choose a public handle that does not impersonate another person, brand, or entity. (See the
  reserved-handle list at `packages/content/reserved-handles.json`; enforcement details land in
  Phase 1.)
- Not abuse rate limits, the API, or the moderation system.

You may delete your account at any time via Settings (path implemented in Phase 1, AUTH-07).
Account deletion removes raw events within the documented retention window
(`docs/legal/retention-schedule.md`).

## User content

When you contribute code via pull request, you contribute under the
[Developer Certificate of Origin](https://developercertificate.org/) and your contribution is
licensed under [Apache-2.0](../../LICENSE) (inbound = outbound). There is no Contributor License
Agreement.

When you post comments on profiles or otherwise contribute non-code content within the service,
you grant the service operator a non-exclusive, worldwide license to host and display that
content as part of running the service. You retain copyright. Content is moderated per
[CODE_OF_CONDUCT.md](../../CODE_OF_CONDUCT.md) and the moderation flow shipped in Phase 9.

## Public leaderboard participation

Public leaderboards are a separate granular consent (see `docs/legal/privacy-policy.md`). You
can withdraw consent for public leaderboards independently of other consents.

## Data handling

See [Privacy Policy](./privacy-policy.md) and [Retention Schedule](./retention-schedule.md).

## Service availability

The service is provided "as is" without warranty. Maintenance, downtime, and feature changes
are at the maintainer's discretion. The maintainer commits to providing 90 days notice and a
per-user data export before any public-instance shutdown -- see [Shutdown Plan](./shutdown-plan.md).

## Termination

The maintainer may suspend or terminate accounts that violate these terms or the Code of
Conduct. The user may delete their account at any time.

## Anti-cheat

Lightweight server-side validation operates on event ingestion to detect and discourage cheating.
The full anti-cheat policy is published separately (Phase 10). Affected users see a visible
flag plus a single-click appeal form; appeals auto-restore after 7 days unless explicitly
upheld.

## Changes to these terms

Material changes are emailed to all users 30 days before they take effect.

## Governing law

To be locked at flip-day per CD-04 legal review. Default while drafting:
United States law applies.

## Contact

hello@{ROOT_DOMAIN}

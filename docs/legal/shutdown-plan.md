# Public Instance Shutdown Plan

If this project's maintainer chooses to step down or close the public instance,
the following commitments apply.

## 90-day notice

A clear, prominent notice is posted to:
- The web app (sticky banner on every page)
- The README in the repository
- Any active social channels
- Email to every account with `email_notifications` consent OR signed in within
  the last 90 days (one-time, regardless of consent state, since it's a service
  notice not marketing)

Notice contains: shutdown date, data export instructions, transfer plan if any.

## Data export per user

Every user can self-service export their data via a "Download my data" button
in `/settings`. Export contains:

- Profile (handle, history, settings)
- All earned achievements + cosmetics + level + lifetime XP
- Last 90 days of raw events
- All quest history
- All comments authored
- All friend graph rows where the user is the subject

Format: a single JSON file (with linked attachments if any).

(Specific implementation arrives in a later phase; flagged in
`.planning/ROADMAP.md` as a post-Phase-0 backlog item.)

## Hosted-instance shutdown options

In priority order:
1. **Transfer:** Hand the public instance to a successor maintainer with
   continuity for end users.
2. **Wind-down:** Run the public instance read-only for 30 days after the
   shutdown date so users can export.
3. **Hard close:** Close on the shutdown date, providing the export window in
   the 90 days *before* close.

## Self-hosters

Self-hosted instances are unaffected by public-instance shutdown by definition.
The Apache-2.0 license guarantees forks can continue indefinitely.

## Why pre-commit

Trust requires pre-commitment. Users investing time in a streak or building an
identity on this platform deserve to know the exit conditions before they
commit. This document is the contract.

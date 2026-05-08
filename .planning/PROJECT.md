# Claude Code Gamification Service

*(Working title — final product name TBD. Directory name `GSD-StatusLineGamification` is legacy and undersells the scope.)*

## What This Is

An open-source gamification service for Claude Code users. A web app, backend, and helper module that turn real workflow signals — token usage, sessions, context efficiency, hook events — into quests, achievements, leaderboards, and cosmetic unlocks. Statusline-agnostic: the helper module exposes data for any statusline implementation, while the web app is the canonical dashboard for users who don't customize their statusline at all.

## Core Value

Make daily Claude Code usage feel less transactional and more rewarding, through honest gamification of the workflow signals users already generate.

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

(None yet — ship to validate)

### Active

<!-- Current scope. Building toward these. -->

**Account & onboarding**
- [ ] Public web signup with a chosen real handle (Twitch-style identity)
- [ ] Browser device-pairing flow: web signup → CLI command opens browser → OAuth-style binds local install to account
- [ ] User profile page (handle, badges, stats, achievements, leaderboard standings)

**Local integration**
- [ ] Documented helper module / API that exposes gamification data (XP, active quests, streaks, badges, leaderboard rank, etc.) for users to wire into any statusline
- [ ] Hook integration that captures workflow signals: token usage (rolling windows + lifetime totals), session length, messages sent, context efficiency, /clear and /compact events, plugin/MCP server installs
- [ ] Cached integration with Anthropic OAuth usage API (`https://api.anthropic.com/api/oauth/usage`) for 5h/7d window data

**Quests**
- [ ] 5 daily quests per user: 3 global (1 easy / 1 medium / 1 hard, same set for everyone today, rotates daily) + 2 personalized (1 builds on a skill the user already shows, 1 pushes a growth area)
- [ ] Quests award XP only (no badges or cosmetic drops from quests)
- [ ] Quest progress visible via API and web app

**Achievements**
- [ ] Achievement system separate from quests; tracks long-term feats and milestones
- [ ] Achievements unlock cosmetics: badges, glyphs (including animated), themes
- [ ] Every cosmetic is tied to a specific achievement (no XP shop, no random drops)

**Leaderboards**
- [ ] Four leaderboards, each ranking a different dimension: raw activity, streaks, quest XP, efficiency
- [ ] Leaderboards public by default, tied to user's real handle

**Web app — social hub**
- [ ] Profile, leaderboards, quest list, badge case (read-only dashboard)
- [ ] Friends / follows
- [ ] Comments on profiles
- [ ] Public showcases
- [ ] Foundation hooks for v2 raid coordination (data model only)

**Visual identity**
- [ ] Retro arcade aesthetic across web app and helper module output: pixel/ASCII art, 8-bit palette, score-popup feel
- [ ] Theme system that the helper module respects so unlocks actually change what users see

**Anti-cheat**
- [ ] Lightweight server-side validation: reject impossible deltas, shadow-ban obvious cheaters
- [ ] Zero perceivable performance or UX cost in the user's Claude Code session

**Distribution**
- [ ] Codebase open source under a permissive license
- [ ] Free hosted instance for the public
- [ ] Optional sponsorship / donations channel

### Out of Scope

<!-- Explicit boundaries. Includes reasoning to prevent re-adding. -->

- **Cooperative raids (community-wide goals everyone chips into)** — explicit v2; ship core loop first
- **Companions (persistent statusline creatures that grow over time)** — explicit v2; bigger design and tech investment than v1 should bear
- **Quest designer / community-submitted quests** — moderation surface area too large for v1
- **Mobile app** — web-first; no native client in v1
- **Paid cosmetic store** — every cosmetic earned through achievements; removes XP-economy balancing
- **Subscription tier with paid analytics** — model is OSS + donations, not freemium
- **Hard payload signing for anti-cheat** — only adopt if it's lightweight and zero-friction; otherwise tolerate some gaming
- **Locking users into our statusline** — service exposes data; users keep their own statusline (or use the web app)

## Context

- **Reference statusline:** `~/.claude/statusline.js` already exists locally as a working segmented ANSI status line: shows folder, model, context % with green/yellow/red thresholds, 5h and 7d Anthropic usage bars with thresholds, and a Central time clock. **Not** the product template — used here only to confirm the visual style of segmented ANSI output the helper module should be capable of producing.
- **Known data source for usage windows:** Anthropic OAuth usage endpoint `https://api.anthropic.com/api/oauth/usage`, accessed via the OAuth token at `~/.claude/.credentials.json`. Threshold-coloring of 5h/7d usage is already a solved pattern.
- **Primary signal source:** Claude Code's hook system — captures session events, messages, /clear and /compact, plugin/MCP installs.
- **Identity model:** Public + real handle by default means moderation/abuse considerations belong from day one (handle squatting, harassment in comments, leaderboard cheating reports).
- **Open source posture** affects every tech choice: stack must be OSS-friendly, hosting must be self-hostable for forks, contributor onboarding matters, no vendor lock-in.

## Constraints

- **Tech stack:** Open — recommended by research phase. Must be OSS-friendly and self-hostable.
- **Auth model:** Open — must support browser-mediated device pairing for local install binding.
- **Hosting:** Open — design for hundreds of users initially, scaling path must not require a rewrite.
- **Performance:** Local instrumentation must be invisible to user sessions. No latency added to statusline render. No noticeable cost to hooks.
- **Anti-cheat:** Lightweight only. Hard signing/verification only if it's free of friction.
- **Wire protocol (statusline ↔ backend):** Open — recommended by research; needs to be simple enough for users wiring it into their own statusline.
- **License:** Permissive open source (specifics TBD, MIT/Apache style).

## Key Decisions

<!-- Decisions that constrain future work. Add throughout project lifecycle. -->

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Statusline-agnostic via helper module + API | Don't lock users into our statusline; web app is the canonical dashboard | — Pending |
| Four separate leaderboards (raw / streak / XP / efficiency) | One ranking dimension is too narrow; multiple boards reward different play styles | — Pending |
| Public + real handle by default | Maximizes social/competitive identity; Twitch-style | — Pending |
| 5 daily quests: 3 global tiered + 2 personalized | Shared talking point + personal growth nudges | — Pending |
| XP from quests, badges/cosmetics from achievements | Two parallel reward tracks; quests are activity, achievements are milestones | — Pending |
| Cosmetics drop from achievements only (no shop, no random) | Every cosmetic has a story; no XP economy to balance | — Pending |
| Browser-mediated device pairing for onboarding | Familiar OAuth-style UX; binds local install cleanly | — Pending |
| Lightweight anti-cheat only | Performance/UX cost is unacceptable; tolerate some gaming | — Pending |
| Open source + donations (no paid tiers) | Aligns with audience; transparent moderation; self-hostable | — Pending |
| Retro arcade aesthetic | Consistent visual identity across web and statusline output; matches ASCII surface area | — Pending |
| v1 lean: quests / achievements / leaderboards / cosmetics / social hub | Validate the core loop before adding raids and companions | — Pending |
| Raids and companions explicit v2 | Bigger scope; ship and learn before committing to them | — Pending |
| Pragmatic mid-scale design | Build for hundreds; scaling path without rewrite | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-05-08 after initialization*

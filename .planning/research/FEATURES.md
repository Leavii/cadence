# Feature Research

**Domain:** OSS gamification service for Claude Code (web app + backend + statusline-agnostic helper module)
**Researched:** 2026-05-08
**Confidence:** HIGH for table-stakes gamification primitives (well-charted prior art); MEDIUM for the developer-tool-specific personalization signals (less charted, more design judgment); HIGH for anti-features (clear consensus from gamification dark-pattern literature)

## Executive Summary

This product sits at an unusual intersection: it's a gamification service (well-studied domain — Duolingo, Habitica, Strava, Stack Overflow, GitHub achievements all have published lessons) for a developer tool (a domain where gamification has an unusually bad reputation — GitHub already removed contribution streaks for being harmful). The features research has to land both: deliver the gamification table stakes users will recognize, and *avoid* the dark patterns the dev-tool audience is allergic to.

The product's existing decisions already dodge the worst traps: cosmetics are achievement-bound (no XP shop = no economy to balance, no inflation), no random drops (no gambling-style mechanics), real handles (no anonymous toxicity), and the helper module is statusline-agnostic (no lock-in). The FEATURES list below is built around making those decisions concrete and naming the table stakes that ship in v1.

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist for a gamification product. Missing these = product feels incomplete.

#### Account & Identity

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Email/password signup with verification | Baseline auth; users won't trust a gamified social product without it | S | Better Auth covers this. Email verification gates handle claim. |
| OAuth signup (GitHub at minimum) | Audience is developers — GitHub OAuth is the lowest-friction path and pre-fills handle suggestions | S | Better Auth supports GitHub provider out of the box. Recommend GitHub-first; defer Google/X to later. |
| Public real handle (Twitch-style) with squatting protection | Already a project decision. Users expect handles to be unique, lowercase-canonicalized, reserved-list filtered (admin, support, api, system, etc.) | S | Reserved list of ~200 names. Allow handle changes once per 30 days, leave a redirect from old handle. |
| Browser-mediated CLI device pairing | `gh auth login` set the expectation. Users will reject anything that asks them to paste an API key into a terminal. | M | Better Auth's `deviceAuthorization` plugin (RFC 8628) — this is solved. Depends on email/password or OAuth signup. |
| Password reset via email | Universal | S | Better Auth covers this. |
| Account deletion / data export | GDPR + good citizenship; gamification products without this signal "we own your data" | M | Hard delete for personal data, anonymize leaderboard history (so totals don't lie). |
| Profile page (public URL: `/u/handle`) | Read-only summary: handle, badges, stats, achievements, rank, recent activity, friends | M | Foundation for showcases, friend pages, comments. |
| Profile privacy toggle (public/private) | Even on a "public by default" product, some users will need a private mode | S | Private profiles still earn cosmetics; just not visible on leaderboards or profile URL. |

#### Quests (the daily loop)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| 5 daily quests per user (3 global tiered + 2 personalized) | Project decision. Users expect a fixed number that resets daily. | L | Background job (BullMQ) generates the personalized 2 nightly per-user; the global 3 are seeded once per day for everyone. |
| Per-user quest reset at user's local-day boundary, not server midnight | **Critical.** Habitica's #1 historical bug class. Server-midnight resets punish users in distant timezones. | M | Store user's IANA timezone at signup; cron-per-user pattern, or "rolling 24h since last completion checkpoint" model. See PITFALLS. |
| Quest progress visible in real-time (statusline + web app) | Users won't trust a quest they can't see progress on | M | SSE for web app push; helper module reads local cache refreshed by background flusher. |
| Quest completion celebration (visible feedback, XP popup) | Without this, completing a quest feels silent and the loop dies | S | Score-popup ANSI animation in helper module; toast + XP bar fill in web app. |
| Quest difficulty tiers — easy/medium/hard XP scaling | Users need to feel the hard quest is worth it. RuneScape teaches that exponential progression feels good; flat XP feels insulting. | S | Easy ≈ 50 XP, medium ≈ 150 XP, hard ≈ 400 XP (ratio ~1:3:8). Personalized quests scale with user's recent activity baseline. |
| Quest history (last 7 days completed/failed) | Users want to know "did I do it yesterday?" | S | Simple table of `quest_id, user_id, day, completed_at, xp_awarded`. |
| Quest rerolls — 0 free, never (or 1/day cap) | Prior art (Habitica, Genshin, etc.) shows quest rerolls turn quests into a slot machine. The simpler model is "you got what you got, finish 3 of 5 to streak." | XS | Recommend zero rerolls for v1. |

#### XP & Progression

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Lifetime XP total | The number every other system reads off | S | Simple counter, audited. |
| Levels with mildly exponential XP curve | RuneScape's ~10% per level pattern is the gold standard for "quick early levels, meaningful late levels." Pure linear feels boring; pure exponential feels like a wall. | S | Level N XP threshold ≈ `100 * 1.10^(N-1)`. Cap at level 99 (RuneScape homage) but allow "virtual" XP display past that for grinders. |
| XP source attribution | Users want to see "100 XP from quest X, 50 XP from achievement Y" — opaque XP feels rigged | S | Append-only `xp_events` table. |
| Level-up notification | Standard celebration moment | S | Web toast + helper module score-popup on next render. |

#### Achievements

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Achievement catalog (visible + hidden) | Stack Overflow + GitHub teach: visible achievements drive feature discovery; hidden ones reward exploration. ~70/30 split is conventional. | M | Achievement definitions live in code/seeds, not user-editable. Hidden until earned, then revealed with description. |
| Achievement progress bars where applicable | "You're 47/100 on the Long Session achievement" feels good; "you don't have it yet" feels opaque | M | Only for achievements with countable progress. Discrete achievements (one-shot triggers) just unlock. |
| Achievement tiers (bronze/silver/gold) where applicable | GitHub uses this; users understand it intuitively | S | E.g., "Streak: 7 days (bronze) / 30 days (silver) / 100 days (gold)." |
| Achievement unlock celebration | Same as quest celebration but bigger — this is the moment cosmetics drop | S | Web modal, helper module banner. |
| Cosmetic unlock tied to achievement | Project decision. Each cosmetic has exactly one achievement that drops it. Users see "Theme: Phosphor — earned for Marathoner achievement." | M | Foreign key from cosmetics table to achievements table; no orphan cosmetics. |

#### Cosmetics

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Cosmetic inventory page | Badge case is non-negotiable; users will not engage with achievements if they can't see their loot | M | Grouped by type (badges / glyphs / themes), with rarity indicators. |
| Equip/unequip cosmetics | Users expect to choose what to display | S | One active theme; one or more "displayed" badges (cap at 6 like Steam showcase); one active animated glyph. |
| Cosmetic loadout sync to helper module | When user equips a new theme on the web, the statusline should reflect it on next refresh | M | Helper module fetches loadout on session start + periodically; cached locally. |
| Theme system with at least 4 launch themes | A single theme = "system has no theme support." Users expect ≥ 3 visible options at launch even if some are locked. | M | E.g., Phosphor (green-on-black), Amber (CRT amber), NES (red/white/blue arcade), Mono (greyscale). Helper module + web app both honor the active theme. |
| Animated glyph rendering in terminal | Project requirement. Frame-based ANSI animation, ~5-10 fps cap. | M | Use cli-spinners-style frame arrays. Render as part of statusline fragment when user has an animated glyph equipped. Static fallback for non-TTY contexts. |
| Static glyph rendering | For users on terminals that don't repaint cleanly, or in CI / non-interactive contexts | S | Falls back to first frame. |
| Badge metadata (rarity, earn count, earned-on date) | "Owned by 0.3% of players" is a major engagement signal | S | Computed nightly; cached. |

#### Leaderboards

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Four leaderboards: raw activity / streaks / quest XP / efficiency | Project decision. | L | Redis sorted sets, one per board. Recompute as scores update; rolling-window boards rebuild via BullMQ. |
| Global view + friends-only view per board | Strava's biggest engagement lesson: "perceived attainability is the strongest predictor of motivation." Global leaderboards demoralize most users; friend leaderboards drive engagement. | M | Same data, filtered query. Friends-only is `ZRANGEBYLEX` over a friend-set or a SQL fallback. |
| Weekly + monthly + all-time tabs per board | Layered leaderboards (Strava, Duolingo) are the consensus answer to "newcomer fairness vs lifetime achievement." Without weekly, only the launch cohort ever wins. | L | Three sorted sets per board (week-2026-W19, month-2026-05, all-time). Weekly resets via cron. |
| Real-time-ish updates | Users won't wait minutes to see their score climb | M | SSE push to web app; helper module polls. Updates within ~5s of score change. |
| Self-rank highlight ("You: #847") | Without this, leaderboards >100 entries are dead | S | `ZREVRANK` lookup. |
| Tie-breaking rule | Inevitable on streak/efficiency boards; users notice if it's unfair | S | Lexicographic on `(score, earlier_achieved_at)` — earlier reach wins. |

#### Streaks

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Daily activity streak | Universal. Duolingo's `25%+ DAU lift` is the canonical proof. | S | "Activity" = completed at least 1 quest that day. |
| Streak freeze (auto-applied when missed) | Duolingo: streak freeze reduced churn by 21% for at-risk users. Without freezes, a single sick day or vacation kills months of progress and the user just leaves. | M | Earn 1 freeze per N quest completions (cap 2 active). Auto-spent on miss. Visible in profile. |
| Streak repair (paid in XP, time-limited) | Users who lose a streak want a way back. Duolingo charges gems; we use XP debt (e.g., 10× the lost day's XP, within 48h). | M | Optional. Skip in v1 if scope is tight. |
| Site-issue streak protection | Duolingo blogged about this: when Duolingo itself is down, no streaks should break. Build it in from day one. | S | Admin toggle to "freeze all streaks for date X" — used during outages. |
| Streak visibility on profile + statusline | The streak number is the single most-glanced gamification element | S | First-class field in API response. |

#### Web app — Social Hub

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Friend / follow graph | Project decision. Recommend asymmetric (Twitter-style follow), not symmetric (Facebook-style friend). Lower friction. | M | `follows` table: `follower_id, followee_id, created_at`. Bidirectional follow = "mutuals." Feed only needs the directed edge. |
| Follow / unfollow + block | Universal social baseline | S | Block hides both directions in feeds, comments, leaderboards. |
| Profile comments (on profile, not on activities) | Twitch-style channel feed. Light social surface, not a full timeline. | M | `comments` table on profile owner. Owner-only delete + hide. |
| Comment moderation: rate limit, profanity filter, report | Real handles + public profiles = harassment vector. Twitch's Mod View is the reference; we just need basics. | M | Rate limit (3 comments / 60s per user). Profanity wordlist (configurable). Report flow → admin queue. Auto-flag links from new accounts. |
| Public showcase ("pinned" items on profile) | Users expect to choose what's most prominent. Bento-grid pattern is the current standard (GitHub pinned repos, Strava trophy case). | M | Pinned: top 3 achievements, top badge, current streak, theme preview, top-3 leaderboard rank if any. |
| Friend feed / activity stream | Users expect to see friend activity. Strava's kudos loop is the canonical pattern. | M | "Last 7 days of friend activity": achievements unlocked, level-ups, leaderboard climbs. Skip "started a session" — too noisy. |
| Kudos / cheers (lightweight reaction) | Strava's #1 retention mechanic: low-cost positive social reinforcement. Users gave 14B kudos in 2025. | S | Single click; one per activity per user; visible count on activity card. Don't add reactions/comments threading in v1. |
| Leaderboard direct messaging | **Anti-feature** — see below. Don't ship DMs in v1. | — | Listed for completeness. |

#### Helper module / API

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Documented JSON API for statusline integration | Project requirement. Users wire this into their own statusline. | M | OpenAPI spec at `/api/openapi.json`. Stable contract from v1. |
| `cli stats` command returning current state as JSON | The "any statusline can call this" entry point | S | Reads from local cache (< 20ms target). |
| `cli statusline-fragment` returning pre-rendered ANSI | For users who don't want to render themselves | S | Honors active theme, includes XP bar / streak / rank as configured. |
| Hook subcommands (`cli hook session-start`, etc.) | Claude Code hooks pass JSON over stdin; we shell out. | M | One subcommand per hook event we instrument. Append to local outbox. |
| Local outbox + offline tolerance | Users will lose internet; gamification must not lose data or block sessions | M | better-sqlite3 outbox; flush on success, retry with backoff. Idempotency keys per event. |
| `cli pair` (device pairing) | Project requirement | S | Better Auth device flow. |
| `cli unpair` / `cli logout` | Universal | XS | Removes local token + clears outbox. |
| `cli status` (paired? when last synced? queue depth?) | Users will want to debug | S | One-line health check. |

#### Anti-cheat

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Server-side delta validation (rate limits + impossible values) | Project requirement. Lightweight. | M | "Cannot earn > N XP per minute," "session can't exceed N hours," "tokens claimed cannot exceed Anthropic API reported usage" cross-check. |
| Shadow-ban for confirmed cheaters | Standard pattern (per leaderboard cheating research). User still sees their own scores; nobody else does. They don't know they're banned, so they don't try to evade. | M | `users.shadow_banned_at` column. All public queries filter on it. |
| Audit log of suspicious events | Required for any moderation decision | S | Append-only `audit_events` table. |
| Anomaly review queue for admin | Pure-automated bans cause false-positive disasters; humans review before permanent action | M | Simple admin page listing flagged users + recent events. |

#### Distribution / OSS

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Public GitHub repo with permissive license | Project requirement | XS | MIT or Apache-2.0. |
| `docker-compose.yml` for self-hosters | Project requirement (forks must run end-to-end) | S | Per stack research. |
| Basic deployment docs | Self-hosters need this on day one | M | README + DEPLOYMENT.md. |
| Donations link (sponsorship channel) | Project requirement | XS | GitHub Sponsors / Open Collective link in footer. |

---

### Differentiators (Competitive Advantage)

Features that set this product apart from generic gamification or other dev-tool gamification attempts.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Statusline-agnostic helper module** | The closest competitor (statusline plugins) lock you into their statusline. We provide data + an optional renderer. Users keep their existing statusline. | M | Already a project decision; this *is* the differentiator vs anyone else who tries to build this. |
| **Achievement-only cosmetic economy** | No XP shop = no inflation, no balance treadmill, no "is this worth grinding for" calculus. Every cosmetic earned has a story. Differentiates strongly from games-style cosmetic stores. | M | Already a project decision. The supporting feature is making the achievement→cosmetic mapping legible (see table stakes above). |
| **4 separate leaderboards rewarding different play styles** | Most leaderboard-driven products have one ranking dimension which means most users see one number and lose. Four orthogonal axes (raw / streak / XP / efficiency) means a wider population can win at *something*. | L | Already a project decision; the differentiator is publishing this clearly so users see it as a feature, not a quirk. |
| **Personalized quest pair (1 strength, 1 growth)** | Most daily-quest systems give everyone the same set, which means heavy users get bored and light users get crushed. Mixing one quest in your strength zone with one in a growth zone is genuinely different. | L | Personalization signals: token-usage percentile, session-length percentile, /clear-frequency percentile, plugin-install recency, etc. Generated nightly per user from their last 7-day baseline. |
| **Efficiency leaderboard (not just volume)** | Stack Overflow's biggest insight: rewarding *quality* (helpful answers) instead of *quantity* (post count) avoided turning the platform into a spam farm. An efficiency board (e.g., XP-per-token, or context-utilization) signals to users that this product values craft. | M | Define metric carefully — see PITFALLS for how this can go wrong. Recommend: `(quests_completed_per_active_session)` or `(useful_token_share = 1 - waste_ratio)`. |
| **Honest gamification: visible XP source attribution** | Users distrust opaque gamification. Showing "+50 XP: Hard quest 'Marathon Session' completed" everywhere builds trust. | S | Already in table stakes XP attribution; the differentiator is making it visible everywhere, not buried in a debug page. |
| **Retro arcade aesthetic across web AND statusline** | Visual continuity from web to terminal is rare in dev-tool products and is a strong identity marker. Press Start 2P + NES.css + ANSI 16-color palette + score-popup conventions. | M | Per stack research. Differentiator is consistency, not just "we have a theme." |
| **Open source + self-hostable** | Differentiates from any closed alternative someone might build. Critical for trust in a product that telemeters dev workflow. | S | Per stack research. |
| **Foundation hooks for v2 raids in the v1 data model** | Project decision: data model accommodates "community goals everyone chips into" without rewrite. Differentiator is shipping with the architecture future-ready. | S | Schema-only work in v1; UI/loop comes in v2. |
| **CLI status fragment with theme honored** | Most CLI integrations let you customize colors *or* use their preset, never both. We let users equip a theme on the web and the helper module renders accordingly. | S | Theme = ANSI palette + glyph set. Cached locally. |

---

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems for *this* product. Some are already explicit project decisions; others are surfaced from prior-art lessons.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| **Random loot drops / loot boxes** | Variable reward schedules drive engagement (slot machines do too) | Already-rejected by project. Gambling-mechanic stigma; legally regulated as gambling in several jurisdictions; conflicts with "every cosmetic has a story." | Achievement-bound cosmetics only. |
| **XP shop / paid cosmetics** | Standard mobile-game monetization | Already-rejected by project. Creates an XP economy that needs balancing forever; conflicts with the OSS+donations model. | Cosmetics earned via achievements only. |
| **Hard server-side payload signing for anti-cheat** | "Stop cheaters!" | Already-rejected by project. Signing requires private keys on user machines, which can be extracted; the cost is real (CPU + complexity + key rotation pain) and the deterrent is weak. | Lightweight delta validation + shadow-ban; tolerate some gaming. |
| **Quest rerolls (free or per-day)** | "I don't like today's quests" | Turns quests into a slot machine; users reroll until easy quests show up; defeats the personalization signal. Genshin Impact and Habitica both struggle with this. | Zero rerolls. The 5/day pool is small enough that "do 3 of 5" works without rerolls. |
| **Public commit-style contribution graph** | GitHub has one; users may ask for it | GitHub *removed* the streak feature for being harmful, then kept the graph but quietly de-emphasized it. Public daily-activity graphs become guilt machines and reward presenteeism. | Private activity graph (visible to user only). Public profile shows aggregate stats, not daily-grid presence. |
| **Lifetime-only leaderboards (no resets)** | Simpler to implement | Newcomers can never rank. Strava's biggest insight: layered (week/month/all-time) is the only fair model. | Layered leaderboards (already a table stake). |
| **Server-midnight quest reset (single timezone)** | Easier to implement | Habitica's #1 historical bug class. Punishes users in distant timezones. | Per-user local-day reset (already a table stake). |
| **Direct messaging between users** | Standard social feature | Real-handle moderation surface. DM harassment is genuinely awful and very hard to moderate. Out-of-scope for v1's social hub. | Profile comments only (with rate limits + reporting). DMs deferred to v2 if at all. |
| **Public "shame" stats** (low efficiency rank, broken streak counter, lazy day flag) | "Pressure motivates" | The dev-tool dark-pattern literature is unambiguous: shame mechanics drive burnout and churn, not engagement. Productivity-app gamification specifically backfires when it pushes through exhaustion. | All shame-y stats are private-only. Public profile shows positives. |
| **Mandatory streak (no freezes)** | "Streaks should be hard" | Documented churn driver. Duolingo lost 21% of at-risk users until they shipped freezes. Sick days, vacations, on-call rotations all kill rigid streaks. | Streak freezes (already a table stake). |
| **User-submitted quests** | Community content engine! | Already-rejected by project. Moderation surface area too large for v1. Gameable. | Curated quest pool. Defer to v2 if at all. |
| **Public daily-activity heatmap on profile** | GitHub-style visual | Same shame-mechanic concern as the contribution graph. A pretty empty grid is a public guilt trip. | Aggregate stats only on public profile (this week's XP, this month's quests, lifetime totals). |
| **Anonymous handles / pseudonyms by default** | Lower-friction signup | Already-rejected by project (real handle is core to the social hub). Anonymous + leaderboards = unmoderable harassment. | Real handles, with privacy mode for users who want non-public profiles. |
| **Push notifications / email digests by default** | "Re-engagement!" | Productivity dark-pattern territory. Notifications are how engagement-farming products turn into addiction loops. | Opt-in only. Default-off. Web-only at v1; no email digests, no push, no nudges. |
| **Streak-loss-warning emails** ("Your streak ends in 3 hours!") | Industry-standard re-engagement | Direct churn-via-anxiety mechanic. Productivity-tool audience will revolt. Duolingo already gets criticized for this. | If we ever ship reminders, opt-in only and rate-limited. Skip in v1. |
| **AI-assisted "quest of the day" coaching prompts** | AI is hot | Heavy infrastructure for unclear value; LLM costs erode "free + donations" model; quest variety from rule-based personalization is sufficient for v1. | Rule-based personalization in v1; revisit if the rule-based version plateaus. |
| **Public leaderboard "shame" entries** (bottom 10, slowest, laziest) | "Funny!" | Reverse-leaderboard is the most consistently cited harassment vector in the gamification dark-pattern literature. | Top-N only. No bottom-N anywhere, ever. |
| **Per-user achievement creation** | Deep customization | Same moderation problem as user-submitted quests. Gameable and unbalanceable. | Curated achievement set. |
| **Real money cashout** ("trade your XP for...") | Engagement | Crosses into gambling-regulation territory in many jurisdictions. Conflicts with project model. | Never. |
| **Statusline lock-in** (we ship our own, you must use it) | "Tighter UX!" | Already-rejected by project. Helper module is statusline-agnostic. | API-first; reference renderer optional. |
| **Mobile app** | Reach! | Already-rejected by project for v1; web is responsive. | Mobile-friendly web app. Native deferred to v2+. |

---

## Feature Dependencies

```
Email/password signup ──> handle claim ──> profile page ──> public profile URL
                                              │
                                              ├──> follows / friends ──> friend feed
                                              │                       └──> kudos
                                              │
                                              ├──> profile comments ──> moderation queue
                                              │
                                              └──> showcase / pinned items
                                                       │
                                                       └──> badges / cosmetics inventory

OAuth signup ──> handle suggestion ──> [same path]

Better Auth device pairing ──> CLI auth token ──> hook subcommands ──> local outbox ──> backend ingest
                                                                                              │
                                                                                              ├──> XP events ──> level / lifetime XP
                                                                                              ├──> quest progress ──> quest completion ──> streak update
                                                                                              ├──> achievement evaluation ──> cosmetic unlock
                                                                                              └──> leaderboard sorted-set updates

Quest definition ──> daily quest generation (BullMQ) ──> per-user quest set ──> quest progress ──> XP award
                          │
                          └──> personalization signal computation (last-7d baselines)

Achievement definition ──> achievement evaluation (post-XP-event) ──> unlock ──> cosmetic foreign key ──> inventory entry
                                                                                                              │
                                                                                                              └──> equip ──> active loadout ──> helper module render

Theme registry ──> active loadout ──> helper module ANSI palette + glyph frames
                                  └──> web app CSS variables

Redis sorted sets ──> leaderboard query ──> SSE push to web app
                                          └──> CLI poll

Anti-cheat: every XP event ──> delta validator ──> audit_events ──> anomaly queue ──> shadow_banned_at flag
                                                                                              │
                                                                                              └──> filters all public queries

[Out of scope for v1 but data model accommodates]
Raids (v2) ──> community goal table ──> contribution events (already on XP event stream)
Companions (v2) ──> companion table ──> tied to user, fed by activity events
```

### Dependency Notes

- **Profile page is the hub.** Friends, comments, showcase, badges, and leaderboard rank all render *through* the profile. Build the profile shell early.
- **Cosmetics depend on theme rendering depending on web app design system.** The helper module + web app must agree on a theme schema (palette + glyph frame format) before themes can be authored. Build the theme schema once, use it everywhere.
- **Quest personalization depends on having ≥ 7 days of activity.** New users get the global 3 + 2 generic personalized quests until their baseline is computed. Plan for the cold-start case.
- **Friend leaderboard view depends on the follow graph.** Don't ship friends-only filtering before the follow graph exists — and ideally before users have had a few weeks to build their graph.
- **Achievement evaluation must run after every XP event, not on a daily cron.** Users expect "oh I just hit level 10, where's my badge?" instantaneously. BullMQ job enqueued per XP event is fine; daily batch is not.
- **Helper module needs a theme cache that survives restarts.** Otherwise every CLI invocation hits the network for theme metadata, blowing the < 20ms statusline budget.
- **Anti-cheat shadow-ban must filter at the query layer, not at the application layer.** If even one public query forgets the filter, banned users leak back onto leaderboards. Recommend a `public_users` view or row-level security policy that excludes shadow-banned users.
- **Streak freeze depends on quest completion, not on raw activity.** Otherwise users who only opened Claude Code keep streaks without engaging — defeats the metric.
- **Comment moderation depends on report flow + admin role.** Shipping comments without a report button is irresponsible; a basic report → review queue path is the minimum.

### Conflicts

- **Public daily-activity heatmap conflicts with mental health goals.** Either ship a private one or none.
- **Server-midnight resets conflict with global user base.** Per-user timezone is the only correct model.
- **Email re-engagement conflicts with developer-audience trust.** Don't combine "we collect your workflow telemetry" with "we email you to nag you."
- **Random drops would conflict with the achievement-only economy decision.** Don't reintroduce them in any form (including "random achievement progress bonus this week!" which is a loot box in disguise).

---

## MVP Definition

### Launch With (v1)

The minimum viable product. Anything here missing = product doesn't validate the concept.

**Account & Identity**
- [ ] Email/password + GitHub OAuth signup
- [ ] Real-handle claim with reserved-list filtering
- [ ] Better Auth RFC 8628 device pairing (`cli pair`)
- [ ] Public profile page at `/u/handle`
- [ ] Profile privacy toggle
- [ ] Account deletion (hard delete + leaderboard anonymization)

**Quests**
- [ ] 3 global daily quests + 2 personalized per user
- [ ] Per-user local-day reset
- [ ] Quest progress in API + web app
- [ ] Quest completion celebration (web toast + helper-module score popup)
- [ ] Easy/medium/hard XP scaling
- [ ] Last-7-day quest history

**XP & Levels**
- [ ] Lifetime XP counter
- [ ] Level curve (~10% per level)
- [ ] Visible XP source attribution
- [ ] Level-up notification

**Achievements & Cosmetics**
- [ ] Achievement catalog with visible + hidden achievements (~70/30 split)
- [ ] Achievement evaluation on every XP event
- [ ] Achievement unlock celebration
- [ ] Cosmetic inventory (badges, glyphs, themes), grouped by type
- [ ] Equip/unequip cosmetics
- [ ] ≥ 4 launch themes (e.g., Phosphor, Amber, NES, Mono)
- [ ] Animated glyph rendering in helper module (frame arrays + ANSI)
- [ ] Static glyph fallback for non-TTY contexts
- [ ] Theme + loadout sync to helper module

**Leaderboards**
- [ ] 4 boards (raw activity / streaks / quest XP / efficiency)
- [ ] Weekly + monthly + all-time tabs
- [ ] Global + friends-only views
- [ ] Self-rank highlight
- [ ] SSE real-time-ish updates

**Streaks**
- [ ] Daily activity streak
- [ ] Streak freeze (auto-applied) with cap
- [ ] Site-issue streak protection (admin toggle)
- [ ] Streak visibility in API + web + statusline

**Social Hub**
- [ ] Asymmetric follow graph (follow / unfollow / block)
- [ ] Profile comments with rate limit + report
- [ ] Profile showcase (pinned achievements/badges/streak/theme)
- [ ] Friend feed (last 7 days)
- [ ] Kudos on activity items

**Helper Module / API**
- [ ] OpenAPI spec
- [ ] `cli pair`, `cli unpair`, `cli status`
- [ ] `cli stats` (JSON), `cli statusline-fragment` (ANSI)
- [ ] Hook subcommands for instrumented events
- [ ] Local outbox + offline tolerance

**Anti-cheat**
- [ ] Server-side delta validation
- [ ] Shadow-ban with query-layer filtering
- [ ] Audit log + admin anomaly queue

**Distribution**
- [ ] MIT or Apache-2.0 license
- [ ] `docker-compose.yml` for self-hosters
- [ ] README + DEPLOYMENT.md
- [ ] Donations link

**Foundation for v2**
- [ ] Schema-only support for raid/community-goal table
- [ ] Schema-only support for companion table

### Add After Validation (v1.x)

Once v1 is shipped and the loop is validated.

- [ ] Streak repair (XP-debt within 48h) — add if users churn at first streak loss
- [ ] Profile pages with deeper stats (not just showcase) — add when users start asking "what was my best week?"
- [ ] Achievement progress bars on profile — add when users complain that long-tail achievements feel opaque
- [ ] Daily quest variety expansion — add when quest pool feels stale
- [ ] Additional OAuth providers (Google, etc.) — add by user demand
- [ ] More themes / cosmetics — content release cadence
- [ ] Self-hoster admin tooling polish — add as forks emerge
- [ ] CLI `--json` everywhere for scripters
- [ ] Webhooks for users who want to wire alerts elsewhere

### Future Consideration (v2+)

Defer until product-market fit is clear.

- [ ] **Cooperative raids** — community-wide goals everyone chips into. Project-decided v2.
- [ ] **Companions** — persistent statusline creatures that grow over time. Project-decided v2.
- [ ] **Native mobile app** — only if usage justifies it; web is responsive.
- [ ] **DM / messaging** — only with a real moderation budget.
- [ ] **Leaderboard seasons with cosmetic rewards** — the "season XX winner" cosmetic class, only if seasonal engagement validates.
- [ ] **AI-assisted personalization** — only if rule-based personalization plateaus and infra cost is justified.
- [ ] **Public API for third-party integrations** — only after schema is stable and we've earned the right to commit to it.
- [ ] **Rich activity feed (granular)** — only if the friend feed (table stakes) drives clear engagement.

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Email/password + GitHub OAuth + handle claim | HIGH | LOW | P1 |
| Browser-mediated CLI device pairing | HIGH | LOW (Better Auth plugin) | P1 |
| Public profile page | HIGH | MEDIUM | P1 |
| 5 daily quests with per-user local-day reset | HIGH | HIGH | P1 |
| XP system + levels + visible attribution | HIGH | LOW | P1 |
| Achievement catalog + cosmetic unlock | HIGH | MEDIUM | P1 |
| Theme system + animated glyphs | HIGH | MEDIUM | P1 |
| 4 leaderboards (weekly + monthly + all-time, global + friends) | HIGH | HIGH | P1 |
| Streak + streak freeze | HIGH | LOW | P1 |
| Follow graph + profile comments + kudos | HIGH | MEDIUM | P1 |
| Friend feed | MEDIUM | MEDIUM | P1 |
| Helper module CLI (pair / stats / fragment / hooks / outbox) | HIGH | HIGH | P1 |
| Server-side delta validation + shadow-ban | HIGH | MEDIUM | P1 |
| Self-host docker-compose | MEDIUM | LOW | P1 |
| Streak repair | MEDIUM | LOW | P2 |
| Comment auto-moderation (link filter, profanity wordlist) | MEDIUM | LOW | P2 |
| Achievement progress bars | MEDIUM | LOW | P2 |
| More themes / glyphs (content) | MEDIUM | LOW | P2 |
| Webhooks | LOW | MEDIUM | P3 |
| Raids | HIGH | HIGH | P3 (v2) |
| Companions | HIGH | HIGH | P3 (v2) |
| DMs | LOW | HIGH (moderation cost) | P3 (likely never) |

**Priority key:**
- P1: Must have for v1 launch
- P2: Should have, add as soon as launch is stable
- P3: Future; defer until validated demand

---

## Competitor Feature Analysis

| Feature | Duolingo | GitHub Achievements | Strava | Stack Overflow | Habitica | Our Approach |
|---------|----------|---------------------|--------|----------------|----------|--------------|
| Daily streak | Yes — with freezes (21% churn reduction) | Removed (was harmful) | Yes — implicit (active days) | No | No (per-task) | **Yes, with freezes from day one.** |
| Quests / dailies | Yes (DAU +25%) | No | Sponsored challenges | No | Core mechanic | **Yes, 3 global + 2 personalized; no rerolls.** |
| Achievements | Yes (badges) | Yes (visible + tiered) | Yes (KOM/QOM, PB) | Yes (badges + reputation) | Yes | **Yes, visible + ~30% hidden; tied to cosmetics.** |
| XP / levels | Yes (XP) | No (just badges) | Implicit (totals) | Reputation (functional levels) | Yes (HP/MP/XP RPG-style) | **Yes, ~10% exponential curve, level cap 99.** |
| Leaderboards | Weekly leagues only | None | Per-segment, friends + global, weekly + all-time | Implicit (rep) | None public | **4 boards × 3 windows × {global, friends}.** |
| Cosmetics | Streak shop (paid + free) | Just badges | Trophies | Nothing visual | Heavy (gear, pets) | **Achievement-bound only. No shop.** |
| Social hub | Friends + leagues | Profile + followers | Followers + clubs + activity feed | Reputation + flair | Parties + guilds | **Real handles, asymmetric follow, profile comments, friend feed, kudos.** |
| Profile customization | Limited | Pinned repos + bento | Trophy case | Reputation + badges | Avatar + gear | **Bento-style showcase + active theme.** |
| Anti-cheat | Server-side validation | None visible | Flagged segments + manual review | Vote-rate-limit + community flag | Light | **Delta validation + shadow-ban + admin queue.** |
| Notifications | Aggressive (criticized) | Light (opt-in) | Activity feed only | Email digests (opt-in) | Configurable | **Opt-in, default-off, web-only.** |
| Visual identity | Owl + green gradient | Octocat + monochrome | Orange + minimal | Beige + serif | Pixel-fantasy RPG | **Retro arcade across web + CLI (8-bit palette + Press Start 2P + ANSI).** |
| Open source | No | No | No | No | Yes | **Yes — MIT/Apache, self-hostable.** |
| Mobile native | Yes (primary) | Yes | Yes | Web-first | Yes | **No — web-responsive only in v1.** |
| DMs | No | No | Yes (limited) | Comments only | Party chat | **No — profile comments only.** |
| Random drops / loot | Limited (chests) | No | No | No | Quest drops | **No — explicitly rejected.** |
| Reverse leaderboards / shame | No | No | No | No | No | **No — explicitly rejected.** |

**Key takeaways from prior art:**
- Duolingo proves daily quests + streak freezes are massive engagement levers when done humanely.
- GitHub teaches that streaks-as-public-shame are harmful; private/aggregate framing is safer.
- Strava teaches that segmented (friends + local) leaderboards beat global ones for motivation.
- Stack Overflow teaches that rewarding quality (not quantity) is essential to avoid spam-farming behavior.
- Habitica teaches that timezones + cron-per-user are non-negotiable, and that user-generated content is a moderation trap.

---

## Sources

**Prior art — gamification design:**
- [Duolingo — Streak System Detailed Breakdown & Design (Premjit Singha, Medium)](https://medium.com/@salamprem49/duolingo-streak-system-detailed-breakdown-design-flow-886f591c953f) — MEDIUM
- [Duolingo Gamification Strategy: A Full Case Study 2026 (Trophy)](https://trophy.so/blog/duolingo-gamification-case-study) — MEDIUM
- [How we protect learner streaks from site issues (Duolingo blog)](https://blog.duolingo.com/protecting-streaks-from-site-issues/) — HIGH
- [Habitica Wiki — Custom Day Start / Cron / Quests / FAQ](https://habitica.fandom.com/wiki/Custom_Day_Start) — HIGH
- [Habitica issue #5919: Dailies reset at wrong time](https://github.com/HabitRPG/habitica/issues/5919) — HIGH (primary source)
- [Stack Overflow gamification badge research (First Monday)](https://firstmonday.org/ojs/index.php/fm/article/view/7299/6301) — HIGH (peer-reviewed)
- [The Gamification (Coding Horror / Jeff Atwood)](https://blog.codinghorror.com/the-gamification/) — HIGH (Stack Overflow co-founder)
- [How Strava Uses Segmented Leaderboards to Drive Engagement (Trophy)](https://trophy.so/blog/how-strava-uses-segmented-leaderboards-to-drive-engagement) — MEDIUM
- [How Strava Uses Gamification to Improve Retention (Trophy)](https://trophy.so/blog/strava-gamification-case-study) — MEDIUM
- [RuneScape Experience formula (OSRS Wiki)](https://oldschool.runescape.wiki/w/Experience) — HIGH
- [GitHub Achievements: All You Need To Know (community discussion)](https://github.com/orgs/community/discussions/176080) — MEDIUM
- [Manage visibility settings for private contributions and achievements (GitHub Docs)](https://docs.github.com/en/account-and-profile/how-tos/contribution-settings/manage-visibility-settings-for-private-contributions-and-achievements) — HIGH

**Anti-features and dark patterns:**
- [GitHub contribution graph can be harmful (Hacker News thread referencing Erik Romijn)](https://news.ycombinator.com/item?id=11404482) — MEDIUM (community)
- [Don't break the chain: why we'll miss GitHub streaks (freeCodeCamp)](https://www.freecodecamp.org/news/dont-break-the-chain-why-github-s-streaks-will-be-sorely-missed-by-many-4fff90bc2a38/) — MEDIUM (mixed view)
- [Productivity App Gamification That Doesn't Backfire (Trophy)](https://trophy.so/blog/productivity-app-gamification-doesnt-backfire) — MEDIUM
- [The Dark Side of Karma & Unicorns (Digital Project Manager)](https://thedigitalprojectmanager.com/productivity/gamification-project-management-doesnt-work/) — MEDIUM
- [A Game of Dark Patterns: Designing Healthy, Highly-Engaging Mobile Games (ACM)](https://dl.acm.org/doi/fullHtml/10.1145/3491101.3519837) — HIGH (peer-reviewed)
- [Exploring the Darkness of Gamification (DiVA / academic PDF)](https://www.diva-portal.org/smash/get/diva2:1518853/FULLTEXT01.pdf) — HIGH (peer-reviewed)

**Anti-cheat:**
- [TrueAchievements Cheat Policy](https://www.trueachievements.com/cheatpolicy.aspx) — MEDIUM
- [Megabonk Verified vs Legit Leaderboard](https://megabonk.org/leaderboard/verified) — MEDIUM
- [PSNProfiles Leaderboard Rules & Disputes](https://psnprofiles.com/guide/18277-psnprofiles-leaderboard-rules-disputes) — MEDIUM
- [Call of Duty Security and Enforcement Policy](https://support.activision.com/articles/call-of-duty-security-and-enforcement-policy) — HIGH

**Leaderboard system design:**
- [Redis Sorted Sets leaderboard tutorial (Redis docs)](https://redis.io/docs/latest/develop/use-cases/leaderboard/nodejs/) — HIGH (official)
- [System Design of a Real-Time Gaming Leaderboard (AlgoMaster)](https://blog.algomaster.io/p/design-real-time-gaming-leaderboard) — MEDIUM
- [Leaderboard Design: The Complete Guide (Yu-kai Chou)](https://yukaichou.com/gamification-analysis/leaderboard-design-definitive-guide-octalysis/) — MEDIUM

**Social hub patterns:**
- [Friends versus Followers: Twitter's elegant design (Andrew Chen)](https://andrewchen.com/friends-versus-followers-twitters-elegant-design-for-grouping-contacts/) — MEDIUM
- [Twitch Chat Moderation Best Practices](https://help.twitch.tv/s/article/setting-up-moderation-for-your-twitch-channel?language=en_US) — HIGH (official)
- [Bento Grid pattern (uxgirl)](https://uxgirl.com/blog/beyond-boxes-elevating-design-with-bento-grid-patterns) — MEDIUM
- [Beyond Boxes: Bento Grid Patterns (BentoGrids.com)](https://bentogrids.com/) — LOW (showcase)

**Retro arcade / terminal animation:**
- [Press Start 2P (Google Fonts)](https://fonts.google.com/specimen/Press%2BStart%2B2P) — HIGH (official)
- [From pixels to characters: GitHub Copilot CLI's animated ASCII banner (GitHub Blog)](https://github.blog/engineering/from-pixels-to-characters-the-engineering-behind-github-copilot-clis-animated-ascii-banner/) — HIGH (engineering source)
- [Reverse Engineering Claude's ASCII Spinner Animation (Kyle Martinez)](https://medium.com/@kyletmartinez/reverse-engineering-claudes-ascii-spinner-animation-eec2804626e0) — MEDIUM
- [ora vs nanospinner vs cli-spinners 2026 (PkgPulse)](https://www.pkgpulse.com/guides/ora-vs-nanospinner-vs-cli-spinners-terminal-spinners-2026) — MEDIUM
- [NES.css framework](https://nostalgic-css.github.io/NES.css/) — HIGH (official)

**Difficulty / personalization:**
- [Dynamic game difficulty balancing (Wikipedia)](https://en.wikipedia.org/wiki/Dynamic_game_difficulty_balancing) — MEDIUM
- [Exploring Dynamic Difficulty Adjustment Methods for Video Games (MDPI)](https://www.mdpi.com/2813-2084/3/2/12) — HIGH (peer-reviewed)

---
*Feature research for: OSS gamification service for Claude Code (web app + backend + statusline-agnostic helper module)*
*Researched: 2026-05-08*

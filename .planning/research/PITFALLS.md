# Pitfalls Research

**Domain:** OSS gamification service for Claude Code (web app + backend + helper module)
**Researched:** 2026-05-08
**Confidence:** HIGH on gamification psychology, OAuth/device-flow security, OSS maintainer dynamics; HIGH on streak/timezone math; MEDIUM on Claude Code hook stability (rapidly evolving target); HIGH on social moderation surface

## Reading Guide

Pitfalls are sorted by severity:

- **Critical Pitfalls** — will cause user harm, project death, security incident, or unfixable architectural lock-in. These MUST be designed against from day one. If a phase touches the related surface, the phase plan must explicitly address the pitfall.
- **Moderate Pitfalls** — will cause measurable harm to engagement, trust, or maintainer sanity but are recoverable. Address during the relevant phase; don't leave to a future "polish" pass.
- **Minor Pitfalls** — annoyances and quality-of-life issues. Document and revisit at milestone boundaries.

Each pitfall is tagged with the phase that owns its prevention. "Cross-cutting" means the pitfall doesn't sit in any single phase and must be carried as a standing constraint across the project.

---

## Critical Pitfalls

### Pitfall 1: Overjustification — extrinsic rewards killing the intrinsic joy of using Claude Code

**What goes wrong:**
Users who already enjoy using Claude Code start checking XP/quests/streaks instead of working. Within months, the work feels hollow without the gamified scoreboard, and many users report higher anxiety, reduced creativity, and lower long-term engagement than before they joined. A subset quits both Claude Code and the gamification service simultaneously, blaming the service.

**Why it happens:**
Self-determination theory and 50 years of overjustification-effect research show that contingent extrinsic rewards (XP, badges) layered on top of an already intrinsically rewarding activity (programming, problem-solving) reliably erode the intrinsic motivation. The activity gets re-encoded in the user's brain as "the thing I do for points." When the points stop feeling meaningful (saturation, leaderboard plateau, achievement exhaustion), the underlying motivation is also gone.

**How to avoid:**
- Design rewards as **informational feedback**, not contingent payment. "You used context efficiently today" preserves intrinsic motivation; "+50 XP for using context efficiently" can damage it. Frame XP as a record of what the user did, not a wage for doing it.
- Prefer **unexpected rewards** over expected ones. Achievement unlocks should mostly be discovered, not chased. Hidden/secret achievements outperform visible checklists for motivation preservation.
- Never gamify the **act of using Claude Code at all**. Quests must be about *how* you used it (efficiency, streaks of green-zone context, plugin diversity) — never raw "use Claude Code 4 hours today."
- Provide a **first-class opt-out from quests/leaderboards** that still lets users keep cosmetics. Some users will self-detect overjustification and need an exit ramp that doesn't lose their identity/badges.
- Add a **"vacation mode"** that pauses streaks and quests without resetting them. Removes the felt obligation.

**Warning signs:**
- Support tickets / community posts saying "I used to enjoy Claude Code, now I just chase XP"
- Activity drops sharply after a user fails a streak (loss aversion overshooting)
- Users describe quests as "homework" or "chores" in feedback
- Time-to-quit cluster around the same point in the progression curve (suggests reward saturation)

**Phase to address:**
Phase that designs the quest/XP/achievement reward semantics (likely the Quests / Achievements design phase). Cross-cutting constraint thereafter — every new mechanic must be evaluated for overjustification risk.

**Prior art:** [Overjustification effect (Wikipedia)](https://en.wikipedia.org/wiki/Overjustification_effect), [Yu-kai Chou — Motivation Traps in Reward-Based Gamification](https://yukaichou.com/gamification-study/motivation-traps-rewardbased-gamification-campaigns/), [How Rewards Kill Creativity (Yu-kai Chou)](https://yukaichou.com/gamification-study/rewards-kill-creativity/), [Negative Effects of Extrinsic Rewards on Intrinsic Motivation (USC CEO)](https://ceo.usc.edu/wp-content/uploads/2013/02/2013-05-G13-05-624-Negative_Effects_of_Extrinsic_Rewards.pdf)

---

### Pitfall 2: Goodhart's Law on raw-activity leaderboard — "raw token usage" stops measuring engagement and starts measuring spam

**What goes wrong:**
Top of the raw-activity leaderboard becomes dominated by users who paste 50KB of garbage into prompts, run trivial loops to inflate token counts, or script /clear-and-spam patterns. Real heavy users feel cheated; new users see the top names and conclude the leaderboard is fake. The whole social hub loses credibility within weeks of launch.

**Why it happens:**
Goodhart's Law: "when a measure becomes a target, it ceases to be a good measure." Token usage was a *proxy* for engagement; once it's the rank, it stops correlating with engagement and starts correlating with whoever is willing to game it. Public leaderboards with real handles are an unusually strong incentive to game — there is reputational payoff, not just a number.

**How to avoid:**
- **Don't rank a single raw input.** Composite scores resist gaming better. Even "raw activity" should be a sanity-checked composite (tokens × distinct sessions × days-active × non-trivial-prompt-share).
- **Cap per-window contribution.** A user gains at most N points per hour; this caps the upside of brute-forcing.
- **Detect & reject "trivial" tokens server-side** with simple heuristics (high entropy on prompt body, prompt length distribution, edit distance between adjacent prompts) before they count toward rank.
- **Rotate ranking algorithms.** Periodically tweak the formula so users can't lock in a stable exploit. Document publicly — "we adjust the formula quarterly to keep it honest" is itself a deterrent.
- **Have multiple leaderboards** (already the plan: raw / streak / XP / efficiency). The "raw" board can be lowest-status; users who care about being respected will play efficiency. Document the relative status hierarchy in copy.
- **Show "this looks suspicious" badges next to inflated stats** rather than silent shadowbanning, until evidence is conclusive — preserves trust.

**Warning signs:**
- Top-N users have token counts that are statistical outliers (>3σ from the mean of the next decile)
- Sessions with thousands of near-identical prompts
- New accounts climbing to top-100 within their first 7 days
- Community discussions accusing top users of cheating (this is the canary — when it starts, the leaderboard's credibility is already half gone)

**Phase to address:**
Leaderboards phase + anti-cheat phase. Score formula and gaming-resistance must be designed together, not bolted on.

**Prior art:** [Goodhart's law and gamification of metrics (de Vroome)](https://tdevroome.medium.com/goodharts-law-and-gamification-of-metrics-ff697ac86575), [Gaming the System: Goodhart's Law in AI Leaderboard Controversy (Collinear)](https://blog.collinear.ai/p/gaming-the-system-goodharts-law-exemplified-in-ai-leaderboard-controversy), [The Leaderboard Illusion (Kejriwal)](https://aiscientist.substack.com/p/musing-118-the-leaderboard-illusion)

---

### Pitfall 3: Streak anxiety — the Duolingo/Habitica trap

**What goes wrong:**
Users who started for fun become anxious about losing their streak. They open Claude Code at 11:55 PM purely to "save the streak" rather than do real work. When the streak eventually breaks (vacation, illness, life), a substantial fraction quit the app entirely rather than restart from zero. Habitica's documented "burnout by month 3" pattern reproduces here.

**Why it happens:**
Streaks weaponize loss aversion: keeping a streak feels neutral, losing it feels like a real loss. Over weeks the cumulative pressure builds. Once broken, the sunk-cost identity ("I'm someone with a 200-day streak") collapses, and there's no soft landing.

**How to avoid:**
- **Streak freezes by default** — accumulate one freeze per N days of activity, capped at a small ceiling. Eliminates anxiety from one bad day.
- **Vacation mode** — explicit pause that doesn't break the streak. Built-in escape valve.
- **Grace window across midnight** — count activity within 3-6 hours after local-day-rollover for the previous day. Avoids "I worked till 12:05 AM and lost my streak" complaints.
- **Don't surface streaks aggressively.** Available on profile, not pushed in notifications. The user opts into seeing it.
- **Streak recovery / partial credit on break.** A broken 100-day streak reduces to a "broken streak record" badge users can keep; the new streak starts at 1 but the previous high is honored. Removes the "all is lost" feeling.
- **Cap meaningful streak rewards at a realistic level (~30 days).** Don't escalate forever — the cosmetic at day 365 trains pathological behavior. Past 30 days, streaks are their own reward.
- **Never use guilt-based notifications** ("Duo is sad", "you broke your streak", etc.). Notifications should be neutral or absent.

**Warning signs:**
- Activity spikes in the last 30 minutes of users' local day (sign they're padding to save streak, not working)
- Users with very long streaks who stop suddenly (broken streak → quit pattern)
- Support tickets about "anxiety" or "feels like a job"
- Community posts copying the Duolingo "weaponized against me" critique

**Phase to address:**
Quests/streaks phase. Cross-cutting check on every notification and quest design afterwards.

**Prior art:** [Streak Creep — perils of too much gamification (Decision Lab)](https://thedecisionlab.com/insights/consumer-insights/streak-creep-the-perils-of-too-much-gamification), [Habitica Burnout (Habitica Wiki)](https://habitica.fandom.com/wiki/Burnout), [The Psychology of Streaks (Trophy)](https://trophy.so/blog/the-psychology-of-streaks-how-sylvi-weaponized-duolingos-best-feature-against-them), [Streak Design without Burnout (Yu-kai Chou)](https://yukaichou.com/gamification-analysis/streak-design-gamification-motivation-burnout/)

---

### Pitfall 4: OAuth Device Code phishing on the pairing flow

**What goes wrong:**
Attacker sends a target a "Hey check this out — claim this rare badge by pairing here" message. The link is the *real* legitimate `verification_uri_complete` from the attacker's freshly initiated `device.code` request. The victim clicks, sees the legitimate site, logs in, and approves. Attacker now has a valid access token bound to the victim's account. MFA does not protect against this — the victim performs the MFA step *for* the attacker. This is the same Storm-2372 attack pattern that hit Microsoft 365 in 2024-2025.

**Why it happens:**
Device Authorization Grant (RFC 8628) intentionally separates the device requesting access from the user authorizing it. That property — "any device can ask, the user approves on a different device" — is the same property that makes phishing possible. Anyone can mint a valid `verification_uri_complete` and convince the victim to click it.

**How to avoid:**
- **Always require user_code re-entry on the verification page**, even if `verification_uri_complete` was used. Show the code, ask "is this the code your terminal is showing?" The victim's terminal will show a code that doesn't match.
- **Display rich device context** at the approval step: IP, geolocation, user-agent claim, timestamp. "A device in [country] is requesting access" — gives the user a chance to detect mismatch.
- **Short user_code lifetime** — RFC 8628 §5.2 explicitly recommends short. 10 minutes max; 5 minutes preferred.
- **Rate-limit `device.code` issuance per IP and per account.** An attacker mass-minting codes is the precursor to phishing campaigns.
- **Bind tokens to a stable client identifier** (per-install UUID generated by the CLI). On suspicious activity, revoke by client ID rather than by user.
- **Show pairing history on the user's profile + email on each new pairing.** Lets the user notice "I never paired in Brazil yesterday."
- **Add a slow-cook step on first pair** — first pairing, send an email with a confirm link that must be clicked within N hours, otherwise revoke. Friction-trade for the most dangerous moment.
- **Educate in the CLI output:** `cli pair` should print "If someone sent you this command, do not run it. Only run pair when you initiated it yourself."

**Warning signs:**
- Spike in `device.code` requests without follow-through pairing
- Users reporting "I got a strange link"
- Pairings approved from IPs/regions that don't match the user's typical pattern
- Tokens being used from a different network within minutes of pairing

**Phase to address:**
Auth / device-pairing phase. Must ship with phishing mitigations from day one — this is not a "harden later" problem.

**Prior art:** [OAuth Device Code Phishing M365 (CSA Labs)](https://labs.cloudsecurityalliance.org/research/csa-research-note-oauth-device-code-phishing-m365-20260325-c/), [OAuth's Device Code Flow Abused in Phishing Attacks (Secureworks)](https://www.secureworks.com/blog/oauths-device-code-flow-abused-in-phishing-attacks), [Introducing GitHub Device Code Phishing (Praetorian)](https://www.praetorian.com/blog/introducing-github-device-code-phishing/), [RFC 8628 §5](https://www.rfc-editor.org/rfc/rfc8628.html#section-5), [RFC 9700 OAuth 2.0 Security BCP](https://datatracker.ietf.org/doc/rfc9700/)

---

### Pitfall 5: Helper module crashes/latency hurting the user's actual Claude Code session

**What goes wrong:**
A bug in the helper (uncaught promise rejection, slow disk write, stuck network call, dependency that requires a native build that fails on Windows ARM) causes a hook to time out or throw. Claude Code's session pauses, errors, or just feels sluggish. The user uninstalls the gamification service immediately and writes a public post. One bad release wipes out months of trust-building.

**Why it happens:**
- Hook handlers run synchronously inline with the user's session.
- Network I/O in a hook = unbounded latency.
- Disk I/O on contended disks (Windows AV scanning) is also unbounded.
- Native deps (e.g. `better-sqlite3`) need platform-specific binaries; postinstall failures are common.
- Version skew between helper and backend can cause unhandled response shapes.

**How to avoid:**
- **Hooks must be fire-and-forget on a strict deadline.** Internal budget: 50 ms hard, 20 ms soft. Anything that can't complete enqueues a record and returns immediately.
- **Never make a network call inline in a hook.** Append to a local outbox (SQLite/JSONL); a separate flusher process syncs it.
- **Wrap every hook entry point in a top-level try/catch that always exits 0** with an empty response. A broken hook should *never* break Claude Code.
- **Per-hook timeout self-killer.** If our own logic exceeds the budget, log it, drop the event, return.
- **Postinstall fallback path.** If a native dep fails to build (ARM Windows is the canonical landmine), fall back to a pure-JS implementation. Prefer pure-JS by default, native as opt-in optimization.
- **Synthetic monitoring** — automated test environment that runs the helper end-to-end on Linux/macOS/Windows + Node 20/22 LTS lines, tripped on every PR.
- **Telemetry on hook duration percentiles** (p50/p95/p99) reported back to backend; alert on regression.
- **Kill switch:** the helper checks a remote feature flag on startup; backend can disable specific hook types instantly without users updating.
- **Statusline fragment reads only from local cache.** Never network. Refreshed opportunistically by background flusher.

**Warning signs:**
- p95 hook duration creeping up release-over-release
- Issues mentioning "Claude Code feels slower since I installed this"
- Crash reports correlated with specific Node versions or platforms
- Rising uninstall rate after a release

**Phase to address:**
Helper module / CLI phase. Cross-cutting non-negotiable — every release after must verify hook latency budget on every supported platform.

**Prior art:** [Claude Code Hooks reference](https://code.claude.com/docs/en/hooks), [Hook Failures (DeepWiki)](https://deepwiki.com/affaan-m/everything-claude-code/16.2-hook-failures), [Plugin hooks not updated when plugin version changes #18517](https://github.com/anthropics/claude-code/issues/18517), [Hooks not loading from settings.json #11544](https://github.com/anthropics/claude-code/issues/11544)

---

### Pitfall 6: OAuth token leakage via reading `~/.claude/.credentials.json`

**What goes wrong:**
The helper reads the user's Anthropic OAuth token from `~/.claude/.credentials.json` (to call the usage API). That token gets logged by mistake, sent to our backend in a debug payload, included in a crash report, written to a world-readable temp file, or exfiltrated by a malicious dependency in our helper's npm tree. The user's *Anthropic* account is now compromised — far worse than just our service being compromised.

**Why it happens:**
- Tokens that exist in process memory tend to leak into logs, error stacks, telemetry, and crash reports unless explicitly redacted.
- Supply chain risk: any transitive npm dep can read the file once we've taught users our helper does.
- Confused-deputy: the helper has *more* access than the backend should have.

**How to avoid:**
- **Never send the Anthropic OAuth token to our backend, ever.** Helper calls `api.anthropic.com` directly with that token and posts the *result* (the usage numbers) to our backend.
- **Read the credentials file with explicit path validation, narrowest file mode** (refuse to proceed if file is world-readable; warn the user).
- **Never log the token.** Redaction filter at the logger level (pino transport). Audit every log statement near token handling.
- **Never include credentials, env, or stack traces with arguments in crash reports.**
- **Pin and audit dependencies.** Use `pnpm audit` + Snyk/`socket.dev` checks in CI. Prefer zero-dep libraries for anything that touches the credential.
- **No postinstall scripts in our deps where avoidable.** Postinstall is the canonical supply-chain attack surface.
- **Document explicitly** in README and helper output: "This helper reads your Anthropic OAuth token to call api.anthropic.com directly. It does not transmit the token elsewhere." Build trust by being loud about what we touch.
- **Treat the credentials file as read-only.** Never write to it. Never propose to write to it.
- **Defensive: detect token format changes** and bail out cleanly if Anthropic changes the storage shape, rather than guess and leak.

**Warning signs:**
- Any log line that contains a string starting with `sk-ant-` or similar token prefix
- A new transitive dep appearing in the helper's tree without review
- Users reporting suspicious activity on their Anthropic account
- Our error reporting showing tokens in stack traces (should never happen)

**Phase to address:**
Helper module phase. Cross-cutting after that — any feature that touches the credential needs explicit threat-model review.

**Prior art:** [OAuth best practices RFC 9700 (WorkOS)](https://workos.com/blog/oauth-best-practices), [Best practices for mitigating compromised OAuth tokens (Google Cloud)](https://cloud.google.com/architecture/bps-for-mitigating-gcloud-oauth-tokens), [Testing for OAuth Weaknesses (OWASP)](https://owasp.org/www-project-web-security-testing-guide/latest/4-Web_Application_Security_Testing/05-Authorization_Testing/05-Testing_for_OAuth_Weaknesses)

---

### Pitfall 7: Maintainer burnout / single-maintainer abandonment

**What goes wrong:**
Project ships, gets traction, the maintainer (you) is now answering issues, moderating reports, fixing leaderboard cheating, hosting costs are climbing, donations cover 5%, and one Saturday you walk away. Users are mid-progress when the public instance goes dark. 60% of OSS maintainers work unpaid; 44% cite burnout as the reason they leave; the median monthly sponsorship is around $50.

**Why it happens:**
This project has unusually high *non-code* burden for an OSS project: moderation surface (comments, reports, harassment), abuse surface (handle squatting, brigading), trust-and-safety surface (anti-cheat appeals), hosting cost surface (token-using audience = high-engagement = expensive), legal surface (GDPR/DMCA/account recovery). All of that lands on one person.

**How to avoid:**
- **Build the moderation tools and the maintenance automation alongside the features**, not after. If reports take 3 minutes each instead of 30, you survive 10x longer. Treat moderation tooling as a Phase 1 deliverable, not a "later" task.
- **Cap the public instance.** Free hosted instance has a published cap (e.g. 5,000 active users). When it hits, signups go to a waitlist or to "self-host instructions." Pre-commit you to NOT scaling beyond what you can afford in time and money.
- **Self-host parity from day one.** Public instance and self-hosted use exact same Docker Compose. When you abandon, users have a path forward.
- **Deferred cosmetics that survive abandonment.** Cosmetics live in a static asset bundle the helper can ship locally. If the backend dies, badges still render.
- **Document a graceful shutdown plan publicly.** "If I ever step down, here's what happens: I will give 90 days notice, export all user data, and either transfer the public instance to a successor or shut it down with full data export." Trust-building via pre-commitment.
- **Recruit a second maintainer before you need one.** Single-maintainer projects are ticking time bombs (Booklore, XZ Utils precedent). At first 50 stars or first paid sponsor, start mentoring a co-maintainer.
- **Saying no is mandatory.** Out-of-scope list in PROJECT.md is your spine. Every "what about adding X" must be defaulted to no.
- **Donations channel from launch.** GitHub Sponsors + buy-me-a-coffee. Even if median is $50/mo, the symbolic effect of "this is supported" matters.
- **No on-call expectation.** Public README explicitly says: this is a hobby project, response time is best-effort, please self-host if you need SLAs.

**Warning signs:**
- Issue tracker > 1 page deep
- Discord/community pings outpacing your response time
- Any month where time-on-project exceeds time-on-paid-job
- Hosting cost rising faster than user count (sign of free-tier abuse)
- Internal monologue "I have to fix this tonight or users will be mad"

**Phase to address:**
Cross-cutting. Specifically: explicit shutdown plan in Phase 1 (project setup), moderation tooling in social hub phase, hosting cap in distribution phase.

**Prior art:** [Open source maintainers state of open (The Register)](https://theregister.com/AMP/2025/02/16/open_source_maintainers_state_of_open), [Single-maintainer open source ticking time bomb (XDA)](https://www.xda-developers.com/single-maintainer-open-source-ticking-time-bomb/), [Open Source Maintainer Burnout (RoamingPigs)](https://roamingpigs.com/field-manual/open-source-maintainer-burnout/), [Combating Open Source Maintainer Burnout with Automation (Dosu)](https://blog.dosu.dev/combating-open-source-maintainer-burnout-with-automation/), [Why I quit open source (Sapegin)](https://dev.to/sapegin/why-i-quit-open-source-1n2e)

---

### Pitfall 8: Public real-handle harassment and doxxing surface

**What goes wrong:**
Real handles + public profiles + comments + leaderboards + low-friction signup = a fully-loaded harassment platform. Within months you'll see: handle-impersonation (someone signs up as a popular streamer's handle to comment harassment "as them"), pile-on harassment in profile comments, doxxing attempts (linking handle to real identity from cross-referenced platforms), brigading the leaderboard (coordinated reporting to shadowban a target). One viral incident defines the project.

**Why it happens:**
Real handles maximize identity (good for engagement) but also maximize attack surface. Comments on public profiles are the most-abused primitive in social software (cf. every platform that has ever shipped them). Open signup means attackers create accounts for free.

**How to avoid:**
- **Reserved-handle list at signup.** Block or reserve obvious squatting targets: well-known Claude/Anthropic employees, popular dev influencers, common slurs and trademarks, "admin"/"staff"/"anthropic"/etc. Maintain a public list, accept reports.
- **Email verification + rate-limit signup per IP/email-domain.** Slows spam ring spinup.
- **Handle-change cooldown** (e.g. one rename per 90 days) so handles can't be hot-potatoed for impersonation.
- **Comments default off.** Profile comments require the profile owner to opt in. They can opt back out. They control who can comment (everyone / followers / mutuals / off).
- **No DMs in v1.** DMs are a moderation black hole. Out-of-scope.
- **Block, mute, and report** as table stakes. Block must be both directions (blocked user can't see blocker's profile).
- **Report queue with auto-actions for repeat offenders.** Reports that match strong heuristics (multiple targets in 24h, account < 7 days old, no profile data) auto-rate-limit the reported account pending human review.
- **Don't show full token counts on profile.** "5h: green / yellow / red" is enough. Raw numbers are a doxxing vector if cross-referenced with publicly-known billing tiers.
- **Don't expose real-time activity** ("active now", "last seen") — stalker-friendly. Use weekly buckets at most.
- **Audit log on profile actions** so users can see who viewed/reported them aggregated (gamesmanship vs. transparency tension; lean transparent).
- **Have a published Code of Conduct and a moderation appeal path.** Both protect users and protect you.
- **One-click full data export and account deletion** (also helps GDPR).

**Warning signs:**
- New accounts with zero activity but commenting on profiles
- Burst pattern: many reports against the same target in a short window
- Handles that are obvious impersonations (real-name look-alikes, zero-width-space tricks)
- Public posts about being harassed via the platform (you will see these before you see the reports)

**Phase to address:**
Social hub phase. Reserved-handle list and rate-limits in signup phase. Cross-cutting moderation tooling.

**Prior art:** [Doxxing Information (UCSD)](https://privacy.ucsd.edu/resources-guidance/doxxing/index.html), [Online Harassment: Assessing Harms and Remedies (Schoenebeck et al.)](https://journals.sagepub.com/doi/10.1177/20563051231157297), [Online Harassment Field Manual (PEN)](https://onlineharassmentfieldmanual.pen.org/protecting-information-from-doxing/), [Moderation Strategies in Open Source Software Projects (ACM CHI)](https://dl.acm.org/doi/10.1145/3610092)

---

### Pitfall 9: Claude Code hook-system breakage on upstream changes

**What goes wrong:**
Anthropic ships a Claude Code release that changes a hook event name, payload shape, settings schema, or removes/renames a hook entirely. Our helper silently stops capturing data, or worse, captures wrong data. Users notice their stats freeze; they blame us; some uninstall before we ship a fix. Anthropic owes us nothing on hook stability — these are first-party integration points and they will evolve.

**Why it happens:**
- Claude Code is rapidly iterating; hooks are still maturing (async hooks shipped Jan 2026, settings resilience improvements through 2025).
- We don't control the contract.
- Open issues like #18517 and #11544 show the hook system has rough edges *today*.

**How to avoid:**
- **Defensive parsing.** Every hook handler validates the input shape with Zod and tolerates unknown fields. Unknown fields are logged for diagnostic but never cause failure.
- **Schema-versioned event capture.** Store raw hook payload (shape-versioned) at the local-outbox layer, in addition to our parsed model. If a parsing assumption was wrong, we can re-derive without losing history.
- **Synthetic test against published Claude Code release channels.** CI installs latest Claude Code release and runs end-to-end hook capture on every backend release.
- **Feature-flag every hook**. Backend can disable a specific hook instantly across the fleet if a release breaks it. Helper polls flags on session start.
- **Multi-source corroboration where possible.** Cross-check hook-derived counts against the OAuth usage API at low frequency. Big deviation = hook break alert.
- **Subscribe to Claude Code changelog/release notes** as a CI-blocker — automated diff against last-tested version triggers a manual verification gate before we ship.
- **Don't depend on undocumented hook fields.** If it's not in the public docs, we don't read it (or we wrap a fragile reader behind a feature flag).
- **Communicate degraded mode.** If we detect a hook is broken, the dashboard shows "your stats may be incomplete due to a Claude Code update; we're investigating" — better than silent stale data.

**Warning signs:**
- Sudden drop in event volume across many users simultaneously (correlates with a Claude Code release)
- Specific hook event count going to zero
- Schema validation errors in our logs spiking
- Anthropic posting a changelog entry that touches hooks

**Phase to address:**
Helper module + hook capture phase. Cross-cutting maintenance burden afterwards.

**Prior art:** [Claude Code Hooks reference](https://code.claude.com/docs/en/hooks), [Claude Code Changelog 2026](https://claudefa.st/blog/guide/changelog), [Plugin hooks not updated when plugin version changes #18517](https://github.com/anthropics/claude-code/issues/18517), [Hooks not loading from settings.json #11544](https://github.com/anthropics/claude-code/issues/11544)

---

### Pitfall 10: Timezone, midnight cluster, and DST bugs in streaks/leaderboards

**What goes wrong:**
A user in Tokyo's "today" finishes when a user in California's "today" is just starting; if we use UTC midnight for daily resets, half the world resets in the middle of their day. DST transitions create 23/25-hour days that break naive day-arithmetic. Concurrent activity at midnight gets double-counted or miscounted. Result: user trust in the streak/leaderboard system collapses ("my streak broke at 9 PM??"). LeetCode and GitHub have publicly mishandled this exact class of bug.

**Why it happens:**
- Date math without explicit timezone handling is a 50-year-old footgun.
- DST rules vary by country and change unpredictably (e.g. recent EU/Mexico DST policy changes).
- "End of day" is a calendar concept, not a duration.
- Server-side cron at "00:00 UTC" does the wrong thing for everyone but UTC users.

**How to avoid:**
- **Store timestamps in UTC.** Always.
- **Store the user's IANA timezone on their profile** (e.g. `America/Los_Angeles`, never `PST` or `-08:00`). Use the OS-detected zone at signup, allow override. Update on each session-start so travelers don't break.
- **Evaluate streak/quest-day in the user's local timezone**, using a real timezone library (Temporal API once stable, otherwise Luxon or date-fns-tz). Never `setHours(0,0,0,0)` on a `Date` for "start of today."
- **Grace window across midnight.** Activity in the first 3-6 hours after local-midnight counts toward the previous day. Eliminates the "2-minutes-late lost streak" complaint and naturally absorbs DST 23-hour days.
- **Per-user reset, not global cron.** A worker job sweeps users whose local-day just rolled, instead of a single 00:00-UTC blast. Smooths load and prevents the global midnight thundering herd.
- **Idempotent day attribution.** Every user-event is attributed to exactly one user-local-day at write time, so concurrent writes near midnight can't double-count.
- **Test DST.** Unit tests that assert correct behavior on spring-forward and fall-back days for at least 3 representative timezones.
- **Show local-day rollover time on the streak UI.** "Your day rolls over at 12:00 AM Pacific" — sets expectations.

**Warning signs:**
- Users complaining about lost streaks within 24h of a DST transition (March/November)
- Backend load spikes at 00:00 UTC
- Inconsistent streak counts when comparing user's UI to admin DB query
- Test suite has zero tests with timezone or DST assertions

**Phase to address:**
Streaks/quests phase + leaderboards phase. Cross-cutting test-suite expectation thereafter.

**Prior art:** [Streak Timezone & DST Handling (Trophy)](https://trophy.so/blog/streak-timezone-dst-handling), [Handling Time Zones in Global Gamification Features (Trophy)](https://trophy.so/blog/handling-time-zones-gamification), [How to Build a Streaks Feature (Trophy)](https://trophy.so/blog/how-to-build-a-streaks-feature), [LeetCode streak broken due to incorrect day counting (#28204)](https://github.com/LeetCode-Feedback/LeetCode-Feedback/issues/28204), [GitHub contribution streak reset despite daily activity](https://github.com/orgs/community/discussions/172053)

---

### Pitfall 11: Localhost OAuth callback and CSRF on browser-mediated pairing

**What goes wrong:**
Even though we plan to use RFC 8628 device flow (no localhost callback needed), a tempting alternative pattern is "CLI opens browser to /callback?code=..., browser redirects to http://localhost:PORT/callback." That pattern is loaded with footguns: DNS rebinding can let a malicious site reach the localhost server, CSRF can let a remote page post to it, port collisions cause failures, antivirus may block it. Even with RFC 8628, careless implementation can backslide into these patterns.

**Why it happens:**
- Localhost servers are mistakenly considered "isolated"; they aren't (DNS rebinding bypasses Same-Origin).
- 0.0.0.0 vs 127.0.0.1 confusion exposes the server to LAN.
- Missing CSRF state parameter is one of the most common OAuth implementation bugs.
- Lack of PKCE on public clients.

**How to avoid:**
- **Stick to RFC 8628 device flow.** Better Auth's plugin handles it; don't reinvent. No localhost listener required.
- **If a localhost listener is ever added (don't), bind only to `127.0.0.1`** — never `0.0.0.0` or `::`. Verify with a startup self-test.
- **Always use the OAuth `state` parameter** generated by the CLI, validated server-side, even on device flow.
- **Always use PKCE** (S256) — Better Auth supports it. Public clients (the CLI) cannot keep secrets, so PKCE is mandatory.
- **Single-use codes with short TTL.** Code can be redeemed once. After redemption, server invalidates so a captured code can't be replayed.
- **Bind device-code to client identity claim** (per-install UUID + platform fingerprint). Server checks at redemption.
- **Clear error UX on expired codes.** "This code expired. Run `cli pair` again." — far better than a silent hang.

**Warning signs:**
- Anyone proposing to add a "just real quick" localhost listener for dev convenience
- Missing PKCE in the device flow plugin config
- `state` parameter not validated end-to-end
- Code reuse not blocked at the server

**Phase to address:**
Auth / device-pairing phase.

**Prior art:** [Localhost dangers: CORS and DNS rebinding (GitHub Blog)](https://github.blog/security/application-security/localhost-dangers-cors-and-dns-rebinding/), [Best practices for CLI authentication (WorkOS)](https://workos.com/guide/best-practices-for-cli-authentication-a-technical-guide), [RFC 9700 OAuth Security BCP](https://datatracker.ietf.org/doc/rfc9700/), [Cross Site Request Forgery and OAuth2 (Spring)](https://spring.io/blog/2011/11/30/cross-site-request-forgery-and-oauth2/)

---

## Moderate Pitfalls

### Pitfall 12: Bottom-of-leaderboard demotivation drives the median user away

**What goes wrong:**
Public leaderboard with absolute ranks: the top 1% feels great, the bottom 50% feels worse than they did before signing up. Median user sees their rank, internalizes "I'm bad at Claude Code," and disengages or quits. Net engagement drop, even though the leaderboard "works" as a competitive driver for the top.

**Why it happens:**
Research is consistent: low ranks demotivate at higher rates than high ranks motivate. Gap-to-top feels insurmountable; people quit rather than try. This effect is strongest for users who weren't naturally competitive to begin with.

**How to avoid:**
- **Default leaderboard view = relative cohort, not global.** Show "your rank vs. people in your same activity tier" — bridgeable gap.
- **Local-cohort leaderboards** (region, friend group, similar-tier band) instead of one global meatgrinder.
- **Don't show rank below position N** ("You're outside the top 1000" is better than "You're #18472 of 50000"). Soft floor.
- **Multiple leaderboards by playstyle** (already planned). Users find the board where they shine.
- **Personal-best framing** as the primary surfacing; absolute rank is a secondary surface.
- **Hide the leaderboard for new users their first week.** Let them build identity before introducing comparison.

**Warning signs:**
- Activity drop after first leaderboard view
- Users in the 50-90 percentile band having higher quit rate than 0-50
- Community posts: "I'm just gonna delete this, I'll never catch the top"

**Phase to address:**
Leaderboards phase.

**Prior art:** [Death of the Leaderboard (Kaizo)](https://medium.com/@kaizo/death-of-the-leaderboard-why-ranking-is-whats-wrong-in-workplace-gamification-7af68c408b60), [Psychological Impact of Leaderboards (CLUELabs)](https://cluelabs.com/blog/the-psychological-impact-of-leaderboards-on-learning-professionals/), [How Ranking Becomes Demotivating (Inside Higher Ed)](https://www.insidehighered.com/blogs/just-visiting/how-ranking-becomes-demotivating), [Leaderboard Fatigue (Spinify)](https://spinify.com/blog/leaderboard-fatigue-is-real-heres-how-to-fix-it/)

---

### Pitfall 13: Quest fatigue from rigid daily quotas

**What goes wrong:**
5 quests every day, every day, with the same rotation pattern, the same shape. After a month, quests feel like compulsory homework. Users skip them, then feel guilty, then quit. Same-set-for-everyone-today ("the global tier-3 today is X") creates the worst version of this — it has to be hittable for everyone, so it becomes blandly generic.

**Why it happens:**
Daily quotas trigger compulsion (Habitica reports this consistently). Variety isn't enough; the *quota structure* is the problem.

**How to avoid:**
- **Quests can be skipped without penalty.** Skipping a quest doesn't hurt anything; only completion rewards. Removes pressure.
- **Personalized quests should be challenging but achievable in normal use.** Never require "extra" Claude Code time the user wouldn't have spent anyway.
- **Variable quest count per day.** Some days have 5, some have 2, some have 7. Less predictable, less compulsive.
- **Allow quest re-rolls.** User can dismiss a quest they don't like, get a different one. Once per day cap.
- **Don't notify aggressively about uncompleted quests.** Show on dashboard, never push.
- **Cap quest XP contribution** so a missed day doesn't create a perceived deficit on the leaderboard.

**Warning signs:**
- Quest completion rate trending down month-over-month for cohorts
- Community posts about "feeling forced"
- Skip rate spikes on specific quest types (signal that those are bad quests, not bad users)

**Phase to address:**
Quests phase.

**Prior art:** [Habitica Burnout (Wiki)](https://habitica.fandom.com/wiki/Burnout), [Streak Creep (Decision Lab)](https://thedecisionlab.com/insights/consumer-insights/streak-creep-the-perils-of-too-much-gamification), [Tired of Habitica? (The Canary)](https://www.thecanary.co/discovery/lifestyle/2026/03/30/tired-of-habitica-try-these-3-cheaper-and-more-engaging-habitica-alternatives/)

---

### Pitfall 14: Anti-cheat false positives destroy trust

**What goes wrong:**
A legitimate power-user with genuinely high token usage gets flagged as suspicious. Stats are silently down-weighted. They notice their rank went down despite working harder. They post about it, prove they're legitimate, and the community concludes "the anti-cheat is busted." Worse: shadowbanning that gets discovered breaks trust with *every* user, not just the affected one.

**Why it happens:**
- Heuristics that catch obvious cheaters also catch outliers who happen to be heavy users.
- Shadowbanning hides from the user but not from observers — when discovered, the betrayal is total.
- Reddit's history with shadowbans is the canonical case study.

**How to avoid:**
- **Tell the user.** If we flag their account, the user sees a "we noticed unusual activity, please respond" notice on their dashboard. Far better than silent down-weighting.
- **Visible appeal path.** Single-click "this was legitimate, here's context" form. Auto-restore on appeal acknowledged within 7 days unless escalated.
- **Confidence-tiered actions.** Low confidence: don't act, just log. Medium confidence: warn user, ask. High confidence (multiple signals + history): rate-limit, never silent-shadowban.
- **Rate-limit, don't ban.** A user with suspicious patterns gets capped score contribution this week, not deleted from the leaderboard.
- **Publish the anti-cheat philosophy.** "We use lightweight signals; we will tell you if you're flagged; you can appeal." Trust comes from transparency.
- **Never silently shadowban in v1.** It's tempting and it's a trap.
- **Audit shadow-band data periodically** with manual review on a sample to catch false-positive patterns early.

**Warning signs:**
- Appeals from users who are clearly legitimate
- Community posts dissecting the anti-cheat algorithm (means it's both gameable and being reverse-engineered)
- High-rank user suddenly drops without explanation
- Specific user-agent or platform combos getting disproportionately flagged

**Phase to address:**
Anti-cheat phase.

**Prior art:** [False Positive Bans in Games (Unbanster)](https://unbanster.com/false-positive-bans/), [False Positive in Codeforces Anti-Cheat (Codeforces blog)](https://codeforces.com/blog/entry/96313), [Reddit Shadowbans 2025 (Reddifier)](https://reddifier.com/blog/reddit-shadowbans-2025-how-they-work-how-to-detect-them-and-what-to-do-next), [Mitigating In-Game Cheating (Quago)](https://quago.io/blog/mitigating-in-game-cheating-an-overview-of-modern-anti-cheat-strategies/)

---

### Pitfall 15: Notification spam disengages users from the social hub

**What goes wrong:**
Friends request, comments posted, leaderboard rank changed, quest available, achievement unlocked, streak warning, weekly summary, comment reply, like on profile. Default-on email + in-app notifications = inbox carnage. Users mark as spam (hurts deliverability), turn off notifications globally (disengage from real signals), or unsubscribe entirely.

**Why it happens:**
Each notification individually seems valuable to ship. The cumulative load is what breaks engagement. Platforms reach for notifications when retention dips, accelerating the problem.

**How to avoid:**
- **Default to almost no notifications.** Email: weekly digest only. In-app: bell-icon, never push.
- **Granular opt-in by category.** User can enable comment replies separately from leaderboard changes separately from achievement unlocks.
- **Never use loss-aversion / guilt notifications** ("Your streak is in danger!", "You haven't logged in!"). Forbidden category.
- **Daily digest pattern**, not per-event. One email max per day, period.
- **One-click unsubscribe (per category).** RFC 8058 list-unsubscribe header.
- **Quiet hours by default.** No notifications outside the user's local working hours.

**Warning signs:**
- Email open rate trending down
- Mark-as-spam reports on transactional email
- "Stop emailing me" support tickets
- Notification settings page being the most-visited settings page

**Phase to address:**
Social hub phase + notifications subsystem.

**Prior art:** [How to Manage Social Media Notifications (CyberGuy)](https://cyberguy.com/privacy/how-to-tame-barrage-stealthy-social-media-notifications-regain-control), [Ultimate Guide to Social Media Moderation (Stream)](https://getstream.io/blog/social-media-moderation/)

---

### Pitfall 16: Cosmetics treated as "earned property" → refund/recovery liability

**What goes wrong:**
A user has 30+ unlocked cosmetics built up over a year. Their account is compromised; the recovery process is messy. They demand we restore everything exactly. Or: we deprecate a cosmetic that turns out to have been someone's favorite, and they treat its loss as a real injury. Or: hosted instance shuts down and the user demands their progression "back" because it took real time. Even though no money changed hands, the felt-property model creates real obligations.

**Why it happens:**
Players treat earned items as property regardless of whether money was paid (Riot, Valve, Epic all hit this). "I worked for this" psychology is identical to "I paid for this."

**How to avoid:**
- **Achievement records are durable, even if cosmetics aren't.** The fact "you earned X" is preserved separately from the cosmetic asset itself, so we can re-render if asset changes.
- **Cosmetic deprecation policy.** Public, written down, generous. "We will not remove cosmetics that have been earned. If we remove a cosmetic from earnability for new players, existing earners keep it." Apply this from day one.
- **Account recovery process documented and tested.** Email-based, with a cooldown, with a way to detect and roll back hostile recovery.
- **Self-host export.** A user can `cli export` their data anytime. If we go down, they keep proof of what they earned.
- **Be explicit no-money-back.** Free service, ToS makes clear no obligation in compensation if anything goes wrong. Reduces legal liability.
- **Don't enable item trading.** Trading creates a market price, which creates real-money expectations even on a free system.

**Warning signs:**
- Support tickets framed as "I lost my X"
- Users asking how to back up their progression
- Community posts about specific deprecated/changed cosmetics
- Account-takeover incident in the news (shows the recovery path under pressure)

**Phase to address:**
Cosmetics/achievements phase + auth/account-recovery phase.

**Prior art:** [Riot Games Global Refund Policy](https://www.riotgames.com/en/global-refund-policy), [Fortnite cosmetic refund backlash (GosuGamers)](https://www.gosugamers.net/entertainment/news/78338-fortnite-rolls-out-d4vd-cosmetic-refunds-as-epic-games-responds-to-player-backlash), [Refund Liability Guide (Hubifi)](https://www.hubifi.com/blog/refund-liability-guide)

---

### Pitfall 17: GDPR / CCPA blind spot on behavioral analytics for personalized quests

**What goes wrong:**
Personalized quests require behavioral analytics on the user's Claude Code workflow. GDPR / CCPA / CPRA require: explicit consent before processing, granular opt-in by purpose, a published retention period (not "as long as needed"), data export, data deletion, and the ability to opt out of "automated decision-making" (which personalized quest selection arguably is). Get any of this wrong and a single complaint to a DPA or AG can be expensive even for an OSS project.

**Why it happens:**
"It's an OSS hobby project" is not a GDPR exemption. Hosting a public instance for EU/California users invokes the obligations. Personalized quests are squarely in scope as profiling.

**How to avoid:**
- **Explicit, granular consent at signup.** Separate checkboxes for: account, quest personalization, leaderboard inclusion, optional community profile, optional behavioral analytics for product improvement.
- **Published retention schedule.** "Raw event data: 90 days. Aggregated stats: indefinite. Account data: until deletion." Specific, not vague.
- **One-click data export** (JSON download).
- **One-click account deletion** with a 30-day grace + verified-email + final-warning flow.
- **Right to opt out of personalization.** Personalized quests can be turned off; user gets the global ones only.
- **Privacy-first analytics for product telemetry.** Plausible/Fathom/PostHog with EU hosting. No Google Analytics.
- **DPA for any third-party processor** (Fly.io, email provider). Most have standard contracts.
- **Public privacy policy.** Even if it's small, it has to exist and be honest.
- **No US-only carve-outs.** If the public instance is reachable from the EU, EU rules apply.
- **Self-hosters set their own policy.** Document this clearly.

**Warning signs:**
- Privacy policy is "TBD" past launch
- No way for a user to see what data we have on them
- Personal data in logs persisting past retention window
- Third-party processors without DPAs

**Phase to address:**
Phase 1 (project setup): privacy policy and ToS scaffolding. Account / data phases: implement export/deletion. Quests phase: consent for personalization.

**Prior art:** [GDPR/CCPA & analytics (DoHost)](https://dohost.us/index.php/2026/05/05/gdpr-ccpa-and-beyond-making-your-analytics-legally-bulletproof/), [First-Party Data Collection & Compliance (Secure Privacy)](https://secureprivacy.ai/blog/first-party-data-collection-compliance-gdpr-ccpa-2025), [CCPA vs GDPR (Matomo)](https://matomo.org/blog/2025/03/ccpa-vs-gdpr-understanding-their-impact-on-data-analytics/)

---

### Pitfall 18: Hosting cost spiral / free-tier abuse

**What goes wrong:**
Users discover that the public instance accepts unlimited event ingest. They set up a CI loop, a script, a fake heavy-usage stream — costs explode. Or: a viral moment brings 50,000 signups in 48 hours and Fly bill triples. Or: someone uploads 4 GB of profile-picture spam. Maintainer is now subsidizing abuse out of pocket.

**Why it happens:**
Free tier = attractor for abuse. Token-using gamification audience = above-average compute spend per user. Profile uploads = unbounded storage. Single-maintainer = no capacity to react in real time.

**How to avoid:**
- **Per-account ingest rate limits + per-IP signup rate limits** baked in from launch.
- **Storage caps.** Profile picture max 200 KB. Comment max 2 KB. Hard server-side limits.
- **No file uploads in v1 beyond avatars.** No images-in-comments, no attachments.
- **Cost ceiling alarms** (Fly/Cloudflare cost alerts). Hard cap with auto-scale-down or auto-degraded-mode if exceeded.
- **Static asset CDN is essential.** Cloudflare free tier in front of everything.
- **Cache aggressively.** Public profiles cache for minutes; leaderboards cache for seconds.
- **Throttle by account age.** Brand-new accounts have very low rate limits, increasing with verified activity.
- **Be explicit about caps publicly.** "Free instance is capped at N active users; self-hosters can run their own."

**Warning signs:**
- Hosting bill rising faster than user count
- One IP or account dominating ingest traffic
- Storage growth not matching user growth
- DDoS-shaped traffic on a low-traffic week

**Phase to address:**
Backend infrastructure phase + signup phase.

**Prior art:** [Open Source Maintainer Burnout (RoamingPigs)](https://roamingpigs.com/field-manual/open-source-maintainer-burnout/), [Open source maintainers state of open (The Register)](https://theregister.com/AMP/2025/02/16/open_source_maintainers_state_of_open)

---

### Pitfall 19: Helper-backend version skew silently produces wrong data

**What goes wrong:**
Helper v1.4 talks to backend v1.6. Backend changed an event schema. Helper sends old shape; backend either rejects (helper sees errors and disables, user notices) or accepts and stores garbage (silent corruption — far worse). Either way, user loses trust.

**Why it happens:**
- Helper installs are spread across user machines and update at user's pace, not ours.
- Forced auto-update is hostile and a security risk.
- Schema migrations that aren't backward-compatible.

**How to avoid:**
- **Versioned API surface (`/api/v1/...`).** Bump only on breaking changes. Keep `v1` running for ≥6 months past `v2` launch.
- **Helper sends its version on every request** (`User-Agent: gsd-helper/1.4.0`). Backend can detect and degrade gracefully, or return a "please upgrade" hint.
- **Schema validation rejects unknown shapes loudly, not silently.** Better to fail-closed than write wrong data.
- **Backend tolerates missing optional fields from old helpers.**
- **Helper checks for new releases on session start** (low-frequency, opt-in auto-update of the npm package).
- **Server-side feature flags exposed to helper.** "This data type is no longer collected; stop sending it" — server tells helper, helper complies.
- **Soft-deprecate, hard-remove later.** Announce deprecation N months before removal; instrument usage to know when it's safe.

**Warning signs:**
- Long tail of old helper versions in User-Agent stats
- Validation-error rate climbing after a backend release
- Stats inconsistency between helper-claimed and backend-stored

**Phase to address:**
Backend API design phase + helper module phase. Cross-cutting standing concern.

**Prior art:** [Managing API Changes (Theneo)](https://www.theneo.io/blog/managing-api-changes-strategies), [Graceful degradation in practice (Unleash)](https://www.getunleash.io/blog/graceful-degradation-featureops-resilience), [Skew Protection in Modern Web Development](https://manuelsanchezdev.com/blog/skew-protection-web-development/), [Vercel Skew Protection](https://vercel.com/blog/version-skew-protection)

---

## Minor Pitfalls

### Pitfall 20: Friend-spam rings inflating follow counts

Sockpuppet accounts following each other to inflate follower count for vanity. Solution: hide follower count below a threshold; require verified email + N days age + some baseline activity before follower count counts toward any visible metric. Address in social hub phase.

### Pitfall 21: SEO-spam profiles

Public profiles indexed by search engines, abused for SEO link spam. Solution: `noindex` on profiles by default, opt-in to indexing. Address in profile-page phase.

### Pitfall 22: "Completionist" pressure on cosmetics

Some users feel compelled to chase every cosmetic, regardless of whether they want it. Solution: don't display "you have N of M cosmetics" prominently; show only what's earned, not what's missing. Address in achievements/cosmetics phase.

### Pitfall 23: Eventual-consistency confusion in leaderboards

User just hit a milestone, dashboard shows old rank for 30 seconds because of cache. They think they're being shortchanged. Solution: optimistic UI updates on the user's own actions; clearly mark cached vs. live data. Address in leaderboards phase.

### Pitfall 24: "Working more just to climb" perverse incentive

The unintended consequence of token-volume leaderboards: users do more low-value Claude Code work to climb. Mitigation: efficiency leaderboard ranks higher in social copy than raw activity; raw-activity board is intentionally lowest-status. Address in leaderboards phase + comms.

### Pitfall 25: Comment-system underinvestment

Comments are 5% of the build effort and 80% of the moderation effort. Easy to underestimate. Mitigation: ship comments off-by-default, behind explicit profile-owner enable. Could also defer comments to v1.1 entirely. Address in social hub phase.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Skip rate limiting on launch ("we'll add it when we need it") | Days of work saved | First abuse incident is also first time we're discovering rate limit gaps under fire | Never |
| In-process job runner instead of BullMQ worker | One less process to manage | Workers OOM the API container; quest generation pauses when API restarts | Only on $5/mo VPS profile, with documented upgrade path |
| Single-region single-machine deploy | Lower hosting cost | Maintenance windows = downtime; one Fly node failure = full outage | Acceptable in months 1-3 while user count is < 500 |
| Skip the appeal flow for shadow-banned accounts | Saves a UI screen | First false-positive becomes a viral PR incident | Never — appeal path must ship with anti-cheat |
| Synchronous network call in a hook for "just one signal" | Direct, simple code | Inevitable spurious latency in user sessions when the network burps | Never |
| Store Anthropic OAuth token on backend "just for caching" | Faster usage API responses | If our backend leaks, users' Anthropic accounts are at risk | Never |
| Skip user-timezone field, use UTC everywhere for "simplicity" | One fewer column, simpler queries | Streak/quest correctness becomes wrong for half the world | Never on user-facing day-bucket logic |
| No vacation mode on streaks for v1 | One feature deferred | Lifetime: exact pattern Habitica gets criticized for | Acceptable if streaks are not yet released; not acceptable once they are |
| Comments without per-profile-owner toggle | Faster ship | Profile owners cornered into receiving harassment | Never |
| `0.0.0.0` bind on backend in dev for "easier mobile testing" | Convenience | Becomes the prod default by accident | Document only, never default |
| Skip pino redaction filter for tokens | One less config | Single bad log line = credential leak | Never |
| Skip CI license-checker | Saves 5 minutes of CI setup | A GPL dep gets pulled in transitively, infects redistribution | Never |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Anthropic OAuth usage API | Polling on every hook event | Cache 5h/7d windows for ≥60 seconds; only refresh on demand |
| `~/.claude/.credentials.json` | Reading without checking permissions, then logging the value | Read with mode check; never log; redact in any logger transport |
| Claude Code hook system | Assuming payload schema is stable | Zod validation; schema-versioned event capture; tolerate unknown fields |
| Claude Code statusline contract | Embedding network calls in the statusline-fragment command | Statusline reads only from local cache; background process refreshes |
| Better Auth device flow | Not enabling PKCE; not validating `state` | Enable PKCE S256; validate state; rate-limit code issuance |
| BullMQ on Redis | Not setting `removeOnComplete` / `removeOnFail` → unbounded memory | Set retention limits per queue |
| PostgreSQL daily reset cron | Single global 00:00 UTC sweep | Per-user worker; sweeps users whose local-day rolls in this minute |
| Drizzle migrations | `drizzle-kit push` in production | `drizzle-kit generate` reviewed migrations; `migrate` in deploy |
| Fly.io | Single machine, no health checks | Multiple machines per app even at small scale; health checks required |
| Cloudflare in front of Fly | Forgetting to set up real client IP forwarding | `fly.toml` proxy_protocol; trust-proxy in Hono |
| SSE for live leaderboards | Holding too many SSE connections per machine | Cap concurrent streams per machine; heartbeat + reconnect; consider pubsub-fanout pattern |
| Email transactional provider | Skipping list-unsubscribe headers | RFC 8058 one-click unsubscribe header on every category |
| OpenTelemetry | Default export to a vendor SDK | Vendor-neutral OTLP exporter; let users (and self-hosters) point it where they want |
| `better-sqlite3` | Native build fails on user's platform → helper install fails | Pure-JS fallback (`sql.js` or simple JSON file) on build failure |
| Press Start 2P / VT323 | Loaded as web fonts blocking first paint | `font-display: swap`; serve from same origin or with proper CORS |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Recompute leaderboard from event log on every read | Read latency creep, DB CPU climbs | Maintain leaderboard in Redis sorted set; recompute only on explicit invalidation | ~5k active users |
| Daily cron at 00:00 UTC for streaks/quests | Massive CPU spike at midnight, nothing else 23 hours | Per-user reset distributed by local timezone; small worker pool sweeps continuously | ~1k users in non-UTC timezones |
| Fanout writes on every event ("update friend feeds, leaderboards, achievements") synchronously | Hook ingest endpoint becomes slow | Ingest writes raw event only; async workers fan out | ~100 concurrent active sessions |
| One SSE connection per browser tab without backpressure | Long-running connections accumulate; OOM | Cap per-machine concurrent SSE; idle timeout; consider periodic full-refresh model | A few hundred concurrent live viewers |
| Storing every hook event individually in Postgres | Table grows unboundedly; queries slow over time | Hot store (last 90 days) + cold store (compressed/aggregated); event-stream archival | ~6 months of usage |
| Computing achievements eagerly on every event | Every event triggers expensive evaluation | Batched evaluation in worker; cheap predicate filter before full check | ~10k users with rich histories |
| Avatars / profile assets served from app | App machine bandwidth + CPU on image serving | Cloudflare R2 or static CDN | Day one, this is cheap to do right |
| Synchronous JSON.parse on large hook payloads in hot path | p99 latency spikes correlate with prompt size | Stream parse, or treat payload as opaque string until off-hot-path | First user with a 100KB prompt |
| `LIKE '%foo%'` queries for user search | Full table scan; slow as user count grows | Postgres `pg_trgm` GIN index for fuzzy search, or dedicated search if needed | ~10k users |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Logging the Anthropic OAuth token (even in error paths) | Catastrophic — user's *Anthropic* account compromised | pino redaction filter; CI grep for token-prefix patterns in committed code |
| Sending Anthropic OAuth token to our backend | Backend breach = Anthropic account compromise | Helper calls `api.anthropic.com` directly; backend never sees the token |
| Trusting client-claimed event timestamps for ranking | Time-travel cheating | Server stamps the canonical timestamp; client timestamp is informational only |
| Trusting client-claimed event counts for ranking | Trivial inflation | Server cross-checks against OAuth usage API and event-rate sanity bounds |
| Missing PKCE on the device flow | Authorization code interception attacks | Enable PKCE S256 in Better Auth config; verify in tests |
| Missing `state` validation on device flow | CSRF on the approval | Validate state end-to-end; reject mismatches |
| Long-lived `user_code` (e.g. 24h) | Phishing window | Cap user_code TTL at 10 minutes; refresh on each `cli pair` invocation |
| Auto-approving second pairing for an existing account without notification | Silent account takeover | Email user on every new pairing with revocation link |
| Profile comments without per-owner toggle | Harassment vector | Default off; profile owner explicitly enables |
| Reserved/admin/staff handles unprotected | Impersonation, phishing in-app | Reserved-handle list at signup; reject; periodically audit |
| Real-time "active now" indicator | Stalker enabler | Use weekly buckets at most; user opts in to anything finer |
| Showing precise token counts per session | Doxxing vector when cross-referenced with billing tier leaks | Aggregate to bands; show colors not numbers in public surfaces |
| `0.0.0.0` bind on dev configs | LAN exposure | `127.0.0.1` only for local listeners; verified in startup self-test |
| Unrestricted account deletion | Hostile recovery / griefing | Email-confirmed, 30-day grace, undo path |
| Unaudited supply-chain | Malicious npm dep reads token | Pin all deps; audit transitive tree; CI license-checker; minimal deps in helper |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Showing global rank to a user in their first session | Demoralization, immediate quit | Hide leaderboard for first week; show personal stats only |
| Pushing notifications about uncompleted quests | Anxiety, chore-feeling | Quest list visible on dashboard, never pushed |
| Guilt-framed copy ("you broke your streak", "Duo is sad") | Hostile feel; long-term resentment | Neutral, factual ("Streak ended at 14 days"); celebrate restart |
| Surfacing ranks below position N | "I'm #18472 of 50000" demoralization | Show "outside top N" instead |
| No vacation/freeze mechanism | Streak anxiety | Streak freezes by default; explicit vacation mode |
| All cosmetics visible-but-locked | Completionist pressure | Show only earned; locked ones discoverable but not displayed as gaps |
| Aggressive CLI output on every hook | Visual noise in user's terminal | Hooks silent unless user opted into verbose mode |
| Statusline fragment re-fetches on every render | Statusline lag perceived as Claude Code lag | Read from local cache only |
| No clear "what does my rank mean" page | Confusion about scoring | Public ranking-formula page with examples |
| Achievement unlock blocks the user's session | Annoying | Toast notification, dismissible, never modal in CLI context |
| Friend request notifications via push | Unwanted social pressure | Friend requests via in-app indicator only; no email/push by default |

## "Looks Done But Isn't" Checklist

- [ ] **Hook latency budget:** measured p50/p95/p99 on Linux + macOS + Windows + Windows-ARM, all under 50 ms p99? (Often missing: ARM Windows)
- [ ] **DST tests:** unit tests for spring-forward and fall-back days across at least 3 timezones? (Often missing: only UTC tests exist)
- [ ] **Token redaction:** grep CI step that fails the build if any committed file contains a string matching the Anthropic token prefix in a logging context? (Often missing: regex never runs against logs)
- [ ] **Reserved handles:** list audited at launch and quarterly thereafter? (Often missing: list ships with 5 entries)
- [ ] **Rate limits:** verified in load test, not just by reading config? (Often missing: config is set, but no test confirms it's honored)
- [ ] **Account deletion:** end-to-end deletion verified, including event archive, leaderboard scrub, comments scrub, third-party processor (Sentry, Plausible)? (Often missing: deletion only touches the primary DB)
- [ ] **GDPR data export:** includes everything we have, in a machine-readable format? (Often missing: exports the user table only)
- [ ] **Privacy policy:** mentions every actual data flow, with retention periods? (Often missing: written generically, doesn't match implementation)
- [ ] **Helper version skew:** old helper version in production sees a sane error message and a clear upgrade path? (Often missing: returns 400 with no body)
- [ ] **Anti-cheat appeal:** appeal path tested by an actual user, end-to-end? (Often missing: form exists, no one's ever submitted it)
- [ ] **Shutdown plan:** documented publicly, with data export + transfer/notice commitments? (Often missing: the maintainer has a plan in their head)
- [ ] **Cosmetic deprecation policy:** written, public, applied even when inconvenient? (Often missing: lives only in the maintainer's intent)
- [ ] **Notification opt-out:** every category truly off-by-default at signup? (Often missing: "weekly digest" defaults on)
- [ ] **Profile comments:** off by default until explicitly enabled by the profile owner? (Often missing: "we'll moderate them")
- [ ] **PKCE + state on device flow:** verified in an integration test that they're actually validated, not merely sent? (Often missing: state is generated but never compared)
- [ ] **Hooks fail-safe:** every hook handler's catch path tested by deliberate fault injection? (Often missing: only happy path tested)
- [ ] **Self-host parity:** public instance and Docker Compose run from the exact same image? (Often missing: a "production tweak" diverges them)
- [ ] **Synthetic Claude Code release test:** CI installs latest Claude Code and runs hook-capture end-to-end? (Often missing: tests use mocked hook inputs)

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Anthropic token leak | HIGH | (1) Notify affected users immediately, (2) help them rotate via `claude` CLI re-auth, (3) public post-mortem, (4) audit how it leaked, (5) add the missing redaction/test, (6) consider security advisory |
| Goodhart-on-leaderboard exploit goes viral | MEDIUM | (1) Rotate scoring formula immediately, (2) recompute affected windows, (3) post-mortem and explain change, (4) add detector for the specific exploit |
| Anti-cheat false-positive flagged a legitimate user publicly | MEDIUM | (1) Restore stats, (2) public apology, (3) explain on dashboard for affected user, (4) review and tune thresholds, (5) audit similar accounts proactively |
| Claude Code release breaks our hooks | LOW–MEDIUM | (1) Detect via synthetic monitoring, (2) flip hook feature flag off backend-side, (3) status banner ("stats may be incomplete due to Claude Code update"), (4) ship fix, (5) replay buffered events if possible |
| Streak-anxiety backlash post goes viral | MEDIUM | (1) Don't argue, (2) ship vacation mode and freezes immediately if not present, (3) reduce notification aggressiveness, (4) post about the change, (5) survey community on remaining anxiety drivers |
| DDoS / abuse spike on free tier | MEDIUM | (1) Cloudflare WAF rules, (2) per-IP signup throttle, (3) cap public ingest, (4) consider invite-only mode, (5) communicate openly |
| Phishing campaign exploits device flow | HIGH | (1) Force re-auth for affected users, (2) revoke pending device codes, (3) stronger pairing email confirmation, (4) public advisory, (5) raise display friction on approval page |
| Maintainer burnout | HIGH | (1) Pre-committed shutdown plan kicks in, (2) recruit co-maintainer or stop service with full data export, (3) hand off public instance gracefully, (4) self-host docs become primary path |
| Account takeover incident | HIGH | (1) Lock affected account, (2) email original owner, (3) reverse hostile changes from audit log, (4) require re-verification, (5) post-mortem on the recovery flow |
| GDPR complaint to a DPA | MEDIUM | (1) Cooperate fully, (2) document data flows in detail, (3) honor any specific request immediately, (4) update privacy policy and processes, (5) communicate publicly if material |

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| 1. Overjustification | Quests/XP design phase | UX review checklist; opt-out shipped; framing audit |
| 2. Goodhart on raw leaderboard | Leaderboards + anti-cheat phase | Composite score formula; periodic rotation plan documented |
| 3. Streak anxiety | Streaks/quests phase | Freezes + vacation mode shipped; no guilt copy in notifications |
| 4. Device-code phishing | Auth / device-pairing phase | PKCE + state verified in integration test; user_code re-entry required; email notification on new pair |
| 5. Helper crashes hurt sessions | Helper module phase | Cross-platform CI; latency budget enforced; top-level catch in every hook |
| 6. OAuth token leakage | Helper module phase | Redaction filter; CI grep; token never sent to backend |
| 7. Maintainer burnout | Cross-cutting (Phase 1 setup) | Shutdown plan published; moderation tooling baseline; hosting cap declared |
| 8. Real-handle harassment | Social hub phase + signup phase | Reserved-handle list; comments default off; report+block+mute shipped |
| 9. Hook-system breakage | Helper module + hook capture phase | Schema-versioned capture; synthetic monitoring; feature flags on hooks |
| 10. Timezone / DST bugs | Streaks + leaderboards phase | DST unit tests; per-user reset; grace window |
| 11. Localhost/CSRF on pairing | Auth phase | Stick to RFC 8628; PKCE + state; no localhost listener pattern |
| 12. Bottom-of-leaderboard demotivation | Leaderboards phase | Default to relative cohort; soft floor; multi-board surfacing |
| 13. Quest fatigue | Quests phase | Skips don't penalize; re-rolls; variable quest count |
| 14. Anti-cheat false positives | Anti-cheat phase | Visible flag + appeal flow; never silent shadowban |
| 15. Notification spam | Social hub + notifications phase | Default-off granular opt-in; no guilt notifications; quiet hours |
| 16. Cosmetic-as-property | Cosmetics + auth/account-recovery phase | Deprecation policy public; export shipped; ToS limits liability |
| 17. GDPR/CCPA blind spot | Phase 1 setup + account/data phases | Privacy policy real; export + delete shipped; granular consent at signup |
| 18. Hosting cost spiral | Backend infra + signup phase | Rate limits; storage caps; cost ceiling alarms; public cap declared |
| 19. Version skew | Backend API + helper phase | Versioned API; helper sends version; backend tolerant; deprecation policy |
| 20. Friend-spam rings | Social hub phase | Follower count gating; bot detection on graph |
| 21. Profile SEO spam | Profile phase | `noindex` default; opt-in indexing |
| 22. Completionist pressure | Achievements/cosmetics phase | Don't show "X of Y" prominently |
| 23. Leaderboard eventual consistency | Leaderboards phase | Optimistic UI on user's own actions; clear cached-vs-live indicator |
| 24. "Working more to climb" | Leaderboards + comms | Efficiency board higher status than raw activity in copy |
| 25. Comment-system underinvestment | Social hub phase | Comments default off; consider deferring to v1.1 |

## Sources

### Gamification Psychology
- [Overjustification effect (Wikipedia)](https://en.wikipedia.org/wiki/Overjustification_effect) — HIGH
- [Yu-kai Chou — Motivation Traps in Reward-Based Gamification](https://yukaichou.com/gamification-study/motivation-traps-rewardbased-gamification-campaigns/) — HIGH (foundational gamification author)
- [How Rewards Kill Creativity (Yu-kai Chou)](https://yukaichou.com/gamification-study/rewards-kill-creativity/) — HIGH
- [Negative Effects of Extrinsic Rewards on Intrinsic Motivation (USC CEO)](https://ceo.usc.edu/wp-content/uploads/2013/02/2013-05-G13-05-624-Negative_Effects_of_Extrinsic_Rewards.pdf) — HIGH (peer-reviewed)
- [Streak Design without Burnout (Yu-kai Chou)](https://yukaichou.com/gamification-analysis/streak-design-gamification-motivation-burnout/) — HIGH
- [Streak Creep (Decision Lab)](https://thedecisionlab.com/insights/consumer-insights/streak-creep-the-perils-of-too-much-gamification) — HIGH
- [The Psychology of Streaks (Trophy)](https://trophy.so/blog/the-psychology-of-streaks-how-sylvi-weaponized-duolingos-best-feature-against-them) — MEDIUM
- [Habitica Burnout (Habitica Wiki)](https://habitica.fandom.com/wiki/Burnout) — HIGH (primary source, the community itself)
- [Tired of Habitica? (The Canary)](https://www.thecanary.co/discovery/lifestyle/2026/03/30/tired-of-habitica-try-these-3-cheaper-and-more-engaging-habitica-alternatives/) — MEDIUM
- [Death of the Leaderboard (Kaizo / Medium)](https://medium.com/@kaizo/death-of-the-leaderboard-why-ranking-is-whats-wrong-in-workplace-gamification-7af68c408b60) — MEDIUM
- [The Psychological Impact of Leaderboards (CLUELabs)](https://cluelabs.com/blog/the-psychological-impact-of-leaderboards-on-learning-professionals/) — MEDIUM
- [How Ranking Becomes Demotivating (Inside Higher Ed)](https://www.insidehighered.com/blogs/just-visiting/how-ranking-becomes-demotivating) — MEDIUM
- [Leaderboard Fatigue Is Real (Spinify)](https://spinify.com/blog/leaderboard-fatigue-is-real-heres-how-to-fix-it/) — MEDIUM

### Goodhart's Law
- [Goodhart's law (Wikipedia)](https://en.wikipedia.org/wiki/Goodhart's_law) — HIGH
- [Goodhart's law and gamification of metrics (de Vroome / Medium)](https://tdevroome.medium.com/goodharts-law-and-gamification-of-metrics-ff697ac86575) — MEDIUM
- [Gaming the System: Goodhart's Law in AI Leaderboard Controversy (Collinear)](https://blog.collinear.ai/p/gaming-the-system-goodharts-law-exemplified-in-ai-leaderboard-controversy) — MEDIUM
- [The Leaderboard Illusion (Kejriwal)](https://aiscientist.substack.com/p/musing-118-the-leaderboard-illusion) — MEDIUM

### OAuth / Device Flow Security
- [RFC 8628 — OAuth 2.0 Device Authorization Grant](https://www.rfc-editor.org/rfc/rfc8628.html) — HIGH (the spec)
- [RFC 9700 — OAuth 2.0 Security Best Current Practice](https://datatracker.ietf.org/doc/rfc9700/) — HIGH
- [OAuth Device Code Phishing Hits 340+ M365 Organizations (CSA Labs)](https://labs.cloudsecurityalliance.org/research/csa-research-note-oauth-device-code-phishing-m365-20260325-c/) — HIGH
- [OAuth's Device Code Flow Abused in Phishing Attacks (Secureworks)](https://www.secureworks.com/blog/oauths-device-code-flow-abused-in-phishing-attacks) — HIGH (security firm primary research)
- [Introducing GitHub Device Code Phishing (Praetorian)](https://www.praetorian.com/blog/introducing-github-device-code-phishing/) — HIGH
- [Go With the Flow: Abusing OAuth Device Code Flow (LevelBlue / SpiderLabs)](https://www.levelblue.com/blogs/spiderlabs-blog/go-with-the-flow-abusing-oauth-device-code-flow) — HIGH
- [Device Authorization Grant explainer (WorkOS)](https://workos.com/blog/oauth-device-authorization-grant) — MEDIUM
- [OAuth best practices: We read RFC 9700 (WorkOS)](https://workos.com/blog/oauth-best-practices) — MEDIUM
- [Best practices for CLI authentication (WorkOS)](https://workos.com/guide/best-practices-for-cli-authentication-a-technical-guide) — MEDIUM
- [Best practices for mitigating compromised OAuth tokens (Google Cloud)](https://cloud.google.com/architecture/bps-for-mitigating-gcloud-oauth-tokens) — HIGH (official)
- [Testing for OAuth Weaknesses (OWASP)](https://owasp.org/www-project-web-security-testing-guide/latest/4-Web_Application_Security_Testing/05-Authorization_Testing/05-Testing_for_OAuth_Weaknesses) — HIGH

### Localhost / CSRF
- [Localhost dangers: CORS and DNS rebinding (GitHub Blog)](https://github.blog/security/application-security/localhost-dangers-cors-and-dns-rebinding/) — HIGH
- [Cross Site Request Forgery and OAuth2 (Spring)](https://spring.io/blog/2011/11/30/cross-site-request-forgery-and-oauth2/) — MEDIUM

### Anti-Cheat
- [Mitigating In-Game Cheating (Quago)](https://quago.io/blog/mitigating-in-game-cheating-an-overview-of-modern-anti-cheat-strategies/) — MEDIUM
- [False Positive Bans in Games (Unbanster)](https://unbanster.com/false-positive-bans/) — MEDIUM
- [False Positive in Codeforces Anti-Cheat (Codeforces)](https://codeforces.com/blog/entry/96313) — MEDIUM (community case study)
- [Reddit Shadowbans 2025 (Reddifier)](https://reddifier.com/blog/reddit-shadowbans-2025-how-they-work-how-to-detect-them-and-what-to-do-next) — MEDIUM
- [Open source community leaderboards best practices (opensource.com)](https://opensource.com/article/21/9/community-leaderboard) — MEDIUM
- [Navigating the Botting Industry (Naavik)](https://naavik.co/podcast/navigating-the-botting-industry-fraud-cheating-and-multi-accounting/) — MEDIUM

### OSS Maintainer / Project Risk
- [Open Source Maintainer Burnout: Critical Infrastructure Is Dying (RoamingPigs)](https://roamingpigs.com/field-manual/open-source-maintainer-burnout/) — MEDIUM
- [Single-maintainer open source is a ticking time bomb (XDA)](https://www.xda-developers.com/single-maintainer-open-source-ticking-time-bomb/) — MEDIUM
- [Open source maintainers state of open (The Register)](https://theregister.com/AMP/2025/02/16/open_source_maintainers_state_of_open) — HIGH
- [The Silent Crisis in Open Source: When Maintainers Walk Away (OpenSauced)](https://opensauced.pizza/blog/when-open-source-maintainers-leave) — MEDIUM
- [Combating Open Source Maintainer Burnout with Automation (Dosu)](https://blog.dosu.dev/combating-open-source-maintainer-burnout-with-automation/) — MEDIUM
- [Why I quit open source (Sapegin)](https://dev.to/sapegin/why-i-quit-open-source-1n2e) — MEDIUM (personal account, valuable)
- [The burden of an Open Source maintainer (Jeff Geerling)](https://www.jeffgeerling.com/blog/2022/burden-open-source-maintainer) — MEDIUM
- [Moderation Strategies in Open Source Software Projects (ACM CHI)](https://dl.acm.org/doi/10.1145/3610092) — HIGH (peer-reviewed)

### Claude Code / Hooks
- [Claude Code Hooks reference (official)](https://code.claude.com/docs/en/hooks) — HIGH
- [Claude Code Changelog 2026](https://claudefa.st/blog/guide/changelog) — MEDIUM
- [Plugin hooks not updated when plugin version changes #18517](https://github.com/anthropics/claude-code/issues/18517) — HIGH (primary, real bug)
- [Hooks not loading from settings.json #11544](https://github.com/anthropics/claude-code/issues/11544) — HIGH (primary, real bug)
- [Hook Failures (DeepWiki)](https://deepwiki.com/affaan-m/everything-claude-code/16.2-hook-failures) — MEDIUM

### Streaks / Timezone / DST
- [Streak Timezone & DST Handling (Trophy)](https://trophy.so/blog/streak-timezone-dst-handling) — HIGH (specific, technical)
- [Handling Time Zones in Global Gamification Features (Trophy)](https://trophy.so/blog/handling-time-zones-gamification) — HIGH
- [How to Build a Streaks Feature (Trophy)](https://trophy.so/blog/how-to-build-a-streaks-feature) — HIGH
- [LeetCode streak broken due to incorrect day counting (#28204)](https://github.com/LeetCode-Feedback/LeetCode-Feedback/issues/28204) — HIGH (primary case)
- [GitHub contribution streak reset despite daily activity](https://github.com/orgs/community/discussions/172053) — HIGH (primary case)

### Privacy / GDPR / CCPA
- [GDPR/CCPA & analytics (DoHost)](https://dohost.us/index.php/2026/05/05/gdpr-ccpa-and-beyond-making-your-analytics-legally-bulletproof/) — MEDIUM
- [First-Party Data Collection & Compliance (Secure Privacy)](https://secureprivacy.ai/blog/first-party-data-collection-compliance-gdpr-ccpa-2025) — MEDIUM
- [CCPA vs GDPR (Matomo)](https://matomo.org/blog/2025/03/ccpa-vs-gdpr-understanding-their-impact-on-data-analytics/) — MEDIUM
- [Plausible Analytics data policy](https://plausible.io/data-policy) — MEDIUM (primary on privacy-first analytics)

### Harassment / Doxxing / Moderation
- [Doxxing Information (UCSD Privacy)](https://privacy.ucsd.edu/resources-guidance/doxxing/index.html) — HIGH
- [Online Harassment Field Manual (PEN America)](https://onlineharassmentfieldmanual.pen.org/protecting-information-from-doxing/) — HIGH
- [Online Harassment: Assessing Harms and Remedies (Schoenebeck et al., SAGE)](https://journals.sagepub.com/doi/10.1177/20563051231157297) — HIGH (peer-reviewed)
- [Ultimate Guide to Social Media Moderation (Stream)](https://getstream.io/blog/social-media-moderation/) — MEDIUM

### Cosmetics / Refund / Recovery
- [Riot Games Global Refund Policy](https://www.riotgames.com/en/global-refund-policy) — HIGH (primary)
- [Fortnite cosmetic refund backlash (GosuGamers)](https://www.gosugamers.net/entertainment/news/78338-fortnite-rolls-out-d4vd-cosmetic-refunds-as-epic-games-responds-to-player-backlash) — MEDIUM
- [LoL Refund Policy (Riot)](https://support-leagueoflegends.riotgames.com/hc/en-us/articles/201751864-LoL-Refund-Policy) — HIGH

### Version Skew / API Compatibility
- [Managing API Changes (Theneo)](https://www.theneo.io/blog/managing-api-changes-strategies) — MEDIUM
- [Vercel Skew Protection](https://vercel.com/blog/version-skew-protection) — MEDIUM
- [Graceful degradation in practice (Unleash)](https://www.getunleash.io/blog/graceful-degradation-featureops-resilience) — MEDIUM
- [Kubernetes CRI API Version Skew Policy](https://www.kubernetes.dev/docs/code/cri-api-version-skew-policy/) — HIGH

---
*Pitfalls research for: OSS gamification service for Claude Code (web + backend + helper module)*
*Researched: 2026-05-08*

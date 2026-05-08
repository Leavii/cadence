# Phase 0: Project Setup, Privacy, and Sustainability Scaffolding - Pattern Map

**Mapped:** 2026-05-08
**Files analyzed:** 32 (new) / 0 (modified)
**Analogs found:** 0 in-repo (fresh project — confirmed) / 32

**Important:** This is a fresh repo. Only `.claude/`, `.git/`, `.planning/`, and `CLAUDE.md` exist at root. There are zero in-repo analogs to copy from. **Every row below is "net new"** and routes the planner to either:

1. A specific section/example in `00-RESEARCH.md` (canonical reference snippet), or
2. An external canonical URL the planner must fetch verbatim (Apache-2.0, Contributor Covenant 2.1, DCO).

Do not invent file content. Use the routes below.

---

## File Classification

Files grouped into **four parallelizable workstreams** matching `00-RESEARCH.md` § Summary primary recommendation: (A) Repo + License + CoC + DCO + CI, (B) Docker Compose stack, (C) Legal docs, (D) Sustainability + content scaffolding.

### Workstream A — Repo + License + CoC + DCO + CI

| New File | Role | Data Flow | Closest Analog | Match Quality |
|----------|------|-----------|----------------|---------------|
| `LICENSE` | governance / legal text | static doc | none in repo | net new — verbatim from canonical URL |
| `CODE_OF_CONDUCT.md` | governance / community | static doc | none in repo | net new — verbatim from canonical URL |
| `CONTRIBUTING.md` | governance / contributor onboarding | static doc | none in repo | net new — see RESEARCH.md § Code Examples Example 12 |
| `SECURITY.md` | governance / vuln reporting | static doc | none in repo | net new — see RESEARCH.md § Code Examples Example 11 |
| `.gitignore` | config / VCS hygiene | static config | none in repo | net new — standard Node + macOS + Windows |
| `.editorconfig` | config / cross-platform formatting | static config | none in repo | net new — 2-space, LF |
| `.github/workflows/license-check.yml` | CI workflow | request-response (PR webhook) | none in repo | net new — see RESEARCH.md § Pattern 2 (verbatim YAML) |
| `.github/workflows/dco.yml` | CI workflow | request-response (PR webhook) | none in repo | net new — see RESEARCH.md § Pattern 3 (verbatim YAML) |
| `.github/PULL_REQUEST_TEMPLATE.md` | governance / PR scaffolding | static doc | none in repo | net new — DCO-checkbox reminder |
| `.github/ISSUE_TEMPLATE/bug_report.md` | governance / issue scaffolding | static doc | none in repo | net new — GitHub default-style |
| `.github/ISSUE_TEMPLATE/feature_request.md` | governance / issue scaffolding | static doc | none in repo | net new — GitHub default-style |

### Workstream B — Docker Compose Stack

| New File | Role | Data Flow | Closest Analog | Match Quality |
|----------|------|-----------|----------------|---------------|
| `docker-compose.yml` | infra / dev + self-host parity | static config | none in repo | net new — see RESEARCH.md § Pattern 4 (verbatim YAML) |
| `docker-compose.override.yml.example` | infra / dev-only template | static config | none in repo | net new — comment-only template; not committed live |
| `.env.example` | config / env defaults | static config | none in repo | net new — see RESEARCH.md § Pattern 4 (verbatim block) |

### Workstream C — Legal / Ops Docs

| New File | Role | Data Flow | Closest Analog | Match Quality |
|----------|------|-----------|----------------|---------------|
| `docs/legal/privacy-policy.md` | legal / data-controller statement | static doc | none in repo | net new — see RESEARCH.md § Code Examples Example 9 |
| `docs/legal/terms-of-service.md` | legal / service contract | static doc | none in repo | net new — clean-room from Plausible/Standard Ebooks per CD-04 |
| `docs/legal/retention-schedule.md` | legal / data lifecycle | static doc | none in repo | net new — see RESEARCH.md § Code Examples Example 6 |
| `docs/legal/hosting-cap.md` | legal / capacity declaration | static doc | none in repo | net new — see RESEARCH.md § Code Examples Example 7 |
| `docs/legal/shutdown-plan.md` | legal / wind-down commitment | static doc | none in repo | net new — see RESEARCH.md § Code Examples Example 8 |
| `docs/ops/dns.md` | ops / DNS records | static doc | none in repo | net new — see RESEARCH.md § Code Examples Example 5 |
| `docs/architecture/00-overview.md` | architecture / cross-cutting rules | static doc | none in repo | net new — codify two load-bearing rules from CONTEXT.md `<specifics>` |

### Workstream D — Sustainability + Content + Monorepo Skeleton

| New File | Role | Data Flow | Closest Analog | Match Quality |
|----------|------|-----------|----------------|---------------|
| `README.md` | governance / project face | static doc | none in repo | net new — see RESEARCH.md § Code Examples Example 4 |
| `package.json` (root) | config / monorepo workspace | static config | none in repo | net new — see RESEARCH.md § Code Examples Example 1 |
| `pnpm-workspace.yaml` | config / monorepo workspace | static config | none in repo | net new — see RESEARCH.md § Code Examples Example 2 |
| `turbo.json` | config / monorepo build pipeline | static config | none in repo | net new — see RESEARCH.md § Code Examples Example 3 |
| `apps/api/package.json` | placeholder stub | static config | none in repo | net new — `{ "name":"@gsd/api", "private":true, "type":"module", "version":"0.0.0" }` |
| `apps/web/package.json` | placeholder stub | static config | none in repo | net new — analogous stub |
| `apps/cli/package.json` | placeholder stub | static config | none in repo | net new — analogous stub (note `bin` placeholder per RESEARCH.md project structure) |
| `apps/workers/package.json` | placeholder stub | static config | none in repo | net new — analogous stub |
| `packages/db/package.json` | placeholder stub | static config | none in repo | net new — analogous stub |
| `packages/content/package.json` | placeholder stub | static config | none in repo | net new — analogous stub |
| `packages/content/reserved-handles.json` | content / reserved name list | static data | none in repo | net new — see RESEARCH.md § Pitfall 5 (categorization + structured-shape JSON) |
| `packages/shared/package.json` | placeholder stub | static config | none in repo | net new — analogous stub |
| `packages/ui/package.json` | placeholder stub | static config | none in repo | net new — analogous stub |
| `apps/{api,web,cli,workers}/README.md` (4 files) | placeholder doc | static doc | none in repo | net new — one-line description each |
| `packages/{db,content,shared,ui}/README.md` (4 files) | placeholder doc | static doc | none in repo | net new — one-line description each |
| `scripts/verify-phase-0.sh` (optional) | tooling / smoke verification | shell script | none in repo | net new — see RESEARCH.md § Validation Architecture (Phase Requirements → Test Map) |

---

## Pattern Assignments

### `LICENSE` (governance, static doc)

**Analog:** none in repo — net new.
**Source-of-truth:** verbatim text fetched from `https://www.apache.org/licenses/LICENSE-2.0.txt`.
**Required substitutions:** Apache's APPENDIX (bottom of file) — fill `[yyyy]` with `2026` and `[name of copyright owner]` with `Claude Code Gamification Service Contributors` per D-04.
**Anti-pattern (RESEARCH.md § Don't Hand-Roll):** do NOT modify the body text — modification breaks SPDX detection and OSI compliance.
**Phase 0 requirement:** FND-01.

### `CODE_OF_CONDUCT.md` (governance, static doc)

**Analog:** none in repo — net new.
**Source-of-truth:** verbatim text from `https://www.contributor-covenant.org/version/2/1/code_of_conduct/`.
**Required substitutions:** the maintainer email for incident reporting in the "Enforcement" section. Per D-12, use `hello@{ROOT_DOMAIN}` (replyable) or `{MAINTAINER_EMAIL}` placeholder until the domain is purchased and `hello@` is live.
**Anti-pattern (RESEARCH.md § Don't Hand-Roll):** do NOT customize the text. Substitute only the contact email.
**Phase 0 requirement:** FND-03 (combined with CONTRIBUTING.md).

### `CONTRIBUTING.md` (governance, static doc)

**Analog:** none in repo — net new.
**Reference snippet:** `00-RESEARCH.md` § Code Examples → **Example 12** (lines ~1008-1050). Copy that markdown verbatim.
**Required content (per D-03 + D-04 + FND-03):**
- DCO sign-off instructions (`git commit -s`)
- Explicit "no CLA" statement
- Workflow (open issue → fork → PR → `pnpm licenses:check` + `docker compose up` smoke)
- Apache-2.0 inbound=outbound clause
- Link to `CODE_OF_CONDUCT.md`
**External reference:** `https://developercertificate.org/` for the DCO text link.

### `SECURITY.md` (governance, static doc)

**Analog:** none in repo — net new.
**Reference snippet:** `00-RESEARCH.md` § Code Examples → **Example 11** (lines ~971-1006). Copy that markdown verbatim.
**Required substitutions:** `security@{ROOT_DOMAIN}` once the domain exists; placeholder `{MAINTAINER_EMAIL}` until then.
**Disclosure window:** 90-day coordinated-disclosure language per RESEARCH.md.

### `.github/workflows/license-check.yml` (CI workflow, request-response)

**Analog:** none in repo — net new.
**Reference snippet:** `00-RESEARCH.md` § Pattern 2 (lines ~256-292). **Copy YAML verbatim** including the banned-SPDX regex.
**Banned-SPDX list (verbatim from RESEARCH.md):** `GPL-2.0|GPL-3.0|AGPL-1.0|AGPL-3.0|LGPL-2.1|LGPL-3.0|SSPL-1.0|RSAL-2.0|RSALv2`.
**Critical anti-pattern (RESEARCH.md § Pitfall 1):** do NOT use `actions/dependency-review-action` — it requires GitHub Advanced Security on private repos and will silently no-op until repo flips public per D-15.
**Hardening flag:** `pnpm install --ignore-scripts` is intentional; license-check must not run dep postinstall hooks.
**Plan-check fixture (RESEARCH.md § Wave 0 Gaps):** verify regex passes a dual-licensed permissive package (e.g., `argon2` = `CC0-1.0 OR Apache-2.0`) and fails a known-AGPL package fixture.
**Phase 0 requirement:** FND-02.

### `.github/workflows/dco.yml` (CI workflow, request-response)

**Analog:** none in repo — net new.
**Reference snippet:** `00-RESEARCH.md` § Pattern 3 (lines ~298-318). Copy YAML verbatim.
**Action used:** `KineticCafe/actions-dco@v2` (MIT-licensed) — `fetch-depth: 0` is required.
**Critical anti-pattern (RESEARCH.md § Pitfall 3):** the squash-merge UI can drop sign-off trailers. Mitigations:
1. The workflow gates *PR commits*, not the merge commit (this is sufficient for inbound-DCO).
2. Repo settings: enable **"Require contributors to sign off on web-based commits"** (Settings → General → Pull Requests). This is a manual maintainer step — flag it in plan as a non-file deliverable.
**Phase 0 requirement:** D-03 / FND-03.

### `.github/PULL_REQUEST_TEMPLATE.md` (governance, static doc)

**Analog:** none in repo — net new.
**Required content:** brief summary block + DCO checkbox reminder (`[ ] All commits Signed-off-by`). Reference: implied by D-03 + RESEARCH.md § Recommended Project Structure (line ~217).

### `.github/ISSUE_TEMPLATE/bug_report.md` and `feature_request.md` (governance, static doc)

**Analog:** none in repo — net new.
**Source pattern:** GitHub's default community templates (`https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/manually-creating-a-single-issue-template-for-your-repository`). Bug report = repro steps / expected / actual / environment. Feature request = problem / proposed solution / alternatives.

### `.gitignore` (config, static)

**Analog:** none in repo — net new.
**Required content:** standard Node.js (`node_modules/`, `dist/`, `.svelte-kit/`, `*.log`), Docker (`docker-compose.override.yml`), env (`.env`, `.env.local`, `*.key`, `*.pem`), OS (`.DS_Store`, `Thumbs.db`), editor (`.vscode/`, `.idea/` with `*.iml`).
**Critical (RESEARCH.md § Phase 0 Specific Security Notes):** `.env` and `*.key` MUST be ignored; only `.env.example` is committed.

### `.editorconfig` (config, static)

**Analog:** none in repo — net new.
**Required content:** root `[*]` block with `indent_style = space`, `indent_size = 2`, `end_of_line = lf`, `charset = utf-8`, `insert_final_newline = true`, `trim_trailing_whitespace = true`. Cross-platform sanity for Windows + macOS + Linux contributors.

### `docker-compose.yml` (infra, static)

**Analog:** none in repo — net new.
**Reference snippet:** `00-RESEARCH.md` § Pattern 4 (lines ~327-386). **Copy YAML verbatim**.
**Three services + healthchecks:**
- `postgres:17-alpine` — `pg_isready` healthcheck (RESEARCH.md § Don't Hand-Roll: do not connect via `psql`).
- `valkey/valkey:8-alpine` — `valkey-cli ping` healthcheck, `--appendonly yes`.
- `axllent/mailpit:latest` — built-in `/readyz` HEALTHCHECK in upstream Dockerfile (RESEARCH.md § Don't Hand-Roll). **Pin to a specific tag at planning time** (e.g., `v1.20`) per RESEARCH.md § Anti-Patterns.
**Critical anti-pattern (RESEARCH.md § Pitfall 2 + Anti-Patterns):** do NOT bundle Plausible CE in this file — it's AGPL-3.0 and would contaminate self-host distributions. Public instance uses Plausible Cloud only.
**Critical anti-pattern (RESEARCH.md § Pitfall 4):** Mailpit may take 1-3s after container start. Validation tests must use a wait-for-health loop (60s timeout per RESEARCH.md § Validation Architecture); A7 in Assumptions Log flags possible bump to 120s on slow runners.
**Coolify parity rule (RESEARCH.md § Pattern 4 → Coolify deployment notes):** this exact file is consumed by Coolify too. Do not bind public ports for `api`/`web` services when added later — Coolify's Traefik handles external hostnames.
**Phase 0 requirement:** FND-08.

### `docker-compose.override.yml.example` (infra, static)

**Analog:** none in repo — net new.
**Reference:** RESEARCH.md § Anti-Patterns ("Committing `docker-compose.override.yml` directly"). Ship the `.example` file with comments showing dev-only tweaks (port remapping, source bind-mounts for hot reload). The live `docker-compose.override.yml` MUST be in `.gitignore`.

### `.env.example` (config, static)

**Analog:** none in repo — net new.
**Reference snippet:** `00-RESEARCH.md` § Pattern 4 (lines ~388-394). Copy verbatim.
**Variables:** `POSTGRES_USER=gsd`, `POSTGRES_PASSWORD=gsd_dev_password`, `POSTGRES_DB=gsd`, `MAILPIT_SMTP_PORT=1025`, `MAILPIT_UI_PORT=8025`.
**Security note (RESEARCH.md § Phase 0 Specific Security Notes):** `gsd_dev_password` is dev-only — README must warn self-hosters to override before going public.

### `docs/legal/privacy-policy.md` (legal, static doc)

**Analog:** none in repo — net new.
**Reference snippet:** `00-RESEARCH.md` § Code Examples → **Example 9** (lines ~870-940). Copy markdown verbatim.
**Required substitutions:** `{DATE}`, `{INSTANCE_HOSTNAME}`, `{MAINTAINER_NAME}`, `{MAINTAINER_COUNTRY}`, `{ROOT_DOMAIN}`.
**Open Question A3 (RESEARCH.md § Assumptions Log + Open Questions):** maintainer EU-residency drives the controller declaration. **Confirm at start of planning.** If non-EU, GDPR Art. 27 representative may apply.
**Three required granular consents (PRIV-02 — RESEARCH.md § Phase Requirements):** `event_capture`, `public_leaderboards`, `email_digests` must all appear by name. Validation grep tests for all three.
**Anthropic OAuth must be declared "never collected"** — this is the load-bearing architectural rule from CONTEXT.md `<specifics>` and Pitfall 6 in `research/PITFALLS.md`.
**Per CD-04 / RESEARCH.md § Don't Hand-Roll:** clean-room from Plausible's policy + GDPR.eu template; flagged for legal review at flip-day.
**Phase 0 requirements:** PRIV-01, PRIV-02, PRIV-04 (Plausible named, not GA).

### `docs/legal/terms-of-service.md` (legal, static doc)

**Analog:** none in repo — net new.
**Reference snippet:** none in RESEARCH.md (privacy policy is the only fully-drafted legal example). Use clean-room adaptation per CD-04 from Plausible's ToS or Standard Ebooks' ToS.
**Required content:** service description, hobby-project disclaimer mirroring README maintenance posture (D-07 cap reference + FND-07 wording), DCO inbound license clause for any user content, account-deletion path (AUTH-07 forward reference), public-instance shutdown clause referencing `shutdown-plan.md` per FND-05.
**Phase 0 requirement:** PRIV-01.

### `docs/legal/retention-schedule.md` (legal, static doc)

**Analog:** none in repo — net new.
**Reference snippet:** `00-RESEARCH.md` § Code Examples → **Example 6** (lines ~746-772). Copy markdown verbatim.
**Critical (RESEARCH.md § Pitfall 7):** every retention rule must name the **implementing phase**. Example: "Raw events: 90 days. Implemented by `events-cleanup` BullMQ worker in Phase 3." This prevents policy/code drift.
**Account-deletion subsection (AUTH-07 forward reference):** 30-day deletion + 90-day handle-cooldown.
**Phase 0 requirement:** PRIV-03.

### `docs/legal/hosting-cap.md` (legal, static doc)

**Analog:** none in repo — net new.
**Reference snippet:** `00-RESEARCH.md` § Code Examples → **Example 7** (lines ~774-807). Copy markdown verbatim.
**Critical (RESEARCH.md § Pitfall 8 — drift trap):** the SQL definition `SELECT COUNT(*) FROM users WHERE last_signin_at > NOW() - INTERVAL '90 days';` is **load-bearing** — it must appear verbatim. Phase 1's session table will reference `last_signin_at` exactly. Three different "active" definitions across phases is the failure mode.
**Tone (CONTEXT.md `<specifics>`):** plain English, no legalese, single page, links to self-host path per D-07.
**Phase 0 requirement:** FND-04.

### `docs/legal/shutdown-plan.md` (legal, static doc)

**Analog:** none in repo — net new.
**Reference snippet:** `00-RESEARCH.md` § Code Examples → **Example 8** (lines ~809-866). Copy markdown verbatim.
**Required commitments (per D-15 / FND-05 / CONTEXT.md `<specifics>`):**
- 90-day notice
- Full per-user data export (JSON)
- Three shutdown options in priority order (transfer → wind-down → hard close)
- Self-hosters explicitly unaffected
**Critical (RESEARCH.md § Pitfall 9):** the data-export inventory must be concrete enough that a future phase can implement it. List exported fields per-user. The export endpoint itself is a post-Phase-0 backlog item — flag in `.planning/ROADMAP.md` per RESEARCH.md.
**Phase 0 requirement:** FND-05.

### `docs/ops/dns.md` (ops, static doc)

**Analog:** none in repo — net new.
**Reference snippet:** `00-RESEARCH.md` § Code Examples → **Example 5** (lines ~666-744). Copy markdown verbatim.
**Required records:**
- SPF: `v=spf1 include:amazonses.com ~all` on `send.{ROOT_DOMAIN}` (Resend/SES chain).
- MX: `feedback-smtp.{REGION}.amazonses.com` priority 10 on `send.{ROOT_DOMAIN}` (placeholder until Resend dashboard issues actual value).
- DKIM: 1-3 TXT records issued by Resend at domain-add time. Placeholder shape `{SELECTOR}._domainkey.{ROOT_DOMAIN}`.
- DMARC: progressive `none → quarantine → reject` schedule on `_dmarc.{ROOT_DOMAIN}`.
- From-address policy: `noreply@` (transactional) + `hello@` (replyable) per D-12.
**Critical (RESEARCH.md § Pitfall 6):** SPF 10-DNS-lookup limit. v1 single-provider (Resend) is well under. Document the limit so a future second provider doesn't silently break deliverability.
**Phase 0 requirement:** D-11.

### `docs/architecture/00-overview.md` (architecture, static doc)

**Analog:** none in repo — net new.
**Reference:** CONTEXT.md `<specifics>` "Architecture doc" + RESEARCH.md § Architectural Responsibility Map + § Security Domain. No verbatim snippet — this doc must be authored.
**Two load-bearing rules that MUST appear (CONTEXT.md `<specifics>`):**
1. **Helper never asserts game state.** Helper module emits raw signals; backend computes XP/quests/achievements. (Source: `research/SUMMARY.md` and `research/ARCHITECTURE.md`.)
2. **Anthropic OAuth token never reaches the backend.** The token from `~/.claude/.credentials.json` stays on the user's machine. Helper extracts only metadata (model, token-counts, session boundaries). (Source: `research/PITFALLS.md` § Pitfall 6.)
**Three-tier system summary:** helper (CLI on user machine) ↔ backend (Hono API + BullMQ workers) ↔ web (SvelteKit dashboard). Reference `research/ARCHITECTURE.md` for full diagram.
**Pino-redaction rule (PRIV-05):** policy stated here, transport installation deferred to Phase 1. Document the rule: tokens (`sk-ant-`, bearer tokens), email PII, and IP-headers are redacted in all backend logs.
**Plausible Cloud-only rule:** restate the Pitfall 2 mitigation here so future PRs cannot naively add Plausible CE to compose.
**Phase 0 requirement:** PRIV-05 (policy only).

### `README.md` (governance, static doc)

**Analog:** none in repo — net new.
**Reference snippet:** `00-RESEARCH.md` § Code Examples → **Example 4** (lines ~620-664). Copy markdown verbatim.
**Required substitutions:** `{repo-url}` (will resolve at flip-day), `{maintainer-handle}` for the Ko-fi badge URL.
**Verbatim maintenance posture wording (CONTEXT.md `<specifics>` + FND-07):** "This is a hobby project maintained on a best-effort basis. Issues and PRs are welcomed but not guaranteed a response within any specific timeframe. The public hosted instance is capped at 5,000 active accounts; if that fills up, please run your own with `docker compose up`."
**Donations badge (FND-06 / CD-01):** Ko-fi `https://ko-fi.com/img/githubbutton_sm.svg` per RESEARCH.md § Don't Hand-Roll. GitHub Sponsors deferred to flip-day per CD-01.
**Phase 0 requirements:** FND-06, FND-07.

### `package.json` (root) (config, static)

**Analog:** none in repo — net new.
**Reference snippet:** `00-RESEARCH.md` § Code Examples → **Example 1** (lines ~572-590). Copy verbatim.
**Key fields:**
- `"private": true`
- `"license": "Apache-2.0"`
- `"engines": { "node": ">=22.0.0", "pnpm": ">=9.0.0" }`
- `"packageManager": "pnpm@9.15.0"` (Corepack lock)
- Scripts: `compose:up`, `compose:down`, `compose:logs`, `licenses:check`
- `"devDependencies": {}` (intentionally empty; later phases populate)

### `pnpm-workspace.yaml` (config, static)

**Analog:** none in repo — net new.
**Reference snippet:** `00-RESEARCH.md` § Code Examples → **Example 2** (lines ~596-600). Copy verbatim:
```yaml
packages:
  - "apps/*"
  - "packages/*"
```

### `turbo.json` (config, static)

**Analog:** none in repo — net new.
**Reference snippet:** `00-RESEARCH.md` § Code Examples → **Example 3** (lines ~605-615). Copy verbatim.
**Pipelines:** `build`, `test`, `lint`, `typecheck` defined with empty/passthrough config; later phases populate task specifics.

### `apps/{api,web,cli,workers}/package.json` (4 files, placeholder stubs)

**Analog:** none in repo — net new.
**Pattern (per RESEARCH.md § Recommended Project Structure, lines ~229-233):**
```json
{
  "name": "@gsd/{name}",
  "version": "0.0.0",
  "private": true,
  "type": "module"
}
```
**Special case for `apps/cli/package.json`:** add `"bin": "./dist/cli.js"` placeholder per RESEARCH.md project structure (line 232).
**Critical (RESEARCH.md § Recommended Project Structure note, line 243):** every `apps/*` directory MUST have at least a `package.json` and a one-line `README.md` or pnpm workspace resolution warns and Turbo refuses to build.

### `packages/{db,content,shared,ui}/package.json` (4 files, placeholder stubs)

**Analog:** none in repo — net new.
**Pattern:** identical to `apps/*/package.json` stub above with `"name": "@gsd/{db|content|shared|ui}"`.

### `apps/*/README.md` and `packages/*/README.md` (8 placeholder docs)

**Analog:** none in repo — net new.
**Required content:** one-line description per RESEARCH.md § Recommended Project Structure (line 243). Examples: "Hono backend (Phase 1).", "SvelteKit web app (Phase 4).", "Helper CLI (Phase 5).", "BullMQ workers (Phase 3+).", "Drizzle schema + migrations.", "Cosmetics catalog, reserved-handles, themes.", "Zod schemas shared helper↔backend↔web.", "8bitcn/ui copies, NES.css overrides."

### `packages/content/reserved-handles.json` (content, static data)

**Analog:** none in repo — net new.
**Reference snippet:** `00-RESEARCH.md` § Pitfall 5 (lines ~484-518). **Copy structured-shape JSON verbatim.**
**Required schema:**
```json
{
  "version": 1,
  "locked_at": "2026-05-08",
  "entries": [
    { "name": "<handle>", "category": "<system|brand|...>", "reason": "<why>" }
  ]
}
```
**Coverage checklist (target ~200 names, RESEARCH.md § Pitfall 5):**
| Category | Target |
|----------|--------|
| HTTP/system paths | ~40 |
| Common admin/staff roles | ~30 |
| Auth / account terms | ~20 |
| Legal / compliance | ~15 |
| Brand collisions (anthropic, claude, openai, etc.) | ~25 |
| Project-specific protected (gsd, gsd-helper, etc.) | ~20 |
| Reserved gaming/social handles | ~20 |
| Feature/route names | ~15 |
| Squat-target permutations | ~15 |
**Source data:** adapted from `https://github.com/shouldbee/reserved-usernames` (590+ names, MIT) trimmed to project context per RESEARCH.md § Don't Hand-Roll.
**Plan-check warning (RESEARCH.md Pitfall 5):** if any category ends with 0 entries, re-check coverage.
**Phase 0 requirement:** CD-03 (definition only; enforcement Phase 1).

### `scripts/verify-phase-0.sh` (optional tooling, shell script)

**Analog:** none in repo — net new.
**Reference snippet:** `00-RESEARCH.md` § Validation Architecture → Phase Requirements → Test Map (lines ~1106-1124) lists every required smoke and integration assertion. Compose those bash one-liners into a single exit-0/exit-1 script.
**Required checks (verbatim from RESEARCH.md test-map):**
- `[ -f LICENSE ] && grep -q "Apache License" LICENSE && grep -q "Version 2.0" LICENSE`
- `[ -f CONTRIBUTING.md ] && [ -f CODE_OF_CONDUCT.md ]` + grep "Contributor Covenant" + "Signed-off-by"
- grep `5,?000` + grep `90 days` in `docs/legal/hosting-cap.md`
- grep `90 days` + "data export" in `docs/legal/shutdown-plan.md`
- grep `ko-fi.com` (or `opencollective.com`) in `README.md`
- grep "best-effort" or "hobby project" in `README.md`
- `[ -f docs/legal/privacy-policy.md ] && [ -f docs/legal/terms-of-service.md ]`
- grep all three `event_capture`, `public_leaderboards`, `email_digests` in `docs/legal/privacy-policy.md`
- grep `90 days` + `raw events` in `docs/legal/retention-schedule.md`
- grep `plausible.io` AND assert `Google Analytics` does NOT appear (PRIV-04)
- grep "redact" + "token" in `docs/architecture/00-overview.md`
- `cp .env.example .env && docker compose up -d` then 60s wait-for-health loop, then `docker compose down`
- `curl -f http://localhost:8025/readyz` for Mailpit liveness
**Optional vs. required:** the planner may instead inline these as per-task verify-steps in the plan rather than a single script. Either is acceptable.

---

## Shared Patterns

These cross-cutting patterns apply across multiple files. Stating them once here so the planner doesn't re-derive per-file.

### Verbatim copy from canonical URLs
**Apply to:** `LICENSE`, `CODE_OF_CONDUCT.md`.
**Sources:**
- `https://www.apache.org/licenses/LICENSE-2.0.txt`
- `https://www.contributor-covenant.org/version/2/1/code_of_conduct/`
- `https://developercertificate.org/` (referenced from CONTRIBUTING.md, not copied verbatim)
**Anti-pattern (RESEARCH.md § Don't Hand-Roll):** modification breaks SPDX detection and community-health-check tooling. Substitute only contact email / copyright holder per the source's APPENDIX.

### Verbatim copy from RESEARCH.md Code Examples
**Apply to:** `README.md` (Ex 4), `dns.md` (Ex 5), `retention-schedule.md` (Ex 6), `hosting-cap.md` (Ex 7), `shutdown-plan.md` (Ex 8), `privacy-policy.md` (Ex 9), `SECURITY.md` (Ex 11), `CONTRIBUTING.md` (Ex 12), `package.json` (Ex 1), `pnpm-workspace.yaml` (Ex 2), `turbo.json` (Ex 3), `docker-compose.yml` (Pattern 4), `.env.example` (Pattern 4 trailing block), `license-check.yml` (Pattern 2), `dco.yml` (Pattern 3).
**Rationale:** RESEARCH.md already drafted these as load-bearing examples. The planner copies and substitutes only the explicit `{PLACEHOLDERS}`. This is the dominant pattern in Phase 0.

### Placeholder substitution (deferred values)
**Apply to:** every legal/ops doc that mentions a domain/email/maintainer.
**Placeholders (locked at flip-day, not Phase 0):**
- `{ROOT_DOMAIN}` — domain bought in Phase 0 (D-11) but final selection depends on naming (D-14, deferred to Phase 9). Treat as `{ROOT_DOMAIN}` literal until purchase.
- `{MAINTAINER_NAME}`, `{MAINTAINER_EMAIL}`, `{MAINTAINER_COUNTRY}` — fill at planning time from user.
- `{INSTANCE_HOSTNAME}`, `{DATE}` — fill at planning / flip-day.
- `{maintainer-handle}` — Ko-fi handle, set up per CD-01 in Phase 0.
**Rationale:** the documents are committed to a private repo (D-15); placeholders are acceptable until the public flip. Verify the substitution list with the user during planning per Open Question A3.

### Anti-pattern: do not bundle Plausible CE
**Apply to:** `docker-compose.yml`, `docs/architecture/00-overview.md`, `docs/legal/privacy-policy.md`.
**Rule:** Public instance uses **Plausible Cloud** (managed, no AGPL contagion). Self-host docs may *link* to Plausible CE as an optional separate stack but never include it in our compose. The MIT-carved-out tracker `script.js` is fine to embed on web pages.
**Source:** RESEARCH.md § Pitfall 2 + § Anti-Patterns.

### Anti-pattern: do not commit secrets
**Apply to:** `.gitignore`, `.env.example`, every doc that references env values.
**Rule:** `.env`, `*.key`, `*.pem` are gitignored. Only `.env.example` is committed. The Postgres dev-default `gsd_dev_password` is the *only* "credential" in the repo and must be flagged in README as override-before-public.
**Source:** RESEARCH.md § Phase 0 Specific Security Notes + § Security Domain table.

### Anti-pattern: do not pin `:latest` tags in committed compose
**Apply to:** `docker-compose.yml`.
**Rule:** Once Phase 0 selects specific image tags at planning time (e.g., `postgres:17.5-alpine`, `valkey/valkey:8.1-alpine`, `axllent/mailpit:v1.20`), commit the pinned tags. `:latest` is acceptable in `.example` files only.
**Source:** RESEARCH.md § Anti-Patterns.

### Verification pattern: 60-second wait-for-health
**Apply to:** any `docker compose up` validation step (`scripts/verify-phase-0.sh`, plan verify-steps).
**Pattern (from RESEARCH.md § Validation Architecture, line ~1115):**
```bash
docker compose up -d
for i in {1..60}; do
  docker compose ps --format json | jq -e '.[].Health' | grep -q healthy || sleep 1
done
docker compose down
```
**Tunable (RESEARCH.md Assumption A7):** if 60s flakes on slow CI runners, raise to 120s.

### Manual maintainer steps (non-file deliverables)
The planner should also surface these explicit non-file actions:
1. **Buy domain** at Cloudflare Registrar per CD-02 / D-11.
2. **Create Ko-fi account** per CD-01 (FND-06 cannot be live until handle exists).
3. **Set GitHub repo "Require contributors to sign off on web-based commits"** per RESEARCH.md § Pitfall 3 mitigation (closes the squash-merge DCO gap).
4. **Add Plausible Cloud account** at flip-day (not in Phase 0 scope, but flag).
5. **Confirm maintainer EU-residency (Open Question A3)** before locking the privacy-policy controller declaration.

---

## No Analog Found

Every Phase 0 file has no in-repo analog because this is a fresh repo. **All 32 net-new files** route to either RESEARCH.md reference snippets or canonical external URLs. The "no analog" status is expected — Phase 0 is by definition the phase that *establishes* the analogs every later phase will copy.

| File | Role | Routing |
|------|------|---------|
| All 32 net-new files | various | See per-file Pattern Assignments above |

---

## Metadata

**Analog search scope:** entire repo root (excluding `.claude/` workflow tooling per CONTEXT.md, `.git/`, `.planning/` planning artifacts).
**Files scanned in repo:** 0 source files; only `CLAUDE.md` (project orchestrator instructions) and `.planning/*` (planning artifacts) exist.
**Pattern extraction date:** 2026-05-08
**Upstream sources:**
- `00-CONTEXT.md` — user decisions D-01 through D-16, CD-01 through CD-04
- `00-RESEARCH.md` — 12 Code Examples + 4 Patterns + 9 Pitfalls + Validation Architecture
- External canonical URLs (Apache-2.0, Contributor Covenant 2.1, DCO, shouldbee/reserved-usernames)

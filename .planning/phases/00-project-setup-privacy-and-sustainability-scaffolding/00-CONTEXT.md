# Phase 0: Project Setup, Privacy, and Sustainability Scaffolding - Context

**Gathered:** 2026-05-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 0 establishes the OSS posture, legal/privacy ground truth, and self-host parity *before* any product code is written, so every later phase inherits the right defaults. Deliverables: monorepo skeleton (pnpm + Turborepo), license + Code of Conduct + DCO enforcement, privacy policy + ToS + retention schedule + 90-day shutdown plan, granular consent model, hosting cap declaration, donations channel, Plausible analytics scaffolding, Docker Compose stack with email + Postgres + Valkey, CI license-checker that fails on GPL/AGPL/SSPL/RSALv2 dependencies. **No product code, no auth, no game features.**

In scope: repository scaffolding, legal/policy docs, OSS sustainability artifacts, dev fixtures (Mailpit, Postgres, Valkey in compose), CI gates (license check, DCO check, lint baseline), DNS + sender identity records committed to docs.

Out of scope: any auth (Phase 1), any helper code (Phase 5), any UI beyond placeholder web app shell (Phase 4), Pino redaction transport install (Phase 1 — Phase 0 only documents the rule), Anthropic OAuth usage cache (Phase 3).

</domain>

<decisions>
## Implementation Decisions

### License + Code of Conduct
- **D-01:** License is **Apache-2.0** (preferred over MIT for the explicit patent grant). SPDX identifier `Apache-2.0`. LICENSE file at repo root.
- **D-02:** Code of Conduct is **Contributor Covenant 2.1**, unmodified text, with maintainer email substituted for incident reporting. Drop into `CODE_OF_CONDUCT.md` at repo root.
- **D-03:** Outside contributions gated by **DCO sign-off only** — every commit requires `Signed-off-by: Name <email>`. CI enforces via [DCO GitHub App](https://github.com/apps/dco) or equivalent check. No CLA bot.
- **D-04:** Copyright attribution is the single project-style header **`Copyright (c) {year} {Project} Contributors`**. No per-file author lists. Header is NOT required on every source file — relying on root LICENSE is acceptable; new files get the one-line header voluntarily.

### Public Hosting Target & User Cap
- **D-05:** Public instance runs on **Hetzner CX22 + Coolify**. Same Docker Compose images as self-host = parity for free; ~$5-15/mo at hundreds of users aligns with the OSS-plus-donations posture. Coolify is the deploy/control plane.
- **D-06:** Published user cap is **5,000 active accounts** where "active" = signed in at least once in the last 90 days. The number is committed to `docs/legal/hosting-cap.md` with the active definition spelled out.
- **D-07:** Cap-overflow policy is **waitlist + prominent self-host link**. Signup form past the cap shows: "We're at our community cap. Join the waitlist or run your own instance: `docker compose up`." This converts overflow into self-host adoption rather than churn.
- **D-08:** Latency/region target is **single region**, defaulting to **EU (Hetzner Falkenstein)** unless a clear US-pool argument emerges before Phase 0 launch. Multi-region deferred to a future milestone (not v1).

### Email & Operational Dependencies
- **D-09:** Public-instance email provider is **Resend** (3k/mo free tier; SMTP fallback also exposed). Self-host instances use **`SMTP_URL`** env var with any SMTP-compatible provider — Resend / Postmark / SES / Mailgun / personal SMTP all work.
- **D-10:** Local-dev and Docker Compose default mail catcher is **Mailpit** on port `:8025` (web UI) + `:1025` (SMTP). Self-hosters get a working local UI out of the box; dev gets clickable verification links.
- **D-11:** Domain is **bought in Phase 0**. Sender = `noreply@{domain}`. SPF / DKIM / DMARC records committed to `docs/ops/dns.md` even before DNS goes live, so flipping the switch is a config change, not a research project. (Domain choice itself depends on the project name decision — see D-14.)
- **D-12:** From-address policy: **`noreply@` for transactional**, **`hello@` replyable for support**. Hello@ forwards to the maintainer inbox. No per-purpose addresses (no `verify@`, `pair@`, etc.) at v1.

### Repository Host & Final Branding
- **D-13:** Canonical repo lives on **GitHub**. Best discovery, GitHub Actions CI, native DCO bot, GitHub Sponsors integration once visibility flips public.
- **D-14:** Project stays on the **working title "Claude Code Gamification Service"** (and placeholder package names like `gsd-helper`, `gsd-server`) until **Phase 9 launch readiness**. Final naming happens with the product fully shaped, not under Phase 0 pressure.
- **D-15 (USER OVERRIDE of recommendation):** Repo stays **private until the maintainer flips it public** — no fixed phase. All Phase 0 deliverables (legal docs, hosting cap, shutdown plan, etc.) get written to the private repo and become accessible at flip-day. CONTRIBUTING.md, CoC, DCO check are in place from day one regardless of visibility.
- **D-16:** **No mirror at v1.** GitHub is the single source of truth. DR via tagged-release `git bundle` uploads is deferred to a future maintenance phase if a maintainer-bus-factor concern arises.

### Claude's Discretion
- **CD-01: Donations channel selection.** GitHub Sponsors requires a public profile/repo to actually accept donations, which conflicts with D-15 (private until flip). To still satisfy FND-06 in Phase 0: set up **Ko-fi** or **OpenCollective** now (works without a public repo), and add GitHub Sponsors at flip-day. README and (placeholder) web app footer link to whichever donations destination is live. Recommended default: **Ko-fi** for lightest setup; switchable to OpenCollective if fiscal-host transparency becomes a priority.
- **CD-02: Domain registrar.** Cloudflare Registrar (at-cost pricing, free WHOIS privacy) is the default unless the maintainer has a strong preference. Locks in only after a name candidate clears trademark/availability checks.
- **CD-03: Reserved-handle list authoring.** The ~200-name reserved list referenced in IDENT-02 is *defined* in Phase 0 as a JSON file under `packages/content/reserved-handles.json`, even though enforcement is Phase 1. This avoids a last-minute scramble.
- **CD-04: Privacy-policy / ToS authoring approach.** Start from a permissive-OSS template (e.g., a clean-room adaptation of Plausible's or Standard Ebooks' policy) and customize for the project's specific data flows. Cheaper than a lawyer at v1; flagged for legal review at the visibility flip / launch.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project-level (locked decisions)
- `.planning/PROJECT.md` — vision, constraints, key decisions table, out-of-scope reasons
- `.planning/REQUIREMENTS.md` — 154 v1 REQ-IDs; Phase 0 owns FND-01 through FND-08 + PRIV-01 through PRIV-05
- `.planning/ROADMAP.md` — 11-phase horizontal-layer plan, dependencies, success criteria
- `.planning/STATE.md` — current position, deferred research questions

### Research synthesis (use during planning)
- `.planning/research/SUMMARY.md` — canonical phase-by-phase brief; cross-cutting decisions to lock now
- `.planning/research/STACK.md` — stack rationale; license-audit chains, version pins
- `.planning/research/PITFALLS.md` — Pitfall 7 (maintainer burnout) and Pitfall 6 (token leakage doc rule) ground Phase 0 deliverables
- `.planning/research/ARCHITECTURE.md` — three-tier system; helper-never-asserts-game-state architectural rule (must be written into the architecture doc Phase 0 produces)
- `.planning/research/FEATURES.md` — anti-features list; reasons for the no-shop / no-random-drops / no-DMs decisions

### External references (consult during planning, not at runtime)
- Apache-2.0 license text — `https://www.apache.org/licenses/LICENSE-2.0`
- Contributor Covenant 2.1 — `https://www.contributor-covenant.org/version/2/1/code_of_conduct/`
- DCO text — `https://developercertificate.org/`
- Coolify docs — `https://coolify.io/docs/` (consult via context7 mcp at planning time)
- Resend docs + DKIM/DMARC setup — `https://resend.com/docs/` (consult via context7 mcp at planning time)
- Mailpit docs — `https://mailpit.axllent.org/docs/` (consult via context7 mcp at planning time)

### Phase 0 will produce (written here so future phases can reference back)
- `LICENSE`, `CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`, `SECURITY.md`, `README.md` at repo root
- `docs/legal/privacy-policy.md`, `docs/legal/terms-of-service.md`, `docs/legal/retention-schedule.md`, `docs/legal/hosting-cap.md`, `docs/legal/shutdown-plan.md`
- `docs/ops/dns.md` — SPF / DKIM / DMARC records
- `docs/architecture/00-overview.md` — three-tier system; helper-never-asserts-game-state rule
- `docker-compose.yml` — Postgres 17 + Valkey 8 + Mailpit fixture
- `.github/workflows/license-check.yml`, `.github/workflows/dco.yml`
- `packages/content/reserved-handles.json` — ~200 reserved names (definition only; enforcement Phase 1)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None — this is a fresh project. Only `.planning/` (planning artifacts), `.claude/` (workflow scaffolding), and `CLAUDE.md` (orchestrator instructions) exist at repo root.

### Established Patterns
- Repository convention: planning artifacts live under `.planning/`; phase work goes under `.planning/phases/{padded}-{slug}/`. Phase 0 must NOT pollute repo root with planning files.
- Workflow tooling lives under `.claude/get-shit-done/`. Phase 0 must NOT touch this directory — it's tool-managed.

### Integration Points
- Phase 0 produces the monorepo layout that every later phase inherits. Recommended layout from `research/SUMMARY.md` and `research/STACK.md`:
  ```
  apps/
    api/        # Hono backend (Phase 1)
    web/        # SvelteKit web app (Phase 4)
    cli/        # Helper CLI (Phase 5)
    workers/    # BullMQ workers (Phase 3+)
  packages/
    db/         # Drizzle schema + migrations
    content/    # cosmetics catalog, reserved-handles, themes
    shared/     # Zod schemas shared helper↔backend↔web
    ui/         # 8bitcn/ui copies, NES.css overrides
  docs/
    legal/      # privacy, ToS, retention, hosting-cap, shutdown-plan
    ops/        # dns, deploy, runbooks
    architecture/  # overview, ADRs
  ```
- pnpm workspaces + Turborepo from `research/STACK.md` is the locked tooling — `pnpm-workspace.yaml` + `turbo.json` ship in Phase 0.

</code_context>

<specifics>
## Specific Ideas

- **Maintenance posture wording for README:** "This is a hobby project maintained on a best-effort basis. Issues and PRs are welcomed but not guaranteed a response within any specific timeframe. The public hosted instance is capped at 5,000 active accounts; if that fills up, please run your own with `docker compose up`."
- **Hosting cap document tone:** Plain English, no legalese. Single page. Defines "active", explains the cap, links to the self-host path.
- **Shutdown plan tone:** Same. Commits to **90 days notice**, **full data export per user before close**, and **transfer plan or graceful close** for the public instance. Self-hosters are unaffected by hosted-instance shutdown by definition.
- **Architecture doc:** Must call out the **two load-bearing rules** from `research/SUMMARY.md`: (1) helper never asserts game state, and (2) Anthropic OAuth token never reaches the backend. These rules are *codified* here so all later phases can reference them.

</specifics>

<deferred>
## Deferred Ideas

- **Final product name** — deferred to Phase 9 launch readiness per D-14.
- **Repo visibility flip date** — maintainer's call, not phase-bound per D-15.
- **GitHub Sponsors activation** — deferred to flip-day per CD-01.
- **DR mirror to second host** — deferred until maintainer-bus-factor concern arises per D-16.
- **Multi-region hosting** — deferred to a post-v1 milestone per D-08.
- **Per-purpose email addresses** (`verify@`, `pair@`, `security@`, etc.) — deferred until volume justifies it per D-12.
- **Legal review of privacy policy / ToS** — deferred to visibility-flip / launch per CD-04.

### Reviewed Todos (not folded)
None — no todo infrastructure set up yet.

</deferred>

---

*Phase: 0-Project Setup, Privacy, and Sustainability Scaffolding*
*Context gathered: 2026-05-08*

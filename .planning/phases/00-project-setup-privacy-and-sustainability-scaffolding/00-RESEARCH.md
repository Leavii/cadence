# Phase 0: Project Setup, Privacy, and Sustainability Scaffolding - Research

**Researched:** 2026-05-08
**Domain:** OSS project scaffolding — license, governance, privacy/legal docs, CI gates, Docker Compose self-host parity, sustainability artifacts. **No product code.**
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### License + Code of Conduct
- **D-01:** License is **Apache-2.0** (preferred over MIT for the explicit patent grant). SPDX identifier `Apache-2.0`. LICENSE file at repo root.
- **D-02:** Code of Conduct is **Contributor Covenant 2.1**, unmodified text, with maintainer email substituted for incident reporting. Drop into `CODE_OF_CONDUCT.md` at repo root.
- **D-03:** Outside contributions gated by **DCO sign-off only** — every commit requires `Signed-off-by: Name <email>`. CI enforces via DCO GitHub App or equivalent check. No CLA bot.
- **D-04:** Copyright attribution is the single project-style header `Copyright (c) {year} {Project} Contributors`. No per-file author lists. Header is NOT required on every source file — relying on root LICENSE is acceptable; new files get the one-line header voluntarily.

#### Public Hosting Target & User Cap
- **D-05:** Public instance runs on **Hetzner CX22 + Coolify**. Same Docker Compose images as self-host = parity for free.
- **D-06:** Published user cap is **5,000 active accounts** where "active" = signed in at least once in the last 90 days.
- **D-07:** Cap-overflow policy is **waitlist + prominent self-host link**.
- **D-08:** Latency/region target is **single region**, defaulting to **EU (Hetzner Falkenstein)**.

#### Email & Operational Dependencies
- **D-09:** Public-instance email provider is **Resend** (3k/mo free tier; SMTP fallback also exposed). Self-host instances use **`SMTP_URL`** env var.
- **D-10:** Local-dev and Docker Compose default mail catcher is **Mailpit** on port `:8025` (web UI) + `:1025` (SMTP).
- **D-11:** Domain is **bought in Phase 0**. Sender = `noreply@{domain}`. SPF / DKIM / DMARC records committed to `docs/ops/dns.md` even before DNS goes live.
- **D-12:** From-address policy: **`noreply@` for transactional**, **`hello@` replyable for support**. No per-purpose addresses at v1.

#### Repository Host & Final Branding
- **D-13:** Canonical repo lives on **GitHub**.
- **D-14:** Project stays on the working title "Claude Code Gamification Service" (placeholder package names like `gsd-helper`, `gsd-server`) until Phase 9 launch readiness.
- **D-15 (USER OVERRIDE):** Repo stays **private until the maintainer flips it public** — no fixed phase. All Phase 0 deliverables get written to the private repo and become accessible at flip-day.
- **D-16:** **No mirror at v1.** GitHub is the single source of truth.

### Claude's Discretion

- **CD-01: Donations channel selection.** Set up **Ko-fi** or **OpenCollective** now (works without a public repo). Add GitHub Sponsors at flip-day. Recommended default: **Ko-fi** for lightest setup.
- **CD-02: Domain registrar.** Cloudflare Registrar (at-cost pricing, free WHOIS privacy) is the default unless maintainer prefers otherwise.
- **CD-03: Reserved-handle list authoring.** Define ~200 names in `packages/content/reserved-handles.json` (definition only; enforcement Phase 1).
- **CD-04: Privacy-policy / ToS authoring approach.** Start from a permissive-OSS template (Plausible, Standard Ebooks, etc.); flagged for legal review at visibility flip / launch.

### Deferred Ideas (OUT OF SCOPE)

- **Final product name** — deferred to Phase 9 launch readiness per D-14.
- **Repo visibility flip date** — maintainer's call, not phase-bound per D-15.
- **GitHub Sponsors activation** — deferred to flip-day per CD-01.
- **DR mirror to second host** — deferred until maintainer-bus-factor concern arises per D-16.
- **Multi-region hosting** — deferred to a post-v1 milestone per D-08.
- **Per-purpose email addresses** (`verify@`, `pair@`, `security@`, etc.) — deferred until volume justifies it per D-12.
- **Legal review of privacy policy / ToS** — deferred to visibility-flip / launch per CD-04.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FND-01 | Codebase published under permissive OSS license (Apache-2.0 preferred) | D-01 + Apache-2.0 LICENSE template (verbatim from `https://www.apache.org/licenses/LICENSE-2.0.txt`) |
| FND-02 | CI fails any PR introducing GPL/AGPL/SSPL/RSALv2 transitive dep | License-check CI workflow (see "License Compliance CI" section) |
| FND-03 | Repo ships with `CONTRIBUTING.md` and a published Code of Conduct | Contributor Covenant 2.1 verbatim + DCO-only CONTRIBUTING.md template |
| FND-04 | Public hosted instance enforces published user-count cap with overflow policy | `docs/legal/hosting-cap.md` content shape (see "Hosting Cap Doc" section) |
| FND-05 | Public shutdown plan documents 90-day notice + full data export path | `docs/legal/shutdown-plan.md` content shape (see "Shutdown Plan" section) |
| FND-06 | Donations channel linked from README and web app footer | Ko-fi setup (CD-01) — README badge + footer link |
| FND-07 | README states maintenance posture (hobby project, best-effort) | Maintenance-posture wording (verbatim from CONTEXT.md `<specifics>`) |
| FND-08 | `docker-compose.yml` boots self-hosted instance from same images as public instance | Compose skeleton with Postgres 17, Valkey 8, Mailpit (see "Docker Compose Stack" section) |
| PRIV-01 | Privacy policy + ToS linked from every page footer | `docs/legal/privacy-policy.md`, `docs/legal/terms-of-service.md` (placeholder web-app footer integrated in Phase 4) |
| PRIV-02 | Granular consent model: separate consents for event capture / public leaderboards / email digests | Consent-record schema sketch (see "Granular Consent Model" section) |
| PRIV-03 | Raw events retention 90 days; aggregates may be retained indefinitely | `docs/legal/retention-schedule.md` template |
| PRIV-04 | Public hosted instance uses Plausible (not Google Analytics) | Plausible Cloud (NOT Plausible CE — see "Plausible Licensing" section) |
| PRIV-05 | All API tokens and sensitive headers redacted in logs (POLICY only — install in Phase 1) | Architecture doc rule + Pino redaction transport documented for Phase 1 to install |

</phase_requirements>

## Summary

Phase 0 is a **documentation, configuration, and CI scaffolding phase**. There is no production code. Everything that ships is one of: a markdown doc, a YAML workflow, a JSON config, a `docker-compose.yml`, a `pnpm-workspace.yaml` / `turbo.json` skeleton, or a placeholder app directory. The bar for "done" is `docker compose up` boots cleanly, two CI workflows (license-check, DCO) gate every PR, and every legal/sustainability doc the project will lean on for the rest of its life is committed.

The phase has **two non-obvious traps** that the planner must engineer around:

1. **The private-repo gap.** Per D-15 the repo stays private until flip-day. GitHub's first-party `actions/dependency-review-action` only works on private repos with **GitHub Advanced Security (GHAS)**, which is a paid org-tier add-on. So the license-check CI **cannot** be the GitHub-native action — it must be a runs-on-anywhere alternative (recommended: `pnpm licenses list --json` parsed by a tiny script, or `license-checker-rseidelsohn`). Swap to `dependency-review-action` at flip-day if desired (cheap follow-up).

2. **Plausible's split licensing.** The Plausible **Community Edition (self-host)** is **AGPL-3.0** — explicitly contagious. The Plausible **Cloud (managed)** has no licensing obligations on consumers. The Plausible **JS tracker** (script.js) is deliberately carved out as **MIT** so embedding it on an Apache-2.0 site is fine. **For the public hosted instance: use Plausible Cloud.** **Do NOT** ship Plausible CE in our `docker-compose.yml` — the AGPL would attach to anyone running our Docker bundle. Self-hosters who want analytics can run their own Plausible CE separately or skip analytics entirely.

**Primary recommendation:** Plan Phase 0 as four parallelizable workstreams — (A) Repo + License + CoC + DCO + CI, (B) Docker Compose stack with Postgres 17 + Valkey 8 + Mailpit, (C) Legal docs (privacy, ToS, retention, hosting-cap, shutdown-plan, DNS), (D) Sustainability + content scaffolding (Ko-fi, README, reserved-handles.json, architecture doc). They share no files; final integration is a single PR that wires them together.

## Architectural Responsibility Map

This phase ships no runtime code, so the tier mapping is for **artifacts** rather than capabilities. It exists so the planner can sanity-check that no Phase 0 artifact is mis-scoped to a tier that doesn't exist yet.

| Capability / Artifact | Primary Tier | Secondary Tier | Rationale |
|------------------------|-------------|----------------|-----------|
| Repo-root legal/governance docs (LICENSE, CoC, CONTRIBUTING, SECURITY, README) | Repository / governance | — | Project metadata, not code |
| `docs/legal/*.md` (privacy, ToS, retention, hosting-cap, shutdown-plan) | Repository / governance | Frontend (footer link, Phase 4) | Authored here, surfaced from web in Phase 4 |
| `docs/ops/dns.md` (SPF/DKIM/DMARC) | Operations / DNS | — | DNS-zone config, no app touchpoint |
| `docs/architecture/00-overview.md` | Architecture | All future tiers | Codifies cross-cutting rules (helper-never-asserts; token-never-reaches-backend) |
| `docker-compose.yml` (Postgres + Valkey + Mailpit) | Local dev + self-host | Coolify-deployed public instance | Same images on both — that's the parity rule |
| `.github/workflows/license-check.yml` | CI | — | Runs in GitHub Actions runner, not a project tier |
| `.github/workflows/dco.yml` | CI | — | Same |
| `packages/content/reserved-handles.json` | Shared content (definition) | API / DB (enforcement Phase 1) | Definition lives in `packages/content/`; consumed by Phase 1's signup handler |
| Monorepo skeleton (`pnpm-workspace.yaml`, `turbo.json`, `apps/*`, `packages/*`) | Build tooling | All tiers | Workspace shape every later phase inherits |

**Tier guard:** No Phase 0 artifact should reference an `apps/api` route, `apps/web` page, or any product table. Architectural rules go in `docs/architecture/` as English prose. Code-level enforcement comes in later phases.

## Standard Stack

This phase introduces tooling but **no runtime libraries**. Everything below is config/infra-only.

### Core (Phase 0 actually installs / pins these)

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| **pnpm** | 9.x | Package manager + workspaces | Locked in research/STACK.md. `pnpm-workspace.yaml` + `pnpm licenses list` for license CI. [VERIFIED: pnpm 9 is current LTS-line; npm view pnpm shows 9.x active] |
| **Turborepo** | 2.x | Monorepo build orchestration | Locked in research/STACK.md as lighter than Nx for our shape. [CITED: turbo.build/repo/docs] |
| **Node.js** | 22 LTS | Runtime (versioned in `engines` field; no actual code yet) | Locked in research/STACK.md. Node 22 LTS supported until Apr 2027. [CITED: nodejs.org/en/about/previous-releases] |
| **Postgres image** | `postgres:17-alpine` (pin to `postgres:17.5-alpine` once committed) | Compose service | Postgres 17 = locked DB. 17-alpine is ~50 MB, fast cold-start. [VERIFIED: Docker Hub - postgres:17-alpine digest sha256:6e8e5deb...; postgres:17.5-alpine sha256:6211f56e...] |
| **Valkey image** | `valkey/valkey:8-alpine` (pin to `valkey/valkey:8.1-alpine`) | Compose service | BSD-3, wire-compatible Redis fork. [VERIFIED: Docker Hub - valkey/valkey:8.1.7-alpine is current as of search] |
| **Mailpit image** | `axllent/mailpit:latest` (pin to a specific `v1.x` tag at planning time) | Compose service | MIT license, single binary. Native HEALTHCHECK with `/readyz` endpoint. [VERIFIED: hub.docker.com/r/axllent/mailpit; healthcheck endpoint confirmed in Mailpit docs] |
| **GitHub Actions** | — | CI runtime | D-13. Free tier sufficient for a private repo at this stage. |

### Supporting (Phase 0 references these but installs nothing yet)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| **license-checker-rseidelsohn** | 4.4.x | Active fork of license-checker | License-check CI **alternative** if `pnpm licenses list --json` proves insufficient. [VERIFIED: npm view license-checker-rseidelsohn — 4.4.2, last published 2024-09-09. Original `license-checker` last published 2022-06-19 = effectively abandoned.] |
| **@pnpm/license-scanner** | 1001.x | pnpm-native license auditor | Alternative if monorepo edge cases hit. [VERIFIED: npm view @pnpm/license-scanner — 1001.0.40, published 2026-05-06 = actively maintained] |
| **actions/dependency-review-action** | v5 | GitHub-native license + vuln check | **Adopt at flip-day** when repo goes public (works on public repos without GHAS). Until then, use the pnpm-based workflow below. [CITED: github.com/actions/dependency-review-action — "available for: Public repositories; Private repositories with a GitHub Advanced Security license"] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `pnpm licenses list --json` script | `license-checker-rseidelsohn` | If pnpm's built-in scanner has gaps we hit during planning, drop in license-checker-rseidelsohn. Both work on private repos; `pnpm licenses list` is zero-deps which is simpler. |
| `pnpm licenses list --json` script | `actions/dependency-review-action` | Defer to flip-day per private-repo gap above. |
| **DCO GitHub App (`github.com/apps/dco`)** | **CNCF dco2** OR **GitHub Action `KineticCafe/actions-dco`** | Probot DCO app: last release Jan 2022, known squash-merge bug ([CITED: github.com/probot/dco/issues/126]). dco2 is the CNCF Rust rewrite, drop-in compatible. KineticCafe's action runs in workflow (no installed app needed) and is the lightest path for a private repo. **Recommend: `KineticCafe/actions-dco@v2` GitHub Action** — runs in repo, no installed app to manage, no squash-merge gotcha. |
| Plausible CE in our compose | **Plausible Cloud** for public instance; **no analytics** in self-host compose | Plausible CE is AGPL-3.0; bundling it = our Docker image becomes AGPL-encumbered for redistributors. [CITED: plausible/analytics README — "Plausible CE is open source under the GNU Affero General Public License Version 3 (AGPLv3)"] |
| Ko-fi | OpenCollective | Ko-fi: zero-setup, ~5% fees, no fiscal-host required, README badge ready in 5 min. OpenCollective: requires a fiscal host (legal entity holding funds) which is overkill for hobby-scale. **Recommend Ko-fi** per CD-01 default. Switch to OpenCollective only if maintainer wants formal fiscal sponsorship. [CITED: help.ko-fi.com — github integration; opencollective.com docs/help/fiscal-hosts] |

**No `npm install` runs in Phase 0** — there are no app dependencies yet. The first `pnpm install` happens in Phase 1.

**Version verification** (run during planning right before authoring `package.json` workspace stubs):
```bash
npm view pnpm version          # confirm 9.x current
npm view turbo version         # confirm 2.x current
npm view license-checker-rseidelsohn version
docker pull postgres:17-alpine && docker inspect postgres:17-alpine | grep Created
docker pull valkey/valkey:8-alpine && docker inspect valkey/valkey:8-alpine | grep Created
docker pull axllent/mailpit:latest && docker inspect axllent/mailpit:latest | grep Created
```

## Architecture Patterns

### System Architecture Diagram (Phase 0 Artifacts)

```
                       Repo Root
                          │
        ┌──────────┬──────┴──────┬───────────────────┐
        │          │             │                   │
   LICENSE      .github/    docker-compose.yml    docs/
   CODE_OF_     workflows/        │                   │
   CONDUCT.md       │             │           ┌───────┼─────────┐
   CONTRIBUT-       ├── license-  │           │       │         │
   ING.md           │   check.yml │       legal/   ops/    architecture/
   SECURITY.md      └── dco.yml   │       (5 docs) (dns.md) (00-overview.md)
   README.md            │         │
                        │   ┌─────┼──────┐
                ┌───────┴┐  │     │      │
                │ runs   │  Postgres   Valkey   Mailpit
                │ on PR  │  17-alpine  8-alpine latest
                │ block  │  port 5432  port 6379 ports 1025/8025
                │ on bad │  named vol  named vol named vol
                │ license│  healthcheck healthcheck healthcheck
                │ or no  │
                │ DCO    │
                └────────┘

   Monorepo skeleton:
   pnpm-workspace.yaml ── turbo.json
        │
        ├── apps/{api,web,cli,workers}/  (empty placeholder dirs with stub package.json)
        └── packages/{db,content,shared,ui}/  (empty placeholder dirs)
                              │
                              └── content/reserved-handles.json (~200 names)
```

**Data flow at this stage:**
- Contributor opens PR → GitHub triggers `license-check.yml` and `dco.yml` workflows in parallel.
- license-check runs `pnpm install --frozen-lockfile` then `pnpm licenses list --json` and pipes output through a small denylist script.
- dco-check parses every commit's trailer, fails if any commit lacks `Signed-off-by:`.
- Both gates green → PR can merge.

For the eventual Coolify deployment (out of Phase 0 but architecturally relevant): Coolify watches the GitHub repo, on push to `main` runs the same `docker-compose.yml`, with overrides via `docker-compose.override.yml` or a Coolify-set env file. Self-host parity (D-05, FND-08) holds because Coolify uses the *exact same* `docker-compose.yml` a self-hoster runs.

### Recommended Project Structure

```
{repo-root}/
├── LICENSE                              # Apache-2.0 verbatim
├── CODE_OF_CONDUCT.md                   # Contributor Covenant 2.1 verbatim, maintainer email substituted
├── CONTRIBUTING.md                      # DCO-only, no CLA, sign-off instructions
├── SECURITY.md                          # Vuln-disclosure email + GPG key (if any) + SLA expectations
├── README.md                            # Maintenance posture + cap + donations + quickstart
├── .gitignore                           # Standard Node.js + macOS + Windows ignores
├── .editorconfig                        # 2-space indent, LF newlines (cross-platform sanity)
├── docker-compose.yml                   # Postgres 17 + Valkey 8 + Mailpit (no app images yet)
├── docker-compose.override.yml.example  # Dev-only tweaks template (NOT committed live)
├── .env.example                         # POSTGRES_*, VALKEY_*, MAILPIT_* defaults
├── pnpm-workspace.yaml                  # apps/* + packages/*
├── turbo.json                           # Empty pipelines; populated as phases add tasks
├── package.json                         # Root: workspaces, scripts ("compose:up", "licenses:check")
├── .github/
│   ├── workflows/
│   │   ├── license-check.yml            # Fail PR on AGPL/GPL/SSPL/RSALv2
│   │   └── dco.yml                      # Fail PR on missing Signed-off-by
│   ├── ISSUE_TEMPLATE/                  # Bug + feature templates
│   └── PULL_REQUEST_TEMPLATE.md         # DCO checkbox reminder
├── docs/
│   ├── legal/
│   │   ├── privacy-policy.md
│   │   ├── terms-of-service.md
│   │   ├── retention-schedule.md
│   │   ├── hosting-cap.md
│   │   └── shutdown-plan.md
│   ├── ops/
│   │   └── dns.md                       # SPF/DKIM/DMARC + placeholders
│   └── architecture/
│       └── 00-overview.md               # 3-tier; helper-never-asserts; token-never-leaves-helper
├── apps/
│   ├── api/        package.json (stub: name "@gsd/api", private, "type":"module")
│   ├── web/        package.json (stub)
│   ├── cli/        package.json (stub: name "@gsd/cli", "bin":"./dist/cli.js" placeholder)
│   └── workers/    package.json (stub)
└── packages/
    ├── db/         package.json (stub)
    ├── content/
    │   ├── package.json (stub)
    │   └── reserved-handles.json        # ~200 names, definition only
    ├── shared/     package.json (stub)
    └── ui/         package.json (stub)
```

**Empty `apps/*` and `packages/*` directories must contain at minimum a `package.json` with `"private": true` and a one-line `README.md`.** Otherwise pnpm workspace resolution warns and Turbo refuses to build.

### Pattern 1: Repo-root governance file convention

**What:** Six top-level files form a recognizable OSS-project signature: `LICENSE`, `CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`, `SECURITY.md`, `README.md`, plus a `.github/` directory.
**When to use:** Always for OSS projects. GitHub auto-surfaces these in the repo "Community Standards" tab and on the project sidebar.
**Example:** Standard adoption — see `github.com/sveltejs/kit`, `github.com/honojs/hono`, `github.com/vitejs/vite`. [CITED]

### Pattern 2: License-checking CI on a private repo

**What:** Run `pnpm install` then `pnpm licenses list --json` and grep/jq for banned SPDX IDs. Fails the PR if any dep is GPL/AGPL/SSPL/RSALv2.
**When to use:** Until repo flips public; then optionally additionally enable `actions/dependency-review-action`.
**Example:**
```yaml
# .github/workflows/license-check.yml
name: License Check
on:
  pull_request:
    branches: [main]
permissions:
  contents: read
jobs:
  check-licenses:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with:
          version: 9
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'pnpm'
      - run: pnpm install --frozen-lockfile --ignore-scripts
      # pnpm licenses list outputs JSON keyed by license; we fail if banned keys are present.
      - name: Fail on banned licenses
        shell: bash
        run: |
          pnpm licenses list --json > /tmp/licenses.json
          BANNED='GPL-2.0|GPL-3.0|AGPL-1.0|AGPL-3.0|LGPL-2.1|LGPL-3.0|SSPL-1.0|RSAL-2.0|RSALv2'
          if grep -E "\"($BANNED)\"" /tmp/licenses.json > /tmp/hits.txt; then
            echo "::error::Banned license detected:"
            cat /tmp/hits.txt
            exit 1
          fi
          echo "OK: no banned licenses found."
```
**Source:** Composed from `pnpm.io/cli/licenses` (pnpm's own list command) + GitHub Actions standard patterns. `--ignore-scripts` is a hardening flag — license-checking should not require running install scripts. `[VERIFIED: pnpm licenses list --json` is the documented command, see pnpm CLI docs]

**Note for planner:** The exact banned-SPDX list above (`GPL-2.0|GPL-3.0|AGPL-1.0|AGPL-3.0|LGPL-2.1|LGPL-3.0|SSPL-1.0|RSAL-2.0|RSALv2`) covers FND-02's "GPL/AGPL/SSPL/RSALv2" plus LGPL out of caution. Dual-licensed packages where one branch is permissive (e.g., Argon2 = `CC0-1.0 OR Apache-2.0`) appear in `pnpm licenses list` keyed by SPDX expression; the regex above won't match these because they're inside a longer string like `"CC0-1.0 OR Apache-2.0"`. Verify this on a fixture during plan-check; if false-positives appear, switch to `jq` parsing of the JSON instead of grep.

### Pattern 3: DCO enforcement via workflow (no installed app)

**What:** A small GitHub Action workflow that calls `KineticCafe/actions-dco@v2` (or equivalent) on every PR commit.
**When to use:** When you want DCO enforcement that works on private repos with no installed app and no squash-merge gotcha.
**Example:**
```yaml
# .github/workflows/dco.yml
name: DCO
on:
  pull_request:
    branches: [main]
permissions:
  contents: read
  pull-requests: read
jobs:
  dco:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0   # need full history for the trailer scan
      - uses: KineticCafe/actions-dco@v2
        with:
          repo-token: ${{ github.token }}
```
**Source:** [CITED: github.com/marketplace/actions/enforce-dco-sign-off — "Enforce DCO Sign-off" / `KineticCafe/actions-dco`, MIT-licensed action]
**Squash-merge note:** Because this runs against PR commits (not the eventual merge commit), the squash-merge bug that affects `github.com/apps/dco` (lost sign-off line on squash) is irrelevant — we gate the *PR commits*, and squash is the merge-time concern. Configure GitHub repo settings to **require sign-off on web-based commits** (Settings → Repository → "Require contributors to sign off on web-based commits") to close the loop. [CITED: github.blog/changelog/2022-06-07-admins-can-require-sign-off-on-web-based-commits/]

### Pattern 4: Docker Compose with healthchecks + same images public ↔ self-host

**What:** Single `docker-compose.yml` with three services (Postgres, Valkey, Mailpit), named volumes, healthchecks, and a single named network. No app images yet — those land in Phase 1.
**When to use:** Always. This file is the parity contract per FND-08.
**Example:**
```yaml
# docker-compose.yml
# Phase 0 baseline — apps/api, apps/web, apps/workers added in later phases via the same file.
# Public instance (Hetzner CX22 + Coolify) and self-host run THIS file. Dev-only tweaks
# go in docker-compose.override.yml (gitignored or .example only).
services:
  postgres:
    image: postgres:17-alpine
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-gsd}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-gsd_dev_password}
      POSTGRES_DB: ${POSTGRES_DB:-gsd}
    volumes:
      - postgres-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-gsd} -d ${POSTGRES_DB:-gsd}"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks: [gsd-net]

  valkey:
    image: valkey/valkey:8-alpine
    restart: unless-stopped
    command: ["valkey-server", "--appendonly", "yes"]
    volumes:
      - valkey-data:/data
    healthcheck:
      test: ["CMD", "valkey-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks: [gsd-net]

  mailpit:
    image: axllent/mailpit:latest   # pin to a specific tag at planning time, e.g. v1.20
    restart: unless-stopped
    ports:
      - "${MAILPIT_SMTP_PORT:-1025}:1025"
      - "${MAILPIT_UI_PORT:-8025}:8025"
    environment:
      MP_MAX_MESSAGES: 5000
      MP_DATABASE: /data/mailpit.db
      MP_SMTP_AUTH_ACCEPT_ANY: 1
      MP_SMTP_AUTH_ALLOW_INSECURE: 1
    volumes:
      - mailpit-data:/data
    # Mailpit has a built-in HEALTHCHECK in its Dockerfile (uses `mailpit readyz`).
    networks: [gsd-net]

volumes:
  postgres-data:
  valkey-data:
  mailpit-data:

networks:
  gsd-net:
    driver: bridge
```
And a matching `.env.example`:
```
POSTGRES_USER=gsd
POSTGRES_PASSWORD=gsd_dev_password
POSTGRES_DB=gsd
MAILPIT_SMTP_PORT=1025
MAILPIT_UI_PORT=8025
```
**Source:** [VERIFIED: hub.docker.com/_/postgres healthcheck pattern; hub.docker.com/r/axllent/mailpit Dockerfile has built-in HEALTHCHECK on `/readyz`; valkey-cli ping is the canonical Valkey/Redis liveness check]

**Adding app images later (Phase 1+):** New service blocks (`api`, `web`, `workers`) are *appended* to this file. The override pattern (`docker-compose.override.yml`) is **only** for dev-only tweaks (port remapping, mounting source for hot reload). Dev-vs-public divergence stays opt-in.

**Coolify deployment notes:**
- Coolify watches the GitHub repo (push-to-deploy or webhook).
- It expects a `docker-compose.yml` at repo root and an env file you configure in the Coolify UI (NOT in git).
- Coolify uses the *exact same* `docker-compose.yml` a self-hoster would run — that's the parity guarantee. Anything dev-only must live in `docker-compose.override.yml`, which Coolify ignores.
- One Coolify subtlety: Coolify's reverse-proxy (Traefik) is what assigns external hostnames; your compose file should NOT bind public ports for `api`/`web` once those services exist. Mailpit is the exception in dev (port-bound for the local UI).
- [CITED: coolify.io/docs/get-started; localtonet.com/blog/how-to-self-host-coolify; community reports on Hetzner CX22 sufficiency for hundreds-of-users scale]

### Anti-Patterns to Avoid

- **Using `actions/dependency-review-action` on the private repo without GHAS.** It will silently fail or refuse to run. Use the `pnpm licenses list` workflow above until flip-day. [VERIFIED: github.com/actions/dependency-review-action README — "Private repositories with a GitHub Advanced Security license"]
- **Pinning `:latest` tags in production.** Use specific version tags (`postgres:17.5-alpine`) once you've selected one at planning time. `:latest` is acceptable in `.example` files but never in the committed `docker-compose.yml`.
- **Bundling Plausible CE in our `docker-compose.yml`.** Plausible CE is AGPL-3.0; bundling it makes the bundle AGPL-encumbered. Public instance: use Plausible Cloud (managed). Self-host docs: link to Plausible CE as an *optional* separate stack a self-hoster can run, but don't ship it in our compose. [CITED: github.com/plausible/analytics README]
- **Committing `docker-compose.override.yml` directly.** Override files are dev-machine-specific. Commit `docker-compose.override.yml.example` only.
- **Per-file copyright headers on every source file.** D-04 explicitly rejects this. The single root `LICENSE` + `Copyright (c) {year} {Project} Contributors` line on new files (when contributor wants to) is the policy.
- **Using GitHub-native CodeQL or GHAS-required tooling on the private repo.** Same private-repo gap.
- **Reserved-handle list as a flat string array without metadata.** Recommend structured shape — see "Reserved Handle List" section below.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| OSS license text | A "based on Apache" custom license | **Verbatim Apache-2.0** from `apache.org/licenses/LICENSE-2.0.txt` | Modifying the text invalidates SPDX matching; license-detection tools (FOSSA, GitHub) won't recognize it; OSI compliance breaks. Copy unchanged, fill the year and copyright holder field per Apache's APPENDIX. |
| Code of Conduct text | A custom CoC | **Contributor Covenant 2.1 verbatim** (the link in CONTEXT.md) | Same reason — and CoC adoption signals are baked into community-health-check tools. Substitute only the contact email. |
| DCO checking logic | A homegrown bash script | **`KineticCafe/actions-dco@v2` action** (or **CNCF dco2** GitHub App) | Trailer parsing has edge cases (multiple sign-offs, `Co-authored-by`, signed by bots, web-edits). Solved by maintained tooling. |
| License denylist regex | A handwritten matcher | `pnpm licenses list --json` + small denylist (or `license-checker-rseidelsohn`) | SPDX expressions are non-trivial (`MIT OR Apache-2.0`, `(GPL-2.0+ AND CC0-1.0)`); pnpm parses them correctly. |
| Privacy policy / Terms of Service | A from-scratch policy or copy-pasted boilerplate | **Clean-room adaptation of a permissive-OSS template** (Plausible's, Standard Ebooks', Codeberg's) — all CC-BY-SA or permissively shared | Privacy law is jurisdictional; templates from EU-resident OSS projects already account for GDPR controller/processor language. Lawyer review at flip-day per CD-04 still required, but starting from a real OSS policy beats from-scratch. |
| Reserved-handle list | An ad-hoc list of names | **Adapt `shouldbee/reserved-usernames`** (590+ names, MIT-licensed, JSON/CSV/SQL formats available) trimmed/extended to ~200 | Existing list already covers system paths, common admin handles, and HTTP method names. We add brand collisions (anthropic, claude, openai) and per-product squat targets. [CITED: github.com/shouldbee/reserved-usernames] |
| Mailpit healthcheck | Custom HTTP probe | **Built-in `/readyz` endpoint**; Mailpit's Dockerfile already has HEALTHCHECK | Don't duplicate. [CITED: mailpit.axllent.org/docs/integration/healthcheck/] |
| Donations badge for README | Custom SVG | **Ko-fi's official "Support me on Ko-fi" badge** at `ko-fi.com/img/githubbutton_sm.svg` | One line of markdown; tracks brand. |
| Postgres healthcheck | Connecting via `psql` | **`pg_isready` from inside the container** | Standard pattern; doesn't require client tools. |

**Key insight:** Phase 0's value comes from **adopting and codifying** existing OSS conventions, not inventing them. Every artifact should be either verbatim-from-canonical-source or a thin clean-room adaptation. Originality here is a smell.

## Common Pitfalls

### Pitfall 1: License-check CI silently fails on a private repo

**What goes wrong:** Planner adds `actions/dependency-review-action`, repo is private, action either no-ops or fails with a non-obvious error about GHAS licensing. CI shows green when it shouldn't, or red for a reason that confuses contributors.

**Why it happens:** GitHub's first-party dep-review-action is gated on GHAS for private repos. Doc note is short and easy to miss. [CITED: github.com/actions/dependency-review-action]

**How to avoid:** Use the `pnpm licenses list` workflow (Pattern 2 above) until D-15 flip-day. Add `actions/dependency-review-action` as a *second*, complementary check at flip-day, not a replacement.

**Warning signs:** Workflow log shows "Dependency review is not available on this repository" or completes with no findings even when a clearly GPL package is present (test by adding a fake AGPL package as a fixture in the verification step).

### Pitfall 2: Bundling AGPL Plausible CE in `docker-compose.yml`

**What goes wrong:** Self-hosters who run our `docker compose up` are now distributing Plausible CE (AGPL-3.0) bundled with our Apache-2.0 code. AGPL's network-use clause kicks in: anyone running our public instance is obligated to publish source for any modifications. Forks become AGPL-encumbered.

**Why it happens:** Plausible CE is the natural "we want privacy-respecting analytics" first thought. The licensing split (CE = AGPL, Cloud = managed, JS tracker = MIT carve-out) is non-obvious. [CITED: github.com/plausible/analytics — main code AGPL-3.0; tracker MIT]

**How to avoid:**
- **Public instance:** Use **Plausible Cloud** (managed). No licensing obligation on us. Embed `script.js` (MIT-carved-out) on web pages.
- **Self-host:** Do NOT include Plausible CE in our `docker-compose.yml`. Document in `docs/ops/` that self-hosters can optionally run their own Plausible instance (CE) **separately** (separate compose file, separate domain). The boundary is: our distributed bundle never contains AGPL code.
- Privacy policy reflects: "On the public instance, we use Plausible Cloud (cookie-free, no personal data sent to third parties beyond aggregated analytics — see plausible.io/data-policy)." Self-host policy template notes "you are responsible for any analytics you add."

**Warning signs:** Anyone proposes "let's add Plausible to compose" — pause and re-read the licensing section before agreeing.

### Pitfall 3: DCO sign-off bypassed via squash-merge with edited commit message

**What goes wrong:** Contributor signs off correctly on PR commits. Maintainer hits "Squash and merge" and the GitHub UI lets them edit the squash commit message — the `Signed-off-by:` lines get dropped. Repo history loses the DCO trail. Probot DCO app can't catch this. [CITED: github.com/probot/dco/issues/126]

**Why it happens:** GitHub's squash-merge UI presents the commit message as freely editable.

**How to avoid:**
- The workflow above gates *PR commits*, not the merge commit, so DCO is satisfied at PR-time and merge-time edits don't unsatisfy it for the upstream review.
- Repo settings: enable **"Require contributors to sign off on web-based commits"** (Settings → General → Pull Requests).
- Maintainer discipline: don't edit the auto-generated squash message. (The GitHub-generated default appends sign-off trailers from the squashed commits.)
- Optional belt-and-suspenders: a post-merge audit job that scans `git log main` for any commit missing `Signed-off-by:` and opens an issue. Out of scope for Phase 0.

**Warning signs:** Pre-merge `git log` of the PR has sign-offs; post-merge `git log main` doesn't.

### Pitfall 4: Mailpit boots without healthcheck and `docker compose up` declares "ready" prematurely

**What goes wrong:** `docker compose up` returns success the moment containers are running, but Mailpit's web UI takes 1-3s to bind. A test that immediately curls `localhost:8025` flakes.

**Why it happens:** Default Compose `up` doesn't wait on healthchecks unless `depends_on.condition: service_healthy` is set on a downstream service. With no app services in Phase 0, nothing depends on Mailpit, so nobody is waiting.

**How to avoid:**
- Mailpit's Dockerfile already has a HEALTHCHECK using `/readyz`. Confirm that healthcheck is honored in compose.
- Validation tests use `docker compose up -d` then a small wait-for-health loop using `docker compose ps --format json | jq` until `Health: healthy`, with a 60-second timeout.
- Same applies to Postgres and Valkey, but they expose obvious "ping" semantics (`pg_isready`, `valkey-cli ping`).

**Warning signs:** A "compose up boots cleanly" test runs reliably on dev machines but flakes on slower CI runners.

### Pitfall 5: Reserved-handle list grows beyond ~200 names and reverse-DNS / impersonation gaps appear later

**What goes wrong:** Initial list is too short. Phase 1 enforcement allows a user to claim `support`, `noreply`, `mail`, or `anthropic-team`. Or a misspelled brand collision (`anthrop1c`) slides through.

**Why it happens:** The "~200 names" quota was set without a categorization model. Easy to under-cover one category.

**How to avoid:** Use the categorization below as a coverage checklist. Each category gets a target count; total ≈ 200.

| Category | Target count | Examples |
|----------|--------------|----------|
| HTTP/system paths | ~40 | `admin`, `root`, `www`, `api`, `static`, `assets`, `cdn`, `mail`, `smtp`, `dns`, `ftp`, `ssh`, `localhost`, `null`, `undefined`, `system` |
| Common admin/staff roles | ~30 | `support`, `help`, `info`, `contact`, `team`, `staff`, `mod`, `moderator`, `admin1`, `webmaster`, `postmaster`, `hostmaster`, `noreply`, `no-reply`, `donotreply` |
| Auth / account terms | ~20 | `login`, `signup`, `signin`, `logout`, `register`, `account`, `password`, `reset`, `verify`, `auth`, `oauth`, `sso`, `2fa`, `mfa` |
| Legal / compliance | ~15 | `legal`, `terms`, `privacy`, `gdpr`, `dmca`, `abuse`, `security`, `report`, `appeal`, `compliance` |
| Brand collisions to defend | ~25 | `anthropic`, `claude`, `claudecode`, `claude-code`, `openai`, `chatgpt`, `gpt`, `microsoft`, `google`, `aws`, `apple`, `meta`, `github`, `gitlab` |
| Project-specific protected | ~20 | `gsd`, `gsd-helper`, `gsd-server`, `helper`, `server`, `cli`, `dashboard`, `leaderboard`, `admin-team`, the project's eventual final name family (one row per likely candidate) |
| Reserved gaming/social handles | ~20 | `me`, `you`, `everyone`, `anonymous`, `anon`, `guest`, `user`, `users`, `bot`, `system-bot`, `null-user`, `nobody` |
| Feature/route names | ~15 | `quest`, `quests`, `xp`, `level`, `streak`, `achievement`, `cosmetic`, `device`, `pair`, `settings`, `u`, `profile` |
| Squat-target permutations | ~15 | Common typos of system terms (`adimn`, `roott`, `sup0rt`), Unicode look-alikes for high-value brands (out of scope for v1; flag for v1.1) |

**Recommended schema (per CD-03, structured rather than flat):**
```json
{
  "version": 1,
  "locked_at": "2026-05-08",
  "entries": [
    { "name": "admin", "category": "system", "reason": "Reserved system path; impersonation risk." },
    { "name": "anthropic", "category": "brand", "reason": "Defend against impersonation." },
    { "name": "claude", "category": "brand", "reason": "Defend against impersonation." }
  ]
}
```
A flat array (`["admin", "root", ...]`) is simpler to consume but loses provenance. Phase 1's enforcement code reads `name` only; the metadata is for human auditors. **Recommend the structured shape** — Phase 1 reduces it with one map operation.

**Source:** Adapted from `shouldbee/reserved-usernames` (590+ names, MIT) trimmed to our brand context. [CITED: github.com/shouldbee/reserved-usernames]

**Warning signs:** Audit at end of Phase 0 shows a category has 0 entries. Re-check coverage.

### Pitfall 6: SPF "10 DNS lookup limit" exceeded

**What goes wrong:** Resend uses Amazon SES under the hood. The recommended SPF is `v=spf1 include:amazonses.com ~all`. SES's SPF chain has its own includes; if the user later adds another include (Google Workspace's `include:_spf.google.com`, etc.), the cumulative DNS-lookup count exceeds 10 and SPF validation fails silently for some receivers.

**Why it happens:** SPF spec (RFC 7208) caps total lookups at 10 to prevent abuse. AWS SES + a second mail provider crosses easily.

**How to avoid:**
- v1: Single provider (Resend) — under the limit by far.
- Document in `docs/ops/dns.md`: "If you add a second mail provider, run an SPF flattener / lookup-count check before deploying."
- Tooling: link to `mxtoolbox.com/SuperTool.aspx` for SPF lookup checks.

**Warning signs:** Email deliverability drops, especially to corporate/Microsoft 365 / Google Workspace recipients.

### Pitfall 7: `docs/legal/*.md` written as if "policy" but the policy doesn't match what code actually does in later phases

**What goes wrong:** Phase 0 writes "raw events are retained for 90 days." Phase 3 implements ingestion and forgets the 90-day cleanup worker. PRIV-03 is technically violated.

**Why it happens:** Policy-vs-implementation drift. Phase 0 docs are written before the code that enforces them.

**How to avoid:**
- Each retention rule in `docs/legal/retention-schedule.md` should be tagged with the phase that *implements* the cleanup. Example: "Raw events: 90 days. Implemented by `events-cleanup` BullMQ worker in Phase 3."
- Phase 3's plan-check verifies the implementation matches the doc.
- Phase 1's account-deletion path (AUTH-07) similarly references the policy doc.

**Warning signs:** Docs say one thing, behavior tests another — pre-launch audit catches this if anyone runs it.

### Pitfall 8: Hosting-cap claim and the underlying definition of "active" drift apart

**What goes wrong:** `docs/legal/hosting-cap.md` says "5,000 active accounts." Later phases compute active-counts in three different ways (last login, last event, last quest completed). Cap is "enforced" against an undefined metric.

**Why it happens:** "Active" is a deceptively simple word. CONTEXT.md D-06 explicitly defines it as "signed in at least once in the last 90 days" — but if not codified in `docs/legal/hosting-cap.md` it'll drift.

**How to avoid:** Verbatim definition from D-06 lands in `hosting-cap.md`. Phase 1's session table includes the field referenced (`last_signin_at`) explicitly. Cap-enforcement query is a single SQL expression: `SELECT COUNT(*) FROM users WHERE last_signin_at > NOW() - INTERVAL '90 days'`. Quoted in the doc.

**Warning signs:** Three different SQL expressions in three different phases query "active" users.

### Pitfall 9: 90-day shutdown plan published without an actual data-export path being scoped

**What goes wrong:** `shutdown-plan.md` promises "full data export per user before close." Later phases never implement an export endpoint. If shutdown actually happens, maintainer scrambles.

**Why it happens:** Doc is forward-looking; nobody owns building the export pipeline.

**How to avoid:** `shutdown-plan.md` includes a "Data export inventory" subsection listing, per-user, what fields are exported (events, quests, achievements, cosmetics, profile, comments authored). Phase 1 ships account deletion (AUTH-07). The export endpoint is a Phase 9 or Phase 10 deliverable; scope-risk #5 in ROADMAP.md flags this. Recommend planner adds it explicitly to the post-Phase-0 backlog.

**Warning signs:** No test exercises the export path.

## Code Examples

### Example 1: `package.json` at repo root (workspace root)

```json
{
  "name": "gsd-monorepo",
  "private": true,
  "version": "0.0.0",
  "license": "Apache-2.0",
  "engines": {
    "node": ">=22.0.0",
    "pnpm": ">=9.0.0"
  },
  "packageManager": "pnpm@9.15.0",
  "scripts": {
    "compose:up": "docker compose up -d",
    "compose:down": "docker compose down",
    "compose:logs": "docker compose logs -f",
    "licenses:check": "pnpm licenses list --json"
  },
  "devDependencies": {}
}
```
Source: standard pnpm + Turborepo monorepo root. `packageManager` field locks pnpm version (used by Corepack). [CITED: pnpm.io / nodejs.org Corepack docs]

### Example 2: `pnpm-workspace.yaml`

```yaml
packages:
  - "apps/*"
  - "packages/*"
```
Source: standard pnpm workspace shape. [CITED: pnpm.io/pnpm-workspace_yaml]

### Example 3: `turbo.json` (empty pipelines, populated by later phases)

```json
{
  "$schema": "https://turbo.build/schema.json",
  "tasks": {
    "build": { "dependsOn": ["^build"], "outputs": ["dist/**", ".svelte-kit/**"] },
    "test": { "dependsOn": ["^build"] },
    "lint": {},
    "typecheck": { "dependsOn": ["^build"] }
  }
}
```
Source: Turborepo 2.x default shape. [CITED: turbo.build/repo/docs/reference/configuration]

### Example 4: README.md skeleton

```markdown
# Claude Code Gamification Service (working title)

> An open-source gamification service for Claude Code users. A web app, backend,
> and helper module that turn real workflow signals — token usage, sessions,
> context efficiency, hook events — into quests, achievements, leaderboards,
> and cosmetic unlocks. Statusline-agnostic.

## Maintenance posture

This is a hobby project maintained on a best-effort basis. Issues and PRs are
welcomed but not guaranteed a response within any specific timeframe.
The public hosted instance is capped at 5,000 active accounts; if that fills up,
please run your own with `docker compose up`.

## Self-host quickstart

```bash
git clone {repo-url}
cp .env.example .env
docker compose up
# Mailpit UI → http://localhost:8025
```

## Status

Phase 0 (project scaffolding) — no product features yet.
See [.planning/ROADMAP.md](./.planning/ROADMAP.md) for the 11-phase plan.

## Support / donations

If this project is useful to you, please consider supporting maintenance:
[Ko-fi](https://ko-fi.com/{maintainer-handle})

GitHub Sponsors will be enabled when the repo flips public.

## License

Apache-2.0 — see [LICENSE](./LICENSE).

## Contributing

By contributing you agree to the [Developer Certificate of Origin](https://developercertificate.org/).
See [CONTRIBUTING.md](./CONTRIBUTING.md) and [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md).
```

### Example 5: `docs/ops/dns.md` (placeholder values pre-domain-purchase)

```markdown
# DNS — Sender Identity (SPF / DKIM / DMARC)

These records are committed before domain purchase so flipping live is a one-step
domain swap, not a research project. Replace `{ROOT_DOMAIN}` with the live domain
when committed.

## SPF (TXT on `send.{ROOT_DOMAIN}`)

Resend uses Amazon SES under the hood. SPF for the `send` subdomain (Resend's
Envelope-From subdomain by default):

```
Type: TXT
Name: send.{ROOT_DOMAIN}
Value: "v=spf1 include:amazonses.com ~all"
TTL:  3600
```

Source: Resend documentation; SES SPF include is the canonical chain.
Reference: https://docs.aws.amazon.com/ses/latest/dg/send-email-authentication-spf.html

## MX (on `send.{ROOT_DOMAIN}`)

Resend asks for an MX on the `send` subdomain so SES can return bounce/complaint
notifications. Exact MX value is provided by Resend at domain-add time and varies
by region; use the value Resend's dashboard shows. Placeholder:

```
Type: MX
Name: send.{ROOT_DOMAIN}
Priority: 10
Value: feedback-smtp.{REGION}.amazonses.com
TTL:  3600
```

## DKIM (TXT records — Resend issues 1-3 keys)

When you add a domain in the Resend dashboard, Resend generates 1-3 DKIM key
records. Each is a TXT record at a Resend-specified selector subdomain. The
exact selector and value come from the Resend dashboard.

Placeholder shape:

```
Type: TXT
Name: {SELECTOR}._domainkey.{ROOT_DOMAIN}
Value: "v=DKIM1; k=rsa; p={PUBLIC_KEY}"
TTL:  3600
```

## DMARC (TXT on `_dmarc.{ROOT_DOMAIN}`)

Progressive policy:

| Phase | Value |
|-------|-------|
| Initial (testing) | `v=DMARC1; p=none; rua=mailto:dmarc-reports@{ROOT_DOMAIN}` |
| After 14 days clean reports | `v=DMARC1; p=quarantine; pct=25; rua=mailto:dmarc-reports@{ROOT_DOMAIN}` |
| After 30 days clean | `v=DMARC1; p=reject; rua=mailto:dmarc-reports@{ROOT_DOMAIN}` |

Start with `p=none` (monitor-only). Walk to `p=quarantine` then `p=reject` only
after DMARC reports show no legitimate mail being marked as failing.

Reference: RFC 7489 (DMARC); Resend implementing-dmarc guide.

## From-address policy

| From | Use |
|------|-----|
| `noreply@{ROOT_DOMAIN}` | All transactional mail (verification, reset, pairing, weekly digest). |
| `hello@{ROOT_DOMAIN}` | Replyable maintainer-monitored inbox; forwarded to maintainer. |

No per-purpose addresses (`verify@`, `pair@`, etc.) at v1 — see CONTEXT.md D-12.
```

Source: composed from Resend documentation and Amazon SES SPF docs. [CITED: docs.aws.amazon.com/ses/latest/dg/send-email-authentication-spf.html; resend.com/docs/dashboard/domains/dmarc]

### Example 6: `docs/legal/retention-schedule.md` skeleton

```markdown
# Data Retention Schedule

Per PRIV-03, FND-05, AUTH-07. Each rule names the phase that implements its
cleanup so policy and code stay aligned.

| Data | Retention | Implemented by | Phase |
|------|-----------|----------------|-------|
| Raw events (`events` table) | 90 days from `created_at` | `events-cleanup` BullMQ worker | Phase 3 |
| Daily aggregates (`daily_user_stats`) | Indefinite | n/a (kept for life of account) | Phase 3 |
| Account record (`users`, `handles_history`) | Until self-service deletion | `account-deletion` flow | Phase 1 |
| Session tokens (Better Auth `session`) | Per Better Auth defaults; revoked on logout / device-revoke | Better Auth | Phase 1 |
| Email digests audit | 90 days | TBD | Phase 9 |
| Audit log of anti-cheat actions | Indefinite (compliance signal) | TBD | Phase 10 |

## On account deletion (AUTH-07)

A user requesting account deletion has the following deleted within 30 days:
- `users` row + cascade
- All raw events (regardless of 90-day status)
- All cosmetic loadouts, achievements, comments authored
- Handle is freed for re-use **after a 90-day cooldown** to prevent ID reuse confusion

Anonymized aggregates may be retained (per privacy policy and PRIV-03).
```

### Example 7: `docs/legal/hosting-cap.md` skeleton

```markdown
# Hosting Cap

The public hosted instance is capped at **5,000 active accounts**.

## Definition of "active"

An account is "active" if it has signed in (logged into the web app, or
exchanged tokens via the helper) at least once in the last **90 days**.

The cap is enforced as:

```sql
SELECT COUNT(*) FROM users WHERE last_signin_at > NOW() - INTERVAL '90 days';
```

(Specific implementation arrives in Phase 1.)

## What happens at the cap

When the public instance reaches the cap, signup form returns:

> We're at our community cap. Join the waitlist or run your own instance:
> `docker compose up`. The codebase is Apache-2.0 licensed and self-hostable.
> Self-host docs: {link}

## Why cap

This is a hobby project and the maintainer is one person. Capping the public
instance is how this project survives long-term — it keeps moderation,
hosting, and trust-and-safety load bounded. Self-hosters are the long tail.
```

### Example 8: `docs/legal/shutdown-plan.md` skeleton

```markdown
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
```

Source: composed from Forgejo / Codeberg / Pixelfed instance-shutdown communications and Pitfall 7 mitigations in `research/PITFALLS.md`. [CITED: research/PITFALLS.md § Pitfall 7]

### Example 9: `docs/legal/privacy-policy.md` skeleton (clean-room sketch — replace placeholders during planning)

```markdown
# Privacy Policy

**Effective:** {DATE} • **Instance:** {INSTANCE_HOSTNAME} • **Controller:**
{MAINTAINER_NAME}, {MAINTAINER_COUNTRY} • **Contact:** privacy@{ROOT_DOMAIN}

> This is the privacy policy for the public hosted instance. Self-hosted
> instances inherit this template but the controller, contact, and infrastructure
> sections will differ — self-hosters MUST update those sections before deploying.

## Who we are

{MAINTAINER_NAME} runs this service as a hobby project. We are the data
controller (GDPR Art. 4). We have no Data Protection Officer (volume below
threshold per GDPR Art. 37); contact above.

## What data we process

| Data | Source | Lawful basis (GDPR Art. 6) | Retention |
|------|--------|----------------------------|-----------|
| Email + password hash | Signup | Contract (Art. 6(1)(b)) | Until account deletion |
| Public handle | Signup | Contract; legitimate interest | Until account deletion + 90-day cooldown |
| Workflow events (token counts, session length, etc.) | Helper module | **Granular consent (Art. 6(1)(a))** — separate consent toggle "event capture" | 90 days raw, indefinite aggregated |
| Public leaderboard rank + cosmetics | Computed | **Granular consent** — separate toggle "public leaderboards" | While consented |
| Email digest opt-in | Settings | **Granular consent** — separate toggle "email digests" | While consented |
| Anthropic OAuth token | **Never collected** — stays on user's machine | n/a | n/a |

## Where we host

Public instance: Hetzner GmbH (Falkenstein, Germany — EU). No international
transfers in scope.

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
1. Event capture from the helper module
2. Public leaderboard participation
3. Email digests

Each can be withdrawn independently in `/settings/privacy`. Withdrawal stops
collection going forward; existing aggregated data may be retained.

## Changes to this policy

Material changes are emailed to all users 30 days before they take effect.

## Contact

privacy@{ROOT_DOMAIN}
```

Source: Adapted clean-room from Plausible's published policy + GDPR.eu template. Lawyer review at flip-day per CD-04. [CITED: plausible.io/privacy; gdpr.eu/privacy-notice/]

### Example 10: Granular-consent record schema sketch (PRIV-02)

This is **schema sketch only** for Phase 0 — no DB code in this phase. Phase 1 implements the table.

```typescript
// Conceptual shape, NOT a Drizzle schema yet (that lands in Phase 1).

type ConsentRecord = {
  user_id: string;                 // FK to users
  consent_kind: 'event_capture' | 'public_leaderboards' | 'email_digests';
  granted: boolean;
  granted_at: Date | null;          // null when never granted
  revoked_at: Date | null;          // null while active
  policy_version: string;           // e.g. "2026-05-08" — hash or date of policy at grant time
  source: 'signup' | 'settings' | 'admin';
  ip_hash: string;                  // hashed (for audit, not surveillance)
};
```

Three independent toggles ⇒ three rows per user (one per `consent_kind`).
Default state for a new account: all three rows present, `granted = false`,
`granted_at = null`. The signup flow flips them per the user's choices.

Source: standard GDPR consent-record pattern; aligns with the controller's
audit obligation under Art. 7(1) ("be able to demonstrate that the data subject
has consented"). [CITED: gdpr-info.eu/art-7-gdpr/]

### Example 11: SECURITY.md skeleton

```markdown
# Security Policy

## Reporting a vulnerability

Email security@{ROOT_DOMAIN} (or for now, {MAINTAINER_EMAIL}) with:

- Description of the vulnerability
- Steps to reproduce
- Affected version(s)
- Suggested fix (optional)

We aim to acknowledge within 7 days and ship a fix within 30 days for High/Critical
issues. This is a hobby project — we'll do our best.

Please do **not** file a public GitHub issue for security-impacting bugs.

## Scope

In scope: backend, web app, helper module, anything published from this repo.

Out of scope:
- Anthropic's services (report directly to Anthropic)
- Self-hosted instances we don't operate
- Vulnerabilities in upstream dependencies — please file with the upstream
  maintainer; we'll update once a fix ships.

## Disclosure

We follow coordinated disclosure: 90 days from report-to-fix, or shorter if a
fix is shipped earlier.
```

Source: standard OSS SECURITY.md template per GitHub community-health guide. [CITED: docs.github.com/en/code-security]

### Example 12: CONTRIBUTING.md skeleton (DCO-only, no CLA)

```markdown
# Contributing

Thanks for considering a contribution. This project is maintained on a best-effort
basis; please be patient.

## Sign-off (DCO)

Every commit must include a `Signed-off-by:` trailer. By signing off you agree to
the [Developer Certificate of Origin](https://developercertificate.org/).

```bash
git commit -s -m "your message"
```

There is **no Contributor License Agreement (CLA)**. DCO is sufficient.

If you forget to sign off, our DCO check will block the merge. To fix:

```bash
git rebase HEAD~N --signoff   # N = number of unsigned commits
git push --force-with-lease
```

## Workflow

1. Open an issue first for non-trivial changes — this saves you wasted work.
2. Fork → branch → PR.
3. Run `docker compose up` and verify the service stack still boots.
4. Run `pnpm licenses:check` (when there are deps) — must pass.
5. PR description references the issue.

## License

By contributing, you agree your contribution is licensed under Apache-2.0 (the
project license).

## Code of Conduct

This project follows the [Contributor Covenant 2.1](./CODE_OF_CONDUCT.md).
```

Source: standard OSS CONTRIBUTING.md combined with DCO-specific guidance. [CITED: developercertificate.org]

## Runtime State Inventory

This is a greenfield phase — no existing code, no existing data, no live services. Section omitted per template guidance.

## Environment Availability

Phase 0 introduces tooling but doesn't run product code. Required dev-machine dependencies:

| Dependency | Required By | Available (typical) | Version | Fallback |
|------------|------------|---------------------|---------|----------|
| Node.js 22 | `package.json` `engines`, future scripts | Likely on dev machine | ≥22 | Document install via Volta / nvm / fnm in README |
| pnpm 9 | Workspace + license-check workflow | Installed via Corepack | ≥9 | `corepack enable && corepack prepare pnpm@9.15.0 --activate` |
| Docker + Docker Compose v2 | `docker compose up` parity gate | Likely on dev machine | Compose v2.x | Document install via Docker Desktop / Rancher Desktop / Colima in README |
| Git | Repo basics | Always | any 2.x | n/a |
| GitHub account + repo | Hosting | Yes | n/a | n/a (D-13) |

**Probe commands** (planner's verify-step in plan-check):
```bash
node --version            # >=22
pnpm --version            # >=9
docker --version          # any 24+
docker compose version    # plugin form, v2+
git --version
```

**Missing dependencies with fallback:**
- If Docker isn't installed, `docker compose up` step won't pass; the planner's "compose boots cleanly" verification step is the only thing that requires Docker. Self-host quickstart in README is honest with users about needing Docker.

**Missing dependencies with no fallback:**
- None. All dependencies are commodity dev tooling.

**Domain registrar:** Cloudflare Registrar per CD-02. Domain purchase happens in this phase per D-11. The actual purchase is a one-time human action; placeholder values in `dns.md` allow the rest of the work to proceed without it.

**Resend account:** Required only when public instance flips on (post-flip-day). Phase 0 commits the DNS docs in `dns.md` placeholder form so the flip is a config change, not a research project. No Resend API key is committed.

**Ko-fi account:** Required for FND-06 to be live. One-time human setup; ~5 minutes. Username gets baked into the README badge URL.

## Validation Architecture

### Test Framework

Phase 0 ships no production code, so there's no Vitest/Playwright suite yet — those land in Phase 1 (Vitest) and Phase 2 (Playwright). What Phase 0 *does* have is **CI integration tests** that the workflows themselves act as. The "tests" are the workflows running against fixture PRs.

| Property | Value |
|----------|-------|
| Framework | GitHub Actions workflows + shell-based assertions |
| Config file | `.github/workflows/license-check.yml`, `.github/workflows/dco.yml` |
| Quick run command | Pushed PR triggers both workflows; no local "quick run." Local equivalent: `pnpm licenses:check` (license workflow's core command). |
| Full suite command | `pnpm licenses:check && docker compose up -d && sleep 60 && docker compose ps && docker compose down` (smoke gate that exercises all Phase 0 deliverables) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FND-01 | LICENSE file is present, contains Apache-2.0 verbatim | smoke | `[ -f LICENSE ] && grep -q "Apache License" LICENSE && grep -q "Version 2.0" LICENSE` | Wave 0 (fixture verify-step) |
| FND-02 | License-check CI fails on a PR introducing AGPL/GPL/SSPL/RSALv2 | integration | Fixture PR adding a known-AGPL package (e.g. `is-agpl-fake-test-pkg`) → workflow run must fail | Wave 0 |
| FND-03 | CONTRIBUTING.md and CODE_OF_CONDUCT.md present | smoke | `[ -f CONTRIBUTING.md ] && [ -f CODE_OF_CONDUCT.md ]` + grep for "Contributor Covenant" + "Signed-off-by" | Wave 0 |
| FND-04 | hosting-cap.md present, defines "active" matching D-06, includes overflow language | smoke | grep `5,?000` + grep `90 days` in `docs/legal/hosting-cap.md` | Wave 0 |
| FND-05 | shutdown-plan.md present, references 90-day notice + data export | smoke | grep `90 days` + grep "data export" in `docs/legal/shutdown-plan.md` | Wave 0 |
| FND-06 | README links to donations channel | smoke | grep `ko-fi.com` (or `opencollective.com`) in `README.md` | Wave 0 |
| FND-07 | README states maintenance posture | smoke | grep "best-effort" or "hobby project" in `README.md` | Wave 0 |
| FND-08 | `docker compose up` boots cleanly on a clean clone with no extra setup | integration | `cp .env.example .env && docker compose up -d && for i in {1..60}; do docker compose ps --format json \| jq -e '.[].Health' \| grep -q healthy \|\| sleep 1; done && docker compose down` (60s timeout) | Wave 0 |
| FND-08 | Mailpit web UI reachable on port 8025 | integration | After compose up: `curl -f http://localhost:8025/readyz` returns 200 | Wave 0 |
| PRIV-01 | Privacy policy + ToS exist | smoke | `[ -f docs/legal/privacy-policy.md ] && [ -f docs/legal/terms-of-service.md ]` | Wave 0 |
| PRIV-02 | Granular consent model documented (3 separate consents) | smoke | grep all three of `event_capture`, `public_leaderboards`, `email_digests` in `docs/legal/privacy-policy.md` | Wave 0 |
| PRIV-03 | Retention schedule present, mentions 90-day raw events | smoke | grep `90 days` + grep `raw events` in `docs/legal/retention-schedule.md` | Wave 0 |
| PRIV-04 | Plausible (not GA) is the named analytics provider | smoke | grep `plausible.io` + assert `Google Analytics` does NOT appear | Wave 0 |
| PRIV-05 | Architecture doc codifies the redaction rule | smoke | grep "redact" + grep "token" in `docs/architecture/00-overview.md` | Wave 0 |
| (FND-08 detail) | All three compose services reach `healthy` state | integration | `docker compose ps` shows `Health: healthy` for postgres, valkey, mailpit | Wave 0 |
| (DCO-CI) | DCO workflow blocks a PR commit lacking sign-off | integration | Fixture PR with a non-signed-off commit → workflow run must fail | Wave 0 |
| (License-CI) | License workflow ALLOWS a dual-licensed pkg with one permissive branch | integration | Fixture PR adding `argon2` (CC0 OR Apache-2.0) → workflow run must pass | Wave 0 |

### Sampling Rate

- **Per task commit:** Local `pnpm licenses:check` (when there are any deps).
- **Per wave merge:** Both CI workflows (license-check + DCO) run on every PR; merge requires both green.
- **Phase gate:** Every Wave-0 row above has a passing automated check before `/gsd-verify-work` for Phase 0.

### Wave 0 Gaps

These need to be set up *during* Phase 0 (they don't exist yet — the phase creates them):

- [ ] `.github/workflows/license-check.yml` — covers FND-02, run on every PR
- [ ] `.github/workflows/dco.yml` — covers DCO enforcement (D-03)
- [ ] `scripts/verify-phase-0.sh` (or planner-equivalent) — runs the smoke greps for each FND-* / PRIV-* doc-existence check, plus a 60s `docker compose up` health-loop. Exit-0 = phase passes.
- [ ] Fixture PR set (3 PRs to seed once workflows are live):
  - One PR adding a known-AGPL package → license-check must fail.
  - One PR with a missing-signoff commit → DCO check must fail.
  - One PR adding a permissive package and signed-off → both must pass.
- [ ] Documentation in `CONTRIBUTING.md` of how to run `verify-phase-0.sh` locally (so contributors can replicate CI before pushing).

**Why no unit tests:** Phase 0 has no functions to test. The artifacts are markdown/YAML/JSON; the only meaningful test is "does this artifact exist and contain the load-bearing claim?" which is a grep-level integration test. Vitest / Playwright bring no value here. They land in Phase 1.

## Security Domain

### Applicable ASVS Categories

ASVS Level 1 per `.planning/config.json`. Phase 0 has no application code, but several controls are *codified* here for later phases to enforce:

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V1 Architecture, Threat Modeling | yes | `docs/architecture/00-overview.md` codifies threat boundaries (helper-never-asserts; token-never-leaves-helper). |
| V2 Authentication | partial (policy only) | Apache-2.0 license + future Better Auth (Phase 1) |
| V3 Session Management | partial (policy only) | Phase 1 ships sessions; Phase 0 documents retention |
| V4 Access Control | no (no app code yet) | n/a Phase 0 |
| V5 Input Validation | no (no inputs yet) | Phase 1+ |
| V6 Cryptography | no (no crypto yet) | Phase 1+ |
| V7 Error Handling, Logging | partial (policy only) | Pino redaction transport rule documented here, installed Phase 1 |
| V8 Data Protection | yes | Granular consent model + retention schedule + privacy policy. PRIV-01 → PRIV-05. |
| V9 Communications | yes | DNS docs (SPF/DKIM/DMARC) commit *now*; HTTPS-only deployment is a Coolify configuration assumption |
| V10 Malicious Code | yes | License-check CI prevents introducing GPL/AGPL/SSPL/RSALv2 deps that could complicate redistribution; DCO ensures contributor provenance |
| V14 Configuration | yes | `.env.example` separates secrets from code; no secrets in compose |

### Known Threat Patterns for Phase 0 (scaffolding-stage)

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Secrets committed to git (`.env`, API keys) | Information disclosure | `.gitignore` includes `.env`, `*.key`, `*.pem`; only `.env.example` committed. CI optional secret-scan add-on at flip-day (`gitleaks` action) |
| Malicious dependency introducing AGPL/GPL contamination or supply-chain backdoor | Tampering / Information disclosure | License-check CI; `pnpm install --ignore-scripts` in CI to skip postinstall hooks; dependency review at flip-day |
| Contributor without right to contribute (legally-encumbered code) | Repudiation / Tampering | DCO enforcement — every commit's `Signed-off-by:` is a contributor declaration. No CLA, but DCO covers the IP origination claim. |
| AGPL contagion via shipping Plausible CE in compose | n/a (license risk) | Use Plausible Cloud for public instance; document the rule in `docs/architecture/00-overview.md` so future PRs don't naively add Plausible CE |
| Privacy-policy / actual behavior drift (data collected exceeds what policy declares) | Repudiation (against users) | Retention schedule references implementing phase; plan-check at each later phase verifies code matches policy; granular consent model means user controls scope |
| Email domain spoofing (someone impersonates `@{ROOT_DOMAIN}` to phish users) | Spoofing | SPF + DKIM + DMARC documented in `dns.md` *before* domain goes live; DMARC progression `none → quarantine → reject` documented |
| OAuth token leakage (Anthropic OAuth from `~/.claude/.credentials.json`) | Information disclosure | **Architectural rule codified in Phase 0:** helper never sends Anthropic OAuth token to backend. Pino redaction transport rule documented for Phase 1 to install. CI grep gate on `sk-ant-` substring documented for Phase 1. [CITED: research/PITFALLS.md § Pitfall 6] |
| Public hosted instance compromise leading to maintainer-burnout-driven shutdown without user data export | Denial of service | Shutdown plan committed Phase 0 (90-day notice + data export); cap on active accounts (5,000) bounds blast radius |

### Phase 0 Specific Security Notes

- **Default Postgres password in `.env.example` is `gsd_dev_password`** — clearly marked as dev-only. README warns self-hosters to override before going public.
- **Mailpit's `MP_SMTP_AUTH_ACCEPT_ANY: 1` + `MP_SMTP_AUTH_ALLOW_INSECURE: 1`** — these are dev-only and suitable for the local dev container. They MUST NOT be set in any prod-bound deployment. Document this clearly.
- **Coolify deployment** — Coolify expects an env file managed in its UI, not committed. Confirm in `docs/ops/deploy-coolify.md` (Phase 0 — out of strict scope but recommended; alternatively land in Phase 1).
- **License denylist intentionally includes LGPL** — defensive even though FND-02 only names GPL/AGPL/SSPL/RSALv2. LGPL with dynamic linking is fine in many jurisdictions, but dependency boundaries in JS land are murky; cleaner to deny outright. Reconsider only if a critical dep is LGPL-only.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Coolify uses the same `docker-compose.yml` it watches in the GitHub repo for deployment | Architecture / Coolify deployment notes | LOW — Coolify docs explicitly support compose-file deployments. If Coolify needs a separate format, easy to detect at first deploy attempt. |
| A2 | The reserved-handle list of ~200 names with our category breakdown is the right shape | Pitfall 5 / reserved-handle list | LOW — adapted from a 590-name baseline (`shouldbee/reserved-usernames`); category sizes are heuristic and easy to adjust at Phase 1 enforcement time. |
| A3 | Maintainer is EU-resident (privacy policy assumes Hetzner DE = no international transfers; controller named in Germany) | Privacy policy template | MEDIUM — if maintainer is non-EU, the policy needs an EU representative (GDPR Art. 27) or different disclosure shape. Confirm with maintainer at planning. |
| A4 | The `pnpm licenses list --json` output structure includes SPDX-keyed grouping suitable for the regex denylist approach | Pattern 2 (license-check workflow) | LOW — verified against pnpm docs. Plan-check should run a fixture test (Wave 0) confirming the regex matches a known-AGPL package and rejects it. |
| A5 | Resend's SPF chain is currently `include:amazonses.com` (i.e., Resend still uses SES under the hood) | Example 5 (`docs/ops/dns.md`) | LOW — verified across multiple sources; a 2026-current change is unlikely. Reconfirm at the actual domain-add step in Resend's dashboard. |
| A6 | `KineticCafe/actions-dco@v2` is currently the lightest DCO action with no GitHub App install required | Pattern 3 (DCO workflow) | LOW — verified on GitHub Marketplace. CNCF's `dco2` GitHub App is an equivalent alternative if action-based runs into edge cases. |
| A7 | A 60-second `docker compose up` healthcheck loop is enough margin for Postgres + Valkey + Mailpit on GitHub-Actions Ubuntu runners | Validation Architecture / FND-08 test | MEDIUM — slow runner days might push past 60s. If flaky in practice, raise to 120s. Alpine images keep cold-start fast. |
| A8 | `~200 names` is an adequate reserved-handle list size for v1 | Pitfall 5 + CD-03 | LOW — Phase 1 enforcement can extend the list trivially. |
| A9 | Cloudflare Registrar (CD-02) supports the maintainer's preferred TLD | Domain registrar / D-11 | LOW — Cloudflare supports most generic TLDs; if maintainer wants something exotic (`.dev`, `.io`, country-specific), confirm at purchase. |
| A10 | Plausible Cloud's "managed cloud, source-available" stance has no downstream license obligations on consumers | Plausible licensing pitfall #2 | LOW — explicitly stated in Plausible's blog post. Conservative interpretation: using a hosted SaaS analytics never triggers AGPL on consumers. |

**Confirm with user before locking** A3 (maintainer EU-residency) — drives the privacy-policy template shape materially. Other items are low-risk and detectable at plan-check.

## Open Questions

1. **Is the maintainer EU-resident for privacy-policy controller declaration?**
   - What we know: D-08 prefers EU hosting; CONTEXT.md does not name maintainer residence.
   - What's unclear: If maintainer is non-EU, GDPR Art. 27 EU representative requirement may apply (or may not, depending on volume).
   - Recommendation: Confirm at start of planning. Default the privacy policy template to "EU-resident maintainer, Hetzner DE host, no international transfers in scope" but flag for swap if maintainer is non-EU.

2. **Does Coolify require a Dockerfile per service, or does it accept the bare `docker-compose.yml` we ship?**
   - What we know: Coolify supports compose-based deployments per its docs.
   - What's unclear: For the same `docker-compose.yml` to literally work for both `docker compose up` (self-host) and Coolify (public), Coolify must consume our exact file. Some Coolify setups expect a Coolify-managed override.
   - Recommendation: A first-deploy smoke test on a throwaway Hetzner CX22 VM, using the Phase-0 `docker-compose.yml`, confirms parity. Out of strict Phase 0 scope but cheap belt-and-suspenders to do once.

3. **Should the license-check workflow's denylist also include CC-BY-NC, BSL, ELv2, or other "source-available but commercial-restricted" licenses?**
   - What we know: FND-02 names GPL/AGPL/SSPL/RSALv2 explicitly.
   - What's unclear: Some "source-available" licenses (BSL, ELv2 etc.) are not OSI-approved but also not in FND-02's denylist. Permitting them by default is implicit.
   - Recommendation: Plan-check decision. Lean conservative: extend denylist to include `BUSL-1.1`, `ELv2`, `Confluent-Community-1.0`, `MariaDB-BSL-1.1`. None should appear in a typical TS/Node monorepo; cheap defense.

4. **Final reserved-handle list size — is 200 actually right, or should it be smaller (more permissive) or larger (more defensive)?**
   - What we know: CD-03 says "~200 names." `shouldbee/reserved-usernames` has 590.
   - What's unclear: Larger list = more user friction at handle-claim; smaller list = more squat risk.
   - Recommendation: 200 covers the categorization in Pitfall 5. Trim from 590 → 200 by dropping rare/obsolete entries; extend if a brand-collision audit at Phase 1 surfaces gaps.

5. **Should `docker-compose.yml` use Compose profiles (`profiles: [self-host, public, dev]`) to guard which services start by default?**
   - What we know: Profiles are a Compose v2 feature for conditional service start.
   - What's unclear: At Phase 0 there are only three services and they're all needed in dev + self-host + public. Profiles are unused.
   - Recommendation: Skip profiles in Phase 0. Reconsider when Phase 1+ adds the API/web/worker images and self-host wants a leaner subset.

## Sources

### Primary (HIGH confidence)

- [Apache License 2.0 verbatim](https://www.apache.org/licenses/LICENSE-2.0.txt) — license text
- [Contributor Covenant 2.1 verbatim](https://www.contributor-covenant.org/version/2/1/code_of_conduct/) — CoC text
- [Developer Certificate of Origin](https://developercertificate.org/) — DCO text
- [GitHub Actions: dependency-review-action README](https://github.com/actions/dependency-review-action) — confirmed GHAS requirement on private repos
- [Plausible Analytics — Introducing Plausible Community Edition](https://plausible.io/blog/community-edition) — confirmed CE = AGPL-3.0
- [Plausible Analytics — Open source licensing](https://plausible.io/blog/open-source-licenses) — confirmed Cloud has no AGPL obligation on consumers
- [plausible/analytics GitHub README](https://github.com/plausible/analytics) — confirmed JS tracker is MIT carve-out
- [Mailpit Docker Hub](https://hub.docker.com/r/axllent/mailpit) — image existence + tags
- [Mailpit healthcheck endpoints docs](https://mailpit.axllent.org/docs/integration/healthcheck/) — `/readyz` confirmed
- [Postgres 17 Docker official tags (Docker Hub)](https://hub.docker.com/_/postgres) — image versions verified
- [Valkey official Docker images](https://hub.docker.com/r/valkey/valkey/) — 8.x tags verified
- [Resend SPF + Amazon SES SPF docs](https://docs.aws.amazon.com/ses/latest/dg/send-email-authentication-spf.html) — `include:amazonses.com` confirmed
- [Resend DMARC docs](https://resend.com/docs/dashboard/domains/dmarc) — DMARC progression policy
- [Resend SMTP docs](https://resend.com/docs/send-with-smtp) — SMTP host/port/credentials
- [GitHub blog — sign-off on web-based commits](https://github.blog/changelog/2022-06-07-admins-can-require-sign-off-on-web-based-commits/) — repo setting confirmed
- [npm view license-checker / license-checker-rseidelsohn / @pnpm/license-scanner](https://www.npmjs.com/) — versions and last-publish dates verified

### Secondary (MEDIUM confidence)

- [Coolify docs on Hetzner with Docker Compose](https://coolify.io/docs/knowledge-base/how-to/webstudio-with-hetzner) — confirmed compose-based deployment pattern
- [How to Self-Host Coolify (Localtonet blog)](https://localtonet.com/blog/how-to-self-host-coolify) — confirmed CX22 sufficiency for hundreds-of-users scale
- [shouldbee/reserved-usernames (GitHub)](https://github.com/shouldbee/reserved-usernames) — 590-name list adapted to our 200-name list
- [GitHub Marketplace — Enforce DCO Sign-off (KineticCafe/actions-dco)](https://github.com/marketplace/actions/enforce-dco-sign-off) — recommended DCO action
- [github.com/cncf/dco2](https://github.com/cncf/dco2) — alternative DCO GitHub App
- [github.com/probot/dco/issues/126](https://github.com/probot/dco/issues/126) — squash-merge bug confirmed
- [How to use Ko-fi with Github (Ko-fi help)](https://help.ko-fi.com/hc/en-us/articles/360021025553-How-to-use-Ko-fi-with-Github) — README integration steps
- [Open Collective fiscal hosts FAQ](https://docs.opencollective.com/help/fiscal-hosts/fiscal-hosts) — alternative donations path
- [pnpm licenses CLI docs](https://pnpm.io/cli/licenses) — license-listing command
- [Forgejo / Codeberg community shutdown precedent](https://codeberg.org/Codeberg/Community/issues/420) — partial shutdown / data export discussions
- [GDPR Art. 6 lawful basis](https://gdpr-info.eu/art-6-gdpr/) — privacy-policy framing
- [GDPR.eu privacy notice template](https://gdpr.eu/privacy-notice/) — privacy-policy structure

### Tertiary (LOW confidence — cited but not load-bearing)

- [DMARC.wiki Resend setup guide](https://dmarc.wiki/resend) — confirmed SPF value cross-reference
- [Localtonet / community Coolify blogs] — anecdotal confirmation of cost / scale claims

## Metadata

**Confidence breakdown:**
- Standard stack (Phase 0 has none in the runtime sense; tooling versions): HIGH — all pinned versions verified via npm registry / Docker Hub.
- Architecture (CI workflows, compose shape, doc structure): HIGH — composed from canonical sources.
- Pitfalls: HIGH — pinned to primary research files (`research/PITFALLS.md`) + verified external behavior (Plausible licensing, GHAS gating, DCO squash-merge bug).
- Privacy policy / ToS specifics: MEDIUM — clean-room template; legal review deferred per CD-04. Assumption A3 (maintainer EU-residency) needs user confirmation.
- Coolify deployment specifics (Open Question 2): MEDIUM — confirmed compose-based deployment is the documented path; first deploy smoke test recommended.

**Research date:** 2026-05-08
**Valid until:** 2026-06-08 for Plausible / Mailpit / Coolify (fast-moving SaaS docs); 2026-08-08 for licensing tooling and Postgres/Valkey image tags (stable). Reverify at any change of Plausible licensing terms, Resend's SES backing, or GitHub's GHAS policy on private repos.

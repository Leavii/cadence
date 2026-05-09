---
phase: 00-project-setup-privacy-and-sustainability-scaffolding
plan: 04
status: complete
requirements_addressed: [FND-06, FND-07, IDENT-02]
files_created: 22
deviations: 2
checkpoints_pending: 0
completed: 2026-05-08
---

# 00-04 SUMMARY — Project Face + Monorepo Skeleton + Reserved Handles + Architecture Doc

## What was built

Workstream D from 00-PATTERNS.md: the project's external face plus the monorepo skeleton later phases populate.

- **README.md** — cadence project face, maintenance posture (best-effort, 5,000-account cap, self-host fallback), Self-host quickstart, Ko-fi placeholder donations link with TODO comment, license + contributing pointers, and a link to the new architecture doc.
- **package.json** (root) — `name: "cadence"`, `private: true`, Apache-2.0, Node ≥22, pnpm@9.15.0 Corepack pin, scripts (`compose:up`, `compose:down`, `compose:logs`, `licenses:check`).
- **pnpm-workspace.yaml** — `apps/*` + `packages/*`.
- **turbo.json** — Turborepo 2.x `tasks` shape (build, test, lint, typecheck) — passthrough config, populated by later phases.
- **8 workspace stubs** — `apps/{api,web,cli,workers}/{package.json, README.md}` and `packages/{db,content,shared,ui}/{package.json, README.md}`. All named `@cadence/*`. `apps/cli/package.json` carries a `bin: { "cadence": "./dist/index.js" }` entry exposing the helper command. Each README is a one-liner naming the phase that owns implementation.
- **packages/content/reserved-handles.json** — 200 entries across 9 categories (system, staff, auth, legal, brand, project, gaming, feature, squat) per Pitfall 5 coverage table and CD-03. Schema: `{ version, locked_at, note, entries: [{ name, category, reason }] }`. Definition only — signup-time enforcement and reserved-route 404 lands in Phase 1 (IDENT-02).
- **docs/architecture/00-overview.md** — codifies the two load-bearing rules every later phase honors:
  1. **The helper never asserts game state.** The helper observes signals and renders backend-served data; assertion is centralized in the backend so there's a single audit log and a single anti-cheat surface. Enforced in Phase 5 (HELPER-11).
  2. **Anthropic OAuth tokens never reach the cadence backend.** Pino redaction transport + CI grep gate over committed code, both installed in Phase 1 (PRIV-05, INGEST-09, INGEST-10). Helper code review enforces in Phase 5 (HELPER-12).

  Plus: three-tier system diagram, Plausible-Cloud-only rule (Pitfall 2), UTC + IANA time semantics, anti-cheat posture, FND-08 self-host parity, retention table (PRIV-03), and a phase-boundary enforcement table mapping each rule to its first-enforcement phase.

## Files created (22)

| Path | Task | Notes |
|------|------|-------|
| README.md | 2 | Project face, posture verbatim |
| package.json | 2 | name=cadence, Corepack pin |
| pnpm-workspace.yaml | 2 | apps/* + packages/* |
| turbo.json | 2 | Turborepo 2.x tasks |
| apps/api/package.json + README.md | 3 | Hono backend (Phase 1+) |
| apps/web/package.json + README.md | 3 | SvelteKit dashboard (Phase 4) |
| apps/cli/package.json + README.md | 3 | Helper CLI; `bin: { cadence }` (Phase 5) |
| apps/workers/package.json + README.md | 3 | BullMQ worker (Phase 6+) |
| packages/db/package.json + README.md | 3 | Drizzle schema (Phase 1) |
| packages/content/package.json + README.md | 3 | Content assets (this plan + later) |
| packages/shared/package.json + README.md | 3 | Cross-cutting types/Zod (Phase 1) |
| packages/ui/package.json + README.md | 3 | Shared Svelte + 8bitcn/ui (Phase 4) |
| packages/content/reserved-handles.json | 4 | 200 entries / 9 categories |
| docs/architecture/00-overview.md | 4 | Load-bearing rules + system overview |

## Commits

- `feat(00-04): README + monorepo skeleton (pnpm workspaces + turbo)` — Task 2
- `feat(00-04): workspace package.json + README stubs (8 packages)` — Task 3
- `feat(00-04): reserved-handles content + cross-cutting architecture doc` — Task 4
- `docs(00-04): summary` — this file

## Deviations

1. **Project name = `cadence`** (not the plan's prior `gsd-monorepo` / `gsd-helper` / `gsd-server` placeholders). User finalized the name to `cadence` mid-execution (matches the GitHub repo `Leavii/cadence`). All package names follow `@cadence/*`. The `bin` for the CLI is `cadence` (not `gsd`). The legacy placeholder names (`gsd`, `gsd-helper`, `gsd-server`, `gsd-cli`, `gsd-bot`, `gsd-team`) are still listed in `reserved-handles.json` under category `project` so users can't impersonate the prior naming if it ever surfaces in user-facing copy.
2. **Execution mode = orchestrator-inline.** Two subagent attempts (with `isolation="worktree"`) wrote all the files but their worktree filesystems were torn down by the runtime before recovery could complete. The orchestrator wrote the files directly on the main tree to avoid the race entirely. Trade-off: more orchestrator context burned; benefit: deterministic. Recovery pattern documented in 00-01-SUMMARY.md and Phase 0 carryovers.

## Open items / carryovers

- **Task 1 (Ko-fi handle, non-blocking):** user chose "use placeholder." `{maintainer-handle}` remains a literal in README.md with a TODO comment. Donation link exists but isn't reachable until handle is assigned. FND-06 partially satisfied; fully satisfied when the placeholder is swapped (no specific deadline given the project's private-default posture).
- **Reserved-handles enforcement:** Phase 1 must wire signup-time validation against this JSON and reserve the matching frontend routes with 404s.
- **Architecture rules enforcement:** Phase 1 must install the Pino redaction transport and the `sk-ant-*` CI grep gate before any code that handles tokens lands. Phase 5 must add the HELPER-11 / HELPER-12 code review checklist items.

## Verification

Acceptance-criteria greps from 00-04-PLAN.md ran green: README posture sentence + Ko-fi link present, package.json carries Apache-2.0 + private:true, pnpm-workspace lists `apps/*`, turbo.json carries `tasks`, reserved-handles.json contains `anthropic` (brand-impersonation reservation) and validates as JSON with 200 entries across 9 categories, architecture doc contains both load-bearing rules and the redaction policy. All 8 workspace package.json files validate as JSON.

## Threat coverage

- T-helper-asserts-state → mitigated by docs/architecture/00-overview.md Rule 1, enforced in Phase 5.
- T-anthropic-token-leak → mitigated by docs/architecture/00-overview.md Rule 2, enforced in Phase 1 (Pino + CI grep) and Phase 5 (helper review).
- T-impersonation (reserved-handle squat) → mitigated by reserved-handles.json definition (200 entries / 9 categories), enforced in Phase 1.

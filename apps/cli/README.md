# @cadence/cli

The cadence helper CLI. Pairs a local Claude Code install with the backend, ingests hook events, and exposes a `cadence stats` command any statusline can call. Implementation lands in Phase 5.

**Hard rule:** the helper never asserts game state. It only reports observed signals. The backend is the single source of truth for XP, quests, streaks, leaderboards. Codified in `docs/architecture/00-overview.md` and enforced in Phase 5 (HELPER-11).

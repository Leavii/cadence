# cadence

> Gamification service for Claude Code users. A web app, backend, and helper CLI that turn real workflow signals — token usage, sessions, context efficiency, hook events — into quests, achievements, leaderboards, and cosmetic unlocks. Statusline-agnostic.

## Maintenance posture

This is a hobby project maintained on a best-effort basis. Issues and PRs are welcomed but not guaranteed a response within any specific timeframe. The public hosted instance is capped at 5,000 active accounts; if that fills up, please run your own with `docker compose up`.

## Self-host quickstart

```bash
git clone {repo-url}
cp .env.example .env
docker compose up
# Mailpit UI → http://localhost:8025
```

## Architecture

See [docs/architecture/00-overview.md](./docs/architecture/00-overview.md) for the load-bearing architectural rules (helper never asserts game state; Anthropic OAuth token never reaches the backend) and the three-tier system overview.

## Status

Phase 0 (project scaffolding) — no product features yet.
See [.planning/ROADMAP.md](./.planning/ROADMAP.md) for the 11-phase plan.

## Support / donations

If this project is useful to you, please consider supporting maintenance:
[Ko-fi](https://ko-fi.com/{maintainer-handle})

<!-- TODO: replace {maintainer-handle} once Ko-fi account is created (FND-06 / CD-01) -->

GitHub Sponsors will be enabled when/if the repo flips public.

## License

Apache-2.0 — see [LICENSE](./LICENSE).

## Contributing

By contributing you agree to the [Developer Certificate of Origin](https://developercertificate.org/).
See [CONTRIBUTING.md](./CONTRIBUTING.md) and [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md).

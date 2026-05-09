# Contributing

Thanks for considering a contribution. This project is maintained on a best-effort basis; please be patient.

## Sign-off (DCO)

Every commit must include a `Signed-off-by:` trailer. By signing off you agree to the [Developer Certificate of Origin](https://developercertificate.org/).

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

## Local verification

After cloning, you can run the phase-wide smoke gate:

```bash
bash scripts/verify-phase-0.sh
```

This is created in Plan 00-02 and asserts the legal / governance / parity contracts of Phase 0 (LICENSE, CoC, DCO workflow, license-check workflow, docker-compose stack, env example, gitignore secret protection).

## License

By contributing, you agree your contribution is licensed under Apache-2.0 (the project license). Inbound license matches outbound license — by submitting a PR you assert the right to contribute the code under Apache-2.0.

## Code of Conduct

This project follows the [Contributor Covenant 2.1](./CODE_OF_CONDUCT.md).

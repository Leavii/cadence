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

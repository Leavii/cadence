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

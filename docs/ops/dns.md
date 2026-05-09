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

> **SPF lookup limit (Pitfall 6):** SPF allows a maximum of 10 DNS lookups.
> `include:amazonses.com` currently resolves within that budget. If a second mail
> provider (e.g., Postmark, Mailgun) is added in the future, audit the total
> lookup count before committing the new `include:` mechanism. Exceeding 10
> lookups causes SPF to return `permerror`, breaking deliverability for all mail.

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

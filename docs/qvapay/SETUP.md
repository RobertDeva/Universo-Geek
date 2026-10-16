# QvaPay integration status and setup gate

## Current status

The QvaPay Edge Functions are **not implemented** in this repository. The following files are currently absent and must not be treated as deployable:

- `supabase/functions/qvapay-create-invoice/index.ts`
- `supabase/functions/qvapay-check-status/index.ts`
- `supabase/functions/qvapay-webhook/index.ts`

Membership payments must remain disabled until the integration is implemented and reviewed. Do not mark an order as paid based on a browser redirect, client-provided status, or an unverified webhook.

## Required work before enabling payments

1. Confirm the current QvaPay API documentation, account eligibility, supported jurisdictions, and merchant requirements.
2. Implement invoice creation in a server-side Edge Function. Validate the authenticated user, order, amount, currency, and allowed membership plan on the server.
3. Implement status verification by querying QvaPay server-to-server. Treat provider responses as untrusted until authenticated and validated.
4. Implement the webhook only after confirming QvaPay's actual signature/authentication mechanism. Verify authenticity, validate the invoice/order association and amount, and make processing idempotent.
5. Keep provider credentials in Supabase Edge Function secrets. Never expose secret keys in frontend files or commit them to Git.
6. Make paid-state transitions server-controlled and idempotent. A client must not be able to set `status = 'paid'` directly.
7. Add automated tests for invalid signatures, duplicate callbacks, mismatched amounts/users, pending/failed payments, provider timeouts, and replay attempts.
8. Verify the migrations and all Edge Functions in an isolated test project, then review the deployment plan before enabling the integration in production.

## Configuration rule

Do not add function declarations to `supabase/config.toml` or deploy these functions until their source files and tests exist. This avoids implying that the payment integration is available when it is not.

## Scope of this change

This document does not implement QvaPay, does not activate payments, and does not change membership payment state. It records the release gate so future implementation can be done and reviewed separately.

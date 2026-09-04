# EVRYLUX Brain Recovery Security Hardening

## What this patch closes

- 10-minute recovery request expiration.
- Server-generated `recovery_request_id`.
- Recovery request bound into HKDF + AEAD AAD.
- Target fingerprint bound into HKDF + AEAD AAD.
- Public key ↔ fingerprint verified locally before wrapping.
- Server validates sender public key, target fingerprint, request id and expiry.
- One-time atomic `claim_brain_device_envelope`.
- Legacy load + consume RPCs revoked.
- Direct authenticated SELECT access to device/envelope tables removed.
- Device listing/get now require an already-authorized device secret.
- First-device bootstrap only when the vault has never had any device row.
- Revoked-all vault cannot silently bootstrap a new device.
- Revocation consumes outstanding envelopes and closes active request.

## Important behavior

`claim_brain_device_envelope` consumes the envelope in the same database
transaction that returns it. If the app crashes after the claim and before
local key import, that envelope cannot be replayed. Start a fresh recovery
request. This is intentional fail-closed behavior.

## Apply

From the project app directory:

```bash
supabase db push
```

or apply `supabase/migrations/20260904_brain_recovery_security_hardening.sql`
through your normal Supabase migration flow.

Then run:

```bash
flutter analyze
```

## Not included

Master Key rotation after device revocation remains a separate future phase.

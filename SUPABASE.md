# Kidz — Supabase backend

The backend lives in `supabase/` and is version controlled. Nothing in this
repository contains a real URL, key, token or password — every value below is a
placeholder.

## Configuration

The app reads its connection settings at build time via `--dart-define`. There
is no fallback and no committed default: if either value is missing the app
shows a "Configuration required" screen naming the missing keys.

| Key | Purpose |
| --- | --- |
| `SUPABASE_URL` | `https://YOUR_PROJECT_REF.supabase.co` |
| `SUPABASE_PUBLISHABLE_KEY` | The publishable (client) key, `sb_publishable_…` |

Never pass a `service_role` key, a secret key, an access token or the database
password to the Flutter app. The client is protected by Row Level Security, not
by hiding the publishable key.

### Run

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_YOUR_KEY
```

### Build

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_YOUR_KEY
```

If you keep the values in a file, use `--dart-define-from-file` and make sure
that file is git-ignored (`supabase.local.json` already is).

## Schema

| Table | Purpose | Readable by |
| --- | --- | --- |
| `users` | Profile, keyed by `auth.users.id` | owner; Admin after Phase 1 migration |
| `sellers` | Seller registration, one per user | owner; Admin after Phase 1 migration |
| `products` | Catalogue | **public** (guest browsing) |
| `cart` | Buyer basket | owner only |
| `orders` | Order history, `order_items` as `jsonb` | owner; Admin after Phase 1 migration |
| `bankingcard` | Demo saved cards | owner only |
| `admin` | Legacy — RLS on, **no policies**, unreachable | nobody |

Storage bucket `product-images` is public for reads. Uploads are restricted to
registered sellers writing under `products/`. Update and delete are denied to
all client roles, which is what prevents one seller from overwriting another's
image (the upload path carries no seller segment).

## Applying

Phase 1 Admin changes are local and have **not** been applied to the hosted
project. Do not run the hosted commands below as part of local review. See
[Admin restoration and operator runbook](ADMIN_PHASES.md) and
[verification results](ADMIN_VERIFICATION.md).

Phase 2 is also local only. It restores the original supported management
operations using narrow server-side RPCs and strengthens Admin reads with live
role/session checks. See [ADMIN_PHASE2.md](ADMIN_PHASE2.md) for behavior changes,
SQL/foreign-key details, safe integration steps, and current test results.

```bash
supabase link --project-ref YOUR_PROJECT_REF
supabase db push --linked --dry-run --skip-vault    # review first; requires approval
supabase db push --linked --skip-vault              # NOT run in local implementation
```

`supabase/seed.sql` holds synthetic demo products and contains no credentials.
It runs on `supabase db reset` (local only), not on `db push`. Test accounts are
created through the app's normal registration screen.

### Tests

`supabase/tests/rls_contract_test.sql` is a pgTAP suite covering the negative
RLS cases (guest cannot write, buyers cannot see each other's carts or orders,
sellers cannot touch each other's products). Requires Docker:

```bash
supabase test db --local
```

## Known issues in the existing application

These are pre-existing app behaviours the backend deliberately does not enable:

- **Legacy `admin` credentials** — the table remains locked with RLS and no
  policies. Phase 1 removes its login lookup and uses Supabase Auth plus the
  server-controlled `app_metadata.role = "admin"` claim. Admin reads require the
  new local migrations; Phase 2 restores only historically supported actions
  through role/session-checked RPCs. The trusted
  operator tool and the separate Phase 2 management plan are documented in
  [ADMIN_PHASES.md](ADMIN_PHASES.md); the implemented management restoration is
  documented in [ADMIN_PHASE2.md](ADMIN_PHASE2.md). No hosted changes have been performed.
- **`bankingcard` stores a CVV** — `lib/addcard.dart` writes a raw card number
  and CVV. Storing a CVV is prohibited by PCI-DSS. The table is owner-locked and
  must only ever hold synthetic demo values. Replace with a payment provider
  token before any real use.
- **Account deletion is disabled** — see below.

## Account deletion (BLOCKED — needs an Edge Function)

`lib/account.dart` previously deleted the user's orders, cart, saved cards,
products, seller row and profile, signed them out, and only then called
`supabase.auth.admin.deleteUser(...)`. That endpoint is part of the **admin**
API and is authorised by the `service_role` key. The app ships the
**publishable** key, so the call always throws — after the business data had
already been destroyed. The user was left signed out, with an auth account that
still existed and a generic "try again" message.

The action now opens a dialog explaining that deletion must be completed by the
server, and performs **no** writes. Nothing is removed.

### Edge Function plan (`delete-account`)

Not deployed. Implement before re-enabling the UI.

1. **Caller verification** — read the `Authorization: Bearer <access_token>`
   header, build a client with the **anon** key plus that header, and call
   `auth.getUser()`. Reject with 401 if it fails. Never trust a user id from
   the request body; the id to delete is always `user.id` (i.e. `auth.uid()`).
2. **Secrets** — the function reads `SUPABASE_SERVICE_ROLE_KEY` from Edge
   Function secrets (`supabase secrets set`). It is never returned in a
   response, never logged, and never present in the Flutter bundle.
3. **Scope** — a second, service-role client deletes exactly one auth user:
   `admin.deleteUser(user.id)`. No parameter allows deleting anyone else.
4. **Dependent data** — every table's FK to `auth.users(id)` is already
   `on delete cascade`, so `users`, `sellers`, `cart`, `orders` and
   `bankingcard` disappear with the auth row, and `products` cascade from
   `sellers`. Storage objects do **not** cascade: the function must list
   `product-images` objects belonging to the seller's products and remove them
   with the service-role client, because client roles have no delete policy on
   that bucket (deliberately — see above).
5. **Confirmation and errors** — require an explicit typed confirmation in the
   app before calling. Return 200 with a JSON result, 401 unauthenticated,
   4xx for a malformed request, 5xx on failure. Deletion should be idempotent:
   an already-deleted user returns success. On any error the function must not
   leave partial state — delete storage objects first, then the auth user, and
   report failure without signing the user out.
6. **Deployment and tests** — `supabase functions deploy delete-account`;
   secrets set out-of-band. Tests: (a) no token → 401; (b) token for user A
   cannot delete user B; (c) successful deletion removes the auth row and all
   dependent rows; (d) storage objects for that seller are gone; (e) re-running
   is idempotent; (f) the response body never contains a key or token.

Only after this exists should `deleteAccount()` call the function and restore
the confirm-and-delete flow.

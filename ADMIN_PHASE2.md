# Phase 2: original Admin management restored locally

> **Later status, verified 2026-11-06:** both Admin migrations are applied to
> the hosted database. This document preserves the earlier local implementation
> or verification record; its no-hosted-change statements refer to that task.
> See [Current State](docs/current-state-2026-11-06.md) for read-only confirmation
> and the confirmed Seller regression blocking the final `main` merge.
>
> Historical instructions below are not a directive to repeat migration or
> account creation. This documentation review changed no hosted data or settings.

Implementation is local only. No hosted migrations, account/password/role changes,
credential changes, settings changes, or deployments were performed. The local
Admin remains an application Admin, never a Flutter client with a service key.

## Historical evidence and exact permissions

The baseline is Git commit `5ead0d7` (`capture pre-recovery kidz_store baseline`),
the earliest available project version. `git show` of all five Admin Dart files
was compared with `KIDZ_PROJECT_DOCUMENTATION.md`, `ADMIN_PHASES.md`, the initial
schema, and later Git history. Commits `4c4b82b`/`077eca7` changed presentation and
image fallback, not management permissions. Commit `4285622` reconstructed the
backend and intentionally locked the plaintext Admin table. Phase 1 is the
existing local, uncommitted secure Auth/read-access implementation.

The original Admin dashboard had four management links, four totals, and a bar
chart. Original executable mutations were exactly:

```text
manage_users.dart:    DELETE public.users WHERE id = target
manage_products.dart: DELETE public.products WHERE id = target
manage_orders.dart:   UPDATE public.orders SET status = chosen WHERE id = target
```

`manage_sellers.dart` only selected/listed seller registrations. No historical
Admin create-user, edit-profile, create/edit-product, seller approval/edit/delete,
order creation/deletion, refund, or role-editor action was found. Those are not
invented in this restoration. Admin can perform all evidenced management actions
across application records, regardless of Buyer/Seller ownership.

| Screen / operation | Original behavior | Restored behavior |
| --- | --- | --- |
| Login / session | Plaintext Admin-table check; no real Admin session | Supabase Auth; verified exact server `app_metadata.role = admin`; guarded screens |
| Dashboard | Counts and chart from selected IDs; management navigation | Existing layout/navigation preserved; exact counts and refresh on returning from management |
| Manage Users: view | All profile names/contact data | All application profiles, nullable-name handling, correct mobile field, all result pages |
| Manage Users: delete | Profile-only deletion; Auth account remained | Confirmed atomic Auth-account deletion with scoped dependent cleanup and retained order history |
| Manage Sellers | List company/registration/product type | Same screen, all sellers; no invented mutations |
| Manage Products: view | Product image/name/price | Same list, guarded, all result pages |
| Manage Products: delete | Delete product; refresh | Actual deletion, with disclosed cart cascade, unchanged historical orders, retained image objects |
| Manage Orders: view | Dates, totals, statuses | Same list, all orders including retained deleted-account history |
| Manage Orders: update | Any selection among Packaging/Shipping/Delivering | Same three choices, including backwards correction; server validation and stale-edit protection |

An unknown stored status is displayed as stored rather than silently relabeled
Packaging. An Admin may correct it to an original supported status. No new global
forward-only transition graph is imposed because the original implementation
did not contain one. Changes to prices, ownership, item snapshots, or addresses
are not accepted by the status API.

## Server-side security boundary

`supabase/migrations/20261106034711_admin_management.sql` implements the trusted
operations. There is no Edge Function or new runtime server secret to deploy.
Flutter uses its existing publishable key and normal signed Auth session.

Public PostgREST RPC wrappers use **SECURITY INVOKER** and delegate to narrowly
scoped **SECURITY DEFINER** bodies in the non-exposed `kidz_private` schema:

| Public RPC | Accepted input | Permitted effect |
| --- | --- | --- |
| `admin_preview_delete` | `p_kind` user/product; exact UUID `p_id` | Authorized impact preview and version-bound confirmation token |
| `admin_delete_record` | Kind, UUID, preview token, exact `DELETE` confirmation | Delete only that supported record/account and disclosed dependent records |
| `admin_set_order_status` | Order UUID, supported status, expected `updated_at` | Update status only for that order |

There is no caller-supplied actor ID, table name, SQL, arbitrary filter, or general
update body. Anonymous roles cannot execute these wrappers. Buyer/Seller tokens
cannot pass the server check, even when bypassing Flutter or editing metadata.
Private implementations also check authorization, so calling an implementation
directly does not bypass the boundary.

The check requires a non-null authenticated identity, exact Admin JWT role, future
JWT expiry, matching existing `auth.sessions` row, unexpired session `not_after`,
and an existing confirmed, non-deleted, non-banned Auth user with the current
server application role. Current user/session rows are locked for the mutation
transaction. Role demotion and session removal therefore deny the old token at
the database boundary. User-editable metadata is never used.

The Phase 1 Admin SELECT policies now call the same live check. Buyer/Seller
ownership policies and public product reads remain unchanged. No broad Admin
INSERT/UPDATE/DELETE RLS policy is introduced. The legacy `admin` table, private
carts/cards, arbitrary storage operations, and private audit data remain
inaccessible to the Admin client.

The private audit table records actor UUID, action, target UUID, impact counts or
old/new status, and timestamp in the same transaction. No passwords, tokens,
keys, or email labels are recorded. Client roles cannot read or modify it.

## Deletion behavior and necessary changes

Deletion remains deletion; neither delete button has been changed into archival,
suspension, or a hidden background operation.

### User account deletion

The old profile-only operation was incomplete. The new server transaction deletes
the exact target from `auth.users`; its identity/session and application FK
cascades remove the account, profile, saved cards, seller registrations, products,
and affected cart entries. The UI previews these counts and requires typing
`DELETE`. It blocks duplicate submissions and re-verifies access after the dialog.

**Order history is retained.** The only business-column/FK change makes
`orders.user_id` nullable and changes its Auth FK from CASCADE to SET NULL. All
order totals, items, dates, payment labels, delivery snapshots and other historical
fields remain. Existing owner RLS denies NULL-owned history to Buyers/Sellers;
authorized Admins can still inspect it. The deleted identity cannot authenticate
again, and an old token cannot recreate FK-owned rows.

The transaction also removes that target's legacy refresh tokens without a
session link and pending PKCE/recovery `flow_state` rows, which lack user FKs in
the inspected managed schema. Session-linked refresh tokens otherwise cascade
with their session. No other user's Auth records are touched.

This is a direct, server-authorized database transaction, not an Auth Admin HTTP
call from Flutter. Keeping Auth deletion, FK behavior, media ownership and the
audit insert in one transaction prevents partially deleted accounts if any step
fails. Supabase documents direct deletion from `auth.users` and its JWT lifetime
limitations in [User Management](https://supabase.com/docs/guides/auth/managing-user-data#deleting-users).
GoTrue HTTP-specific hooks/notifications are not invoked by this SQL operation;
full managed-service integration remains a required verification step.

Stored product-image objects owned by the deleted user are retained, with only
their `owner_id` and legacy `owner` metadata reassigned to the acting Admin.
Object names, public URLs, physical payloads and order image references are not
deleted or rewritten. Clients gain no storage UPDATE/DELETE policy from this.
No image URL is treated as a deletion instruction or used to fetch/delete an
arbitrary external resource. Ownership fields were confirmed against the hosted
schema with a **read-only catalog query**; no hosted records were changed.

Safety restrictions: the current Admin and all Admin accounts are protected from
Manage Users deletion (historical Admins were in a separate credential table and
were not targets of the user list). This also protects the last Admin. An Auth
identity without an application profile cannot be deleted through this endpoint.
Accounts owning buckets or objects outside `product-images` are refused for
operator review, rather than deleting unrelated resources. These restrictions
are explicit and leave all data unchanged on refusal.

### Product deletion

The product is physically deleted from the catalogue. Existing cart FK cascades
remove cart entries referencing it; the UI explicitly discloses that this can
affect other buyers. Order-item JSON snapshots remain unchanged. Storage objects
are retained so shared URLs and historical orders do not lose their images.
Orphan-image cleanup is deliberately not invented as an Admin capability.

### Stale effects, transactions and concurrency

Deletion previews include a token derived from record versions and impact counts.
The server recomputes it under short transaction locks and refuses a mismatch,
forcing a fresh preview/confirmation. It does not trust client impact counts.
Status edits compare the expected `updated_at` before changing the row.

Competing Admin mutations also use a transaction-scoped, non-waiting advisory
mutex. Contention returns HTTP 409 instead of implicitly retrying a destructive
request. Missing records return explicit HTTP 404. These error responses are
handled without displaying raw database details.

Deletion locks application tables and storage-object metadata in a consistent
order to coordinate with ordinary Buyer/Seller writes; lock waits are bounded.
No network calls or user interaction occur while locks are held. This favors
integrity for the existing small store; high-volume concurrency should be load
tested before rollout. PGlite is a single-connection engine; a separate real
Supabase stack successfully tested simultaneous status changes and deletions.
High-volume load behavior remains unverified. Real checkout/payment workflows
were not changed.

## Local verification and remaining limitations

See `ADMIN_PHASE2_VERIFICATION.md` for final PASS/FAIL/UNVERIFIED results, commands,
and the complete Phase 2 file manifest. The SQL harness uses an in-memory
Postgres engine with synthetic Supabase Auth/Storage interfaces; it loads all
three migration files unchanged. It does not connect to a hosted database or
claim to reproduce GoTrue, Storage payload handling, or PostgREST transport.

`supabase/tests/admin_management_test.sql` is also provided for pgTAP against a
fresh local **full Supabase stack**. Existing read-policy tests now supply a live
synthetic Admin session and confirmed metadata for the stricter server checks.
The existing contract plan remains corrected to 26. Docker was initially
unavailable, then became available during verification. A fresh, unlinked local
stack subsequently passed **94 pgTAP assertions and 34 real Auth/REST/Storage
checks**, including simultaneous mutations. That test stack and its synthetic
volumes were removed afterward. Hosted integration remains unperformed.

## Initial Admin creation and password setting

The existing Phase 1 operator tool remains unchanged. Use a dedicated Admin
identity; never promote an existing Buyer/Seller as an automatic fallback.
Passwords and server keys are entered only at masked prompts, never in a Flutter
define, command argument, source file, or test output. See the complete runbook
in `ADMIN_PHASES.md`.

Preview without any network or secret prompts:

```powershell
.\tools\admin-account.ps1 -Action Create -Email admin@your-domain.example `
  -VerifiedEmailOwnership -WhatIf
```

Only after separate hosted-account approval, remove `-WhatIf`, confirm the exact
project/email, and supply the server key and a unique 16+ character password at
the prompts. The tool creates a dedicated confirmed Auth user with the Admin
application role. To reset its password after approval, use `-Action ResetPassword
-Email ... -UserId <AUTH-UUID>`; it verifies that exact UUID/email and existing
Admin role and sends a password-only Admin API update. Sign in afresh so the
JWT contains the role and a live Supabase session ID.

## Subsequent integration steps (NOT executed)

1. Review the complete diff, the behavior changes above, and the private SQL
   routines. Preserve existing local changes and back up the intended hosted
   project before any separately approved rollout. No backup or hosted mutation
   was performed in this task.
2. Reproduce the portable local tests from the project root:

   ```powershell
   flutter.bat test --no-pub
   npm.cmd ci --prefix tools/admin-db --cache .dart_tool/admin-db/npm-cache --ignore-scripts --no-audit --no-fund
   npm.cmd test --prefix tools/admin-db
   Invoke-Pester -Script tools/admin-account.Tests.ps1
   ```

3. Reproduce the complete local stack checks with Docker running:

   ```powershell
   .\tools\test-admin-stack.ps1
   ```

   The runner creates a fresh `.dart_tool/kidz_admin_verify_<random>` workdir,
   distinct project ID, and ports 55321/55322, without a linked project or copied
   data. It pins the tested local service versions, applies all three migration
   files unchanged, runs pgTAP **before** HTTP fixtures, then tests real Auth,
   REST, Storage, metadata spoofing, deletion, image-byte retention, concurrency,
   role demotion and logout. Keys are captured only in process memory and are
   never printed. Cleanup stops/removes only the exact stack/volumes just
   created. It never uses `--all`, hosted URLs, `db reset`, or existing stack data.
   The first run may download Docker images. Keep these ports unused; the runner
   refuses to overwrite an active prior Admin verification stack.
4. Resolve any integration failure or UNVERIFIED service behavior before real
   account deletion is enabled in an approved hosted environment. Keep
   `kidz_private` out of exposed Data API schemas. Review ownership/grants of
   new routines, the nullable order FK, and the exact existing managed schema.
   Do not broaden Buyer/Seller policies to work around an error.
5. After explicit hosted-migration approval, use CLI help for the installed
   version. With the currently inspected CLI 2.121.0, review pending history and
   preview exactly the Phase 1/2 migrations:

   ```powershell
   supabase migration list --linked
   supabase db push --linked --dry-run --skip-vault
   ```

   Stop if unrelated migrations or schema drift appear. Only after reviewing the
   preview and obtaining hosted rollout approval, the application command is
   `supabase db push --linked --skip-vault`. Do not include roles, seed data or
   credential arguments. `--skip-vault` prevents incidental Vault-secret updates.
   Never use `db reset` on a hosted project. These commands were NOT run here.
6. Allow PostgREST's schema cache to reload; confirm the three named RPCs are
   discoverable for authenticated requests and private bodies are not exposed.
   No Edge Function deployment or new runtime secret is needed. Run the relevant
   database security advisors against the approved environment and review the
   new functions/grants; existing unrelated advisories require separate review.
7. After distinct account-operation approval, provision the dedicated Admin
   using the masked operator tool, then sign in afresh in Android and Web using
   the existing publishable configuration. Verify all lists/totals. Run actual
   destructive end-to-end checks only in the isolated/staging synthetic project,
   never against existing hosted Buyer/Seller accounts as a test.
8. Rebuild the app with its intended public URL/publishable key only after review.
   Builds produced during this task use deliberately invalid synthetic public
   settings and are compilation checks, not deployable hosted integrations.

If rollback is needed before any deletion, remove RPC EXECUTE privileges/disable
the controls and review the migration reversal. After a confirmed deletion, the
Auth identity and cascaded data cannot be reconstructed by reversing DDL; recover
from an approved backup if required. Retained orders must not be cascade-deleted
as part of a rollback.

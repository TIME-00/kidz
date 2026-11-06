# Phase 2 implementation and verification

> **Later status, verified 2026-11-06:** both Admin migrations are applied to
> the hosted database. This document preserves the earlier local implementation
> or verification record; its no-hosted-change statements refer to that task.
> See [Current State](docs/current-state-2026-11-06.md) for read-only confirmation
> and the confirmed Seller regression blocking the final `main` merge.
>
> Historical instructions below are not a directive to repeat migration or
> account creation. This documentation review changed no hosted data or settings.

Completed locally on 2026-11-06 in `<project>`.
No commit or deployment was made. No hosted database schema/data, accounts,
passwords, roles, credentials or project settings were changed. Hosted access
was limited to read-only catalog inspection of managed Auth/Storage columns and
foreign keys; no hosted mutation tests were run.

The existing `android/gradle.properties` change and untracked
`devtools_options.yaml` were preserved. Their hashes were recorded before the
build checks and compared afterward. Global Flutter, Java/JDK, Android Studio,
PowerShell and Git settings were not modified. Docker test containers/volumes
were uniquely named, contained only synthetic fixtures, and were removed after
the run. Other Docker projects were not stopped or reconfigured.

## Final results

| Check | Final result | Scope |
| --- | --- | --- |
| Full Flutter suite | **PASS: 137 tests** | Existing suite plus secure Auth/routing/guards and restored action/error/confirmation tests |
| Targeted Dart analysis | **PASS: no issues** | Auth, management, all five Admin screens, routing and associated test/support files |
| Full `flutter.bat analyze --no-pub` | **NOT CLEAN: exit 1** | 0 errors, 17 existing warnings, 92 existing informational findings; no configuration suppressions or unrelated cleanup |
| In-memory Postgres scenarios | **PASS: 29 scenarios** | All three migrations loaded unchanged; RLS, direct RPC authorization, transactions, cascades, rollback, owner isolation, grants and retained history |
| Full isolated Supabase pgTAP | **PASS: 94 assertions / 3 files** | Fresh real local database with managed Auth/Storage schema; executed before HTTP fixtures |
| Full isolated Auth/REST/Storage | **PASS: 34 checks** | Real sign-in/signup, Storage upload/download, RPCs, metadata spoofing, deleted-account login/refresh rejection, concurrent actions, role demotion and logout |
| Existing operator tool tests | **PASS: 14 tests** | Mocked Admin API calls only; no hosted account operations |
| Web build | **PASS** | `flutter.bat build web --no-pub`; JS build and Wasm dry run succeeded |
| Android debug APK build | **PASS** | Existing Android/JDK/Gradle configuration retained; `assembleDebug` succeeded |
| Node/PowerShell test-runner syntax | **PASS** | Node syntax checking and PowerShell AST parsing |
| Credential literal / Git whitespace checks | **PASS** | No real-shaped secret/JWT literals in authored changes; CRLF-aware `git diff --check` |
| Hosted integration / Production behavior | **UNVERIFIED, not attempted** | Explicitly outside approval; must be reviewed separately |
| Manual device/browser UI sessions | **UNVERIFIED** | Compilation and widget tests passed; no manual Android/Web interaction with hosted services |
| High-volume load and external Auth hooks | **UNVERIFIED** | Targeted two-request concurrency passed; no load benchmark or GoTrue HTTP-delete notification hook assertion |

Both builds used `SUPABASE_URL=https://synthetic.invalid` and an explicitly
synthetic publishable value. They are compilation artifacts, not builds ready
to connect to the hosted store. No real secret was supplied to Flutter.

### Full-stack environment

The final runner created `kidz_admin_verify_4ce91ecf` under `.dart_tool/`, without
a `project-ref` link, on API/DB ports **55321/55322**. Service versions were pinned
inside that isolated workdir only:

- Postgres `17.6.1.121`
- GoTrue `v2.192.0`
- PostgREST `v14.7`
- Storage API `v1.61.10`

This differs from the hosted service patch versions; it does not claim a hosted
rollout was validated. Docker images were cached/downloaded, not global settings
changed. CLI startup/status credentials were captured in process memory and
never logged or saved as fixture files. The HTTP harness refuses any URL except
the generated, unlinked loopback test project. Cleanup used the exact generated
project ID, never `--all`, a hosted reset, or another project's volume.

The final pgTAP run reported:

```text
admin_access_test.sql ...... ok  (42 assertions)
admin_management_test.sql .. ok  (26 assertions)
rls_contract_test.sql ...... ok  (26 assertions)
Files=3, Tests=94
Result: PASS
```

The original contract's `plan(22)` mismatch remains corrected to `plan(26)`.

### What the real HTTP checks established

- Admin can read all application fixture profiles; Buyer/Seller only their own.
- Normal Buyer registration and Seller self-registration still work.
- Seller product creation and image upload work under existing ownership RLS.
- Guests, Buyers, Sellers and refreshed spoofed `user_metadata.role` tokens cannot
  invoke the Admin RPCs directly.
- Admin can update another Buyer's order. Stale status requests return HTTP 409;
  two concurrent requests produce one success and one conflict.
- Actual product deletion removes its cart references; historical item snapshots
  and fetched image bytes remain unchanged.
- Actual account deletion removes the GoTrue identity: Admin lookup returns 404,
  password sign-in fails, and the old refresh token cannot obtain a new session.
- Orders survive with NULL account ownership, unchanged totals and item snapshots;
  the deleted Buyer's old token cannot read them.
- Seller-account deletion removes its remaining products and retains actual
  public image bytes after scoped ownership reassignment. Another Seller's
  product remains unaffected.
- Concurrent deletion requests delete the target once; the competing request
  receives an explicit conflict rather than being implicitly retried.
- Demotion immediately removes global reads and RPC access from an already-issued
  Admin token. Logout likewise rejects the old signed token.

The portable Postgres tests additionally inject an audit failure to prove full
rollback of Auth/business rows and storage ownership, check private-function
grants, test malformed/expired/missing sessions, protect Admin accounts, reject
unrelated bucket ownership, and verify Buyer/Seller CRUD/FK isolation.

### Issues discovered and corrected during verification

An early pgTAP attempt overlapped HTTP fixture creation and failed its
empty-database count assumptions. It was rerun on a fresh stack with pgTAP first.
Real REST testing also showed that ordinary SQL serialization error codes were
surfaced as server errors. Expected conflicts now use explicit HTTP 409, missing
records use HTTP 404, and competing Admin mutations use a non-waiting transaction
advisory mutex. The final fresh full-stack run passed all checks. No failed test
was relabeled PASS without a successful rerun.

## Reproduce locally

From the Kidz project root:

```powershell
flutter.bat test --no-pub --reporter expanded
npm.cmd ci --prefix tools/admin-db --cache .dart_tool/admin-db/npm-cache --ignore-scripts --no-audit --no-fund
npm.cmd test --prefix tools/admin-db
.\tools\test-admin-stack.ps1
Invoke-Pester -Script tools/admin-account.Tests.ps1
```

Docker must be available for the full-stack runner; ports 55321/55322 must be
free. The portable in-memory suite needs no Docker. Do not run mutation fixtures
against a linked or existing-data database. The runner never uses the normal
local stack's default port 54322. It applies migrations only to its newly created
test project and cleans up that project's synthetic data afterward.

## Complete Phase 2 file manifest

Statuses below compare against the approved local **Phase 1** implementation,
which was already uncommitted. Paths are relative to `kidz_store`.

| Status | File | Change |
| --- | --- | --- |
| Modified | `.gitignore` | Ignore project-local SQL-test node_modules |
| Modified | `lib/admin_dashboard.dart` | Refresh original statistics when returning from management |
| Modified | `lib/manage_users.dart` | Restore confirmed account deletion and paged reads |
| Modified | `lib/manage_sellers.dart` | Preserve original list and read all pages |
| Modified | `lib/manage_products.dart` | Restore confirmed product deletion and paged reads |
| Modified | `lib/manage_orders.dart` | Restore original status action, version checks, refresh/error handling and paged reads |
| Modified | `test/admin_access_test.dart` | Assert restored action availability while retaining guard regressions |
| Modified | `test/support/auth_fakes.dart` | Offline paged-query and scoped-RPC support |
| Modified | `supabase/tests/admin_access_test.sql` | Confirmed Admin/session fixtures for live authorization |
| Modified | `ADMIN_PHASES.md` | Mark earlier proposal historical and link current restoration |
| Modified | `ADMIN_VERIFICATION.md` | Preserve Phase 1 record with current-report notice |
| Modified | `KIDZ_PROJECT_DOCUMENTATION.md` | Point legacy baseline descriptions to current Phase 2 behavior |
| Modified | `SUPABASE.md` | Current RPC/read policies, integration links, explicit local tests and Vault-safe future commands |
| Created | `lib/admin_management.dart` | Scoped RPC service, safe errors, paging and impact-confirmation dialog |
| Created | `supabase/migrations/20261106034711_admin_management.sql` | Trusted actions, live role/session RLS, audit and order retention FK |
| Created | `supabase/tests/admin_management_test.sql` | 26 full-stack pgTAP assertions for restored operations |
| Created | `test/admin_management_test.dart` | Restored action, denial, confirmation, conflict and paging tests |
| Created | `tools/admin-db/package.json` | Private project-local test package with exact PGlite pin |
| Created | `tools/admin-db/package-lock.json` | Locked test dependency/integrity |
| Created | `tools/admin-db/bootstrap.sql` | Explicit synthetic Auth/Storage interfaces for portable tests |
| Created | `tools/admin-db/test.mjs` | 29 isolated real-Postgres scenarios |
| Created | `tools/admin-db/fullstack.mjs` | 34 loopback-only real Auth/REST/Storage checks; private credentials stay in memory |
| Created | `tools/test-admin-stack.ps1` | Fresh isolated stack setup, ordered test run and exact-project cleanup |
| Created | `ADMIN_PHASE2.md` | Historical permission comparison, deletion changes, initial-Admin and hosted integration instructions |
| Created | `ADMIN_PHASE2_VERIFICATION.md` | This test evidence and complete manifest |

Phase 2 changed **13 files** and created **12 files** relative to Phase 1.
The following 10 earlier Phase 1 files also remain in the cumulative working
tree, unchanged by Phase 2:

```text
lib/login.dart
lib/main.dart
lib/session_routing.dart
lib/admin_access.dart
supabase/migrations/20261106030934_admin_read_access.sql
supabase/tests/rls_contract_test.sql
test/login_test.dart
test/session_routing_test.dart
tools/admin-account.ps1
tools/admin-account.Tests.ps1
```

Together these are **35 authored project files** across both phases. The user's
pre-existing Android and DevTools files are excluded. Generated build artifacts,
test workdirs, downloaded test dependencies and caches are ignored, not source
or configuration changes to commit.

## Deployment boundary

All historically evidenced management actions are implemented locally. The
intentional restrictions are documented: no plaintext authentication, no
Admin-account deletion through Manage Users, no unrelated-bucket destruction,
and no invented create/edit/refund/approval UI. Deletion is actual deletion with
disclosed dependent effects and order/image retention, not hidden archival.

Use `ADMIN_PHASE2.md` for the exact separately approved integration sequence.
Do not apply the migration, create/reset a hosted Admin, change credentials, or
publish these synthetic-config builds without further approval.

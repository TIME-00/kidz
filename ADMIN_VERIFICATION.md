# Phase 1 local verification

> **Later status, verified 2026-11-06:** both Admin migrations are applied to
> the hosted database. This document preserves the earlier local implementation
> or verification record; its no-hosted-change statements refer to that task.
> See [Current State](docs/current-state-2026-11-06.md) for read-only confirmation
> and the confirmed Seller regression blocking the final `main` merge.
>
> Historical instructions below are not a directive to repeat migration or
> account creation. This documentation review changed no hosted data or settings.

> Historical Phase 1 record. Phase 2 is now implemented locally, including a
> project-local isolated SQL test dependency. See
> [ADMIN_PHASE2_VERIFICATION.md](ADMIN_PHASE2_VERIFICATION.md) for current results
> and [ADMIN_PHASE2.md](ADMIN_PHASE2.md) for restored management permissions.

Verified on 2026-11-06 inside `<project>`.
No hosted accounts, passwords, role metadata, tables, policies, project settings,
credentials, or deployments were modified. No database was reset. Global Flutter,
Java/JDK, Android Studio, PowerShell, Git, Docker, and other project settings were
not modified. No dependencies or SDKs were installed/upgraded. The pre-existing
`android/gradle.properties` modification and untracked `devtools_options.yaml`
were preserved and are excluded from the authored-file manifest below.

## Final verification results

| Check | Result | Evidence / limitation |
| --- | --- | --- |
| `flutter.bat test --no-pub --reporter expanded` | PASS: 111 tests | Entire existing Flutter suite plus new Auth, routing and Admin-screen tests; no live Supabase client/socket is constructed by the new fakes |
| Targeted `dart analyze` | PASS: no issues | `lib/admin_access.dart`, `lib/admin_dashboard.dart`, `lib/login.dart`, `lib/session_routing.dart`, all four `lib/manage_*.dart` files, and the four changed/new Dart test/support files |
| `flutter.bat analyze --no-pub` | NOT CLEAN: exit 1 | 0 errors, 17 warnings, 92 informational findings (109 total); remaining findings are in existing code, including existing splash `print` / public-private-type lints in `main.dart`; unrelated cleanup was not undertaken |
| `Invoke-Pester -Script tools/admin-account.Tests.ps1 -PassThru` | PASS: 14 tests | API calls and password prompts mocked; no hosted account created or changed |
| PowerShell AST parsing | PASS: 0 errors | Operator script parses using installed Windows PowerShell |
| `supabase test db --local` | UNVERIFIED / BLOCKED: exit 1 | Connection refused at `127.0.0.1:54322`; no local database running |
| `docker version` server check | UNAVAILABLE | Docker Desktop Linux engine pipe absent; no service was started or setting changed |
| pgTAP original assertion plan | STATIC CHECK ONLY: 26 planned / 26 assertions | Corrected former `plan(22)` mismatch; database runtime remains unverified |
| Admin screen guard/mutation source inspection | PASS (static) | All five public screens use `AdminGate`; none contains insert/upsert/update/delete calls |
| Credential pattern scan of authored changes | PASS (static) | No real-shaped server secret or signed JWT literal found; synthetic markers only in tests; operator has masked input and whitelisted output |
| CRLF-aware Git whitespace check | PASS | `git -c core.whitespace=cr-at-eol diff --check`; temporary read-command option only, no Git config written |
| Hosted Auth / RLS / device integration | UNVERIFIED, not attempted | Explicitly outside local implementation approval; no hosted mutations or deployments |

The first test iteration exposed an SDK fixture-constructor mismatch and the
expiry test initially used a lifetime inside the SDK's 30-second expiry margin.
Both fixtures were corrected; the complete suite above subsequently passed.
Pester call-count assertions were scoped to each test for the installed Pester
3.4 runtime before obtaining the final 14/14 result.

### Authorization coverage

- Exact server-controlled Admin role, missing role, malformed/case-mismatched
  roles, and spoofed user metadata.
- Verified Admin login; Buyer/Seller shared-home destinations; restored Admin
  requires server verification; mismatched/changed identities denied.
- No session or expired session denied; upstream verification failure and
  unconfirmed email deny Admin restoration. Ordinary Buyer/Seller restoration
  retains offline Home entry without an extra server verification call.
- Direct navigation to Dashboard, Users, Sellers, Products, and Orders denied
  for guests, Buyers, Sellers, spoofed metadata, and verification errors before
  any protected query begins.
- Logout racing an in-flight verification, role demotion on Auth events,
  automatic content removal at expiry, and re-verification on app resume.
- Exact totals above 1,000 rows, nullable profile names, actual stored order
  status, disabled delete/update controls, and empty/error/retry states.
- Operator duplicate-account refusal, verified ownership, exact UUID/email
  targeting, preservation of application metadata, refusal to overwrite a
  different role, Admin-only password reset, client-key refusal, safe output,
  pinned project, forbidden DELETE, and no network/prompts under `-WhatIf`.

New pgTAP cases cover all three Admin SELECT policies; guest and owner isolation;
spoofed/malformed claims; Admin reads without cart/card/legacy access; denied
Admin writes to other users' business data; retained Seller ownership; and
post-refresh demotion. These are prepared SQL cases, NOT runtime passes.
Dedicated Admins retain ordinary owner rights to their own data under unchanged
existing policies. No general Admin write capability is added.

## Remaining gates

1. Have an isolated local Supabase test stack available, with synthetic data only.
   Apply both migrations in that test stack without resetting existing data, then
   run `supabase test db --local`. Do not use `--linked`, `--project-ref`, or a
   hosted connection string. The tests expect a fresh isolated fixture database.
   No system service setup, stack reset, or hosted workaround was performed here.
2. Review the local migration and runbook before separately authorizing any
   hosted rollout or dedicated Admin creation. Real Admin API transport and
   application-to-hosted-RLS integration have not been verified.
3. Review the existing 109 analyzer findings independently. They are not hidden
   by changing analyzer configuration or weakening check severity.
4. Phase 2 management writes require explicit approval of the action-specific
   design in `ADMIN_PHASES.md`; they remain disabled.

## Complete authored-file manifest

Paths are relative to `kidz_store`. No commit was made.

| Status | File | Purpose |
| --- | --- | --- |
| Modified | `lib/login.dart` | Auth-only login, verified role routing, safe errors, password whitespace, duplicate-submit guard |
| Modified | `lib/main.dart` | Verified session restoration routes Admin to Dashboard |
| Modified | `lib/session_routing.dart` | Admin destination and verified routing boundary |
| Modified | `lib/admin_dashboard.dart` | Guarded existing dashboard, exact counts, read states, logout |
| Modified | `lib/manage_users.dart` | Guarded read list, nullable names/mobile field, disabled deletion |
| Modified | `lib/manage_sellers.dart` | Guarded read list and read states |
| Modified | `lib/manage_products.dart` | Guarded read list and disabled deletion |
| Modified | `lib/manage_orders.dart` | Guarded read list, preserved stored status, disabled status updates |
| Modified | `supabase/tests/rls_contract_test.sql` | Correct plan to 26 |
| Modified | `test/session_routing_test.dart` | Verified Admin restoration and shared-home regressions |
| Modified | `SUPABASE.md` | Updated Admin policy and runbook links; no hosted rollout performed |
| Modified | `KIDZ_PROJECT_DOCUMENTATION.md` | Notice that legacy Admin sections describe the baseline |
| Created | `lib/admin_access.dart` | Auth verification, per-screen gate, read-state UI |
| Created | `supabase/migrations/20261106030934_admin_read_access.sql` | Three SELECT-only Admin policies, unapplied remotely |
| Created | `supabase/tests/admin_access_test.sql` | Isolated pgTAP authorization cases, runtime unverified |
| Created | `test/admin_access_test.dart` | Admin/Auth/role/guard/read-state tests |
| Created | `test/login_test.dart` | Invalid and valid Admin login UI tests |
| Created | `test/support/auth_fakes.dart` | Offline SDK-contract fakes; no credentials/network |
| Created | `tools/admin-account.ps1` | Trusted local Admin API operator tool |
| Created | `tools/admin-account.Tests.ps1` | 14 mocked operator tests |
| Created | `ADMIN_PHASES.md` | Phase 1 behavior, operator runbook, original-function inventory and Phase 2 plan |
| Created | `ADMIN_VERIFICATION.md` | This verification record and complete manifest |

Total: 12 modified and 10 created project files. Flutter test/build caches are
ignored generated artifacts and are not implementation/configuration changes.

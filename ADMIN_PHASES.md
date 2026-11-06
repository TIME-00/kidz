# Kidz Admin restoration

Phases 1 and 2 are implemented locally for review. No hosted migration, account
change, password change, setting change, or deployment has been performed.
The Phase 1 behavior and original Phase 2 proposal below are retained as a
historical design record. **Current restored permissions, deletion semantics,
and integration instructions are in [ADMIN_PHASE2.md](ADMIN_PHASE2.md).**
Current checks and the Phase 2 manifest are in
[ADMIN_PHASE2_VERIFICATION.md](ADMIN_PHASE2_VERIFICATION.md).

## Phase 1 behavior and authorization

- All login uses Supabase Auth email/password. The legacy credential-table lookup
  is removed; `public.admin` remains RLS-protected without policies.
- Only the exact string `app_metadata.role = "admin"` authorizes Admin access.
  Signup metadata, `user_metadata`, profile fields, and seller registration
  cannot assign this role. Passwords are not trimmed at login.
- Login and restored Admin sessions call Auth `getUser` to verify the current session.
  Verification failure, missing/expired sessions, unconfirmed email, or a changed
  identity deny privileged entry. Buyers and Sellers keep `HomePage` and existing
  profile-based Seller navigation. Ordinary Buyer/Seller session restoration
  retains its existing session-based Home entry, including offline entry. Admin
  restoration requires successful online verification; failure returns to login.
  Newly assigned Admin roles require a fresh login/token refresh.
- Every public Admin screen wraps its protected body in `AdminGate`, so its
  database reads do not begin before verification. Auth events, token expiry,
  and app resume recheck/remove protected content. Data reads show separate
  loading, empty, and retry states; raw upstream errors are not displayed.
- The Dashboard retains four management links, the count cards, and the chart.
  Counts use exact HEAD/count queries, not the length of a limited result page.
  Counts represent application profiles, seller registrations, products, and
  orders; profile count is not an independent count of Auth identities.
- User/product delete icons and the order-status dropdown remain visible but
  disabled. Their mutation methods are removed from the Admin screen code.
  Seller management was already a list without write controls.
- Admin lists select explicit fields instead of whole records. As before, these lists are subject
  to the configured REST row cap; pagination is a Phase 2 prerequisite for larger
  datasets. Dashboard counts do not have that limitation.

### Database migration (local file only)

`supabase/migrations/20261106030934_admin_read_access.sql` adds exactly three
`SELECT TO authenticated` policies: `users: admin read`, `sellers: admin read`,
and `orders: admin read`. Each requires a non-null `auth.uid()` and the exact
server-controlled JWT application role. Products already have public SELECT.

No tables, columns, account records, grants, triggers, or existing policies are
changed. No Admin INSERT/UPDATE/DELETE, cart, saved-card, storage, or legacy
credential access is added. Ordinary owner permissions still apply to an
Admin's own data, just as to any other Auth user; the Admin screens send no
writes. Use a dedicated Admin identity with no Buyer/Seller business activity.

RLS uses the signed JWT claim. Role demotion is reflected in RLS after token
refresh/expiry; it does not retroactively rewrite an issued token. The UI's
server verification also checks current application metadata, but UI guards are
not a replacement for RLS. A password reset must not be described as immediate
invalidation of every existing access token. Plan session revocation and strict
session checks for sensitive Phase 2 operations.

## Operator runbook (execute only after separate hosted-change approval)

`tools/admin-account.ps1` is a trusted operator program, not a Flutter asset or
an HTTP endpoint. It uses Supabase Auth Admin API POST/GET/PUT operations on the
pinned Kidz project. No service key or password is accepted on the command line,
written to a file, sent to Flutter, or included in output. Values are requested
with masked prompts and held in process memory. Managed strings cannot be
guaranteed erased from memory. Run on a trusted machine without a debugger or
HTTP tracing; never put real values into source, fixtures, screenshots, or chat.

The tool supports modern server secret keys and legacy service_role keys. It
rejects publishable/anon keys. It cannot delete users, change project settings,
follow HTTP redirects, or target a different project. API errors are generic;
there is no automatic retry or fallback from account creation to account update.
Confirmations show project/email/UUID, never credentials. `-WhatIf` performs no
requests and no credential prompts.

1. Complete isolated local RLS verification before scheduling a hosted rollout.
   Review the migration separately; it has NOT been pushed by this implementation.
2. Choose a new dedicated Admin email, verify that you control it, and generate
   a unique password in a password manager (tool minimum: 16 characters).
3. Preview creation without contacting Supabase:

   ```powershell
   .\tools\admin-account.ps1 -Action Create -Email admin@your-domain.example `
     -VerifiedEmailOwnership -WhatIf
   ```

4. After explicit hosted-change approval, run the same command without `-WhatIf`.
   Confirm the target. Enter the server secret and password only at the masked
   prompts. Creation uses `email_confirm = true` and `app_metadata.role = admin`,
   hence the prior ownership check. The Auth trigger creates the normal empty
   profile automatically. Record the returned UUID in your private operator
   records. A duplicate-email error stops; never reuse an existing Buyer/Seller.
5. To inspect a specific dedicated identity, use its exact UUID and expected email:

   ```powershell
   .\tools\admin-account.ps1 -Action Inspect -Email admin@your-domain.example `
     -UserId <AUTH-UUID>
   ```

6. To explicitly assign the role to a separately provisioned dedicated Auth
   identity, use `-Action AssignRole -Email ... -UserId ...
   -VerifiedEmailOwnership`. This preserves other application metadata and
   refuses to overwrite an existing different role. It does not change passwords
   or email-confirmation state. Verify the identity is dedicated before use;
   absence of a role claim alone does not prove it has no Buyer/Seller history.
7. To reset only that Admin's password after approval:

   ```powershell
   .\tools\admin-account.ps1 -Action ResetPassword -Email admin@your-domain.example `
     -UserId <AUTH-UUID>
   ```

   The tool fetches the exact UUID, verifies expected email and existing Admin
   role, then sends a password-only update. Non-Admin accounts are refused.
   Store the new password privately. No existing password is read or recovered.
8. Sign in afresh through the existing application login after a role/password
   change. A token issued before role assignment will not contain Admin claims.
   Confirm the migration is applied in the intended environment before expecting
   platform-wide reads. No hosted account or migration step above has been run.

References: [createUser](https://supabase.com/docs/reference/javascript/auth-admin-createuser),
[updateUserById](https://supabase.com/docs/reference/javascript/auth-admin-updateuserbyid),
[JWT authorization metadata and freshness](https://supabase.com/docs/guides/database/postgres/row-level-security#authjwt).

## Original Admin functionality inventory

The "before" column describes inspected source plus the schema/RLS established
by the audit. It is not a claim that destructive operations were executed.
Hosted behavior after Phase 1 remains unverified because deployment is forbidden.

| Operation / source | Original UI and database operation | Before / Phase 1 status | Phase 2 authorization and RLS | Security concern / decision |
| --- | --- | --- | --- | --- |
| Admin login (`lib/login.dart`) | Query `admin(email,password)` then compare plaintext in Dart; open dashboard | Blocked intentionally by no-policy RLS; replaced locally with Auth | Keep server-only role assignment and backend RLS; no legacy-table grants | Remove legacy authentication permanently; retain locked table until separately approved cleanup |
| Session restoration (`lib/main.dart`, `lib/session_routing.dart`) | Every valid session went to Home | Admin routing absent; now server verified | Preserve shared Buyer/Seller home | Restore Admin routing; never trust editable metadata |
| Dashboard navigation (`lib/admin_dashboard.dart`) | Four buttons push the management screens | No screen guards before; all five entry points now guarded | Keep route guards plus independent server authorization | Preserve existing screens and navigation |
| Dashboard totals / chart | SELECT IDs from users/sellers/products/orders; count returned rows and chart them | Owner-scoped/incomplete; result length could be capped; local code uses exact counts | Three Admin SELECT policies; no new write policy | Restore counts; add pagination/filtering and reconciliation if larger scale requires it |
| User list (`lib/manage_users.dart`) | SELECT all profiles; display names, email, `phone` | Own profile only; nullable names could crash; wrong phone column; local read-only list corrects these | Admin SELECT on users; project only necessary profile fields | Restore list; protect personal data and avoid broad exports |
| User deletion | DELETE `public.users WHERE id=target` | Other profiles denied; this only deletes a profile, NOT the Auth account; disabled and callback removed | No direct Admin DELETE grant. Future privileged server action must verify current caller role, target, and permitted lifecycle action | Redesign as suspension/controlled account lifecycle. Direct Auth deletion cascades to orders/sellers/products and would destroy data; define retention before any deletion |
| Seller list (`lib/manage_sellers.dart`) | SELECT sellers; show company, registration number, product type | Own registration only; local Admin SELECT restores list | Admin SELECT on sellers | Restore read list. No original approval/edit/delete control exists |
| Seller approval, suspension, editing or deletion | No Admin implementation or approval-state column exists | Not an original working capability; nothing added in Phase 1 | Requires a separately approved model and server action, never unrestricted owner-row edits | Treat as new scope, not silently recreated functionality. Seller deletion cascades to products |
| Product list (`lib/manage_products.dart`) | SELECT product identity/name/price/images/seller | Public reads already worked; legacy Admin entry blocked; list preserved with guard | Existing public SELECT; preserve Seller ownership policies | Restore list; avoid adding unrelated product editing |
| Product deletion | DELETE `public.products WHERE id=target`, then refresh | Other sellers' products denied; disabled and callback removed | Future server action with current Admin role, exact product ID, confirmation, audit, and allowed lifecycle transition; no blanket DELETE policy | Redesign as archival first. Hard deletion cascades to cart entries; storage images do not cascade. JSON order snapshots should remain historical |
| Order list (`lib/manage_orders.dart`) | SELECT id/date/total/status/items/buyer | Own orders only; empty list spun indefinitely; local Admin reads restore list and proper states | Admin SELECT on orders; only fields actually displayed/needed | Restore list; avoid unnecessary address/card exposure |
| Order status dropdown | Packaging / Shipping / Delivering; UPDATE orders SET status WHERE id=target | Other buyers' orders denied; unknown statuses were displayed as Packaging; now disabled and preserves actual stored value | Future server action may update status only; validate permitted transitions and concurrency; verify current Admin role; do not grant arbitrary row UPDATE | Restore with redesign. No change to totals, buyer ID, item snapshots, or addresses may be accepted as part of a status action |
| Admin logout | No original logout button on dashboard | Added locally using Auth sign-out and clearing navigation stack | No privileged key required | Keep; document access-token expiry and revocation limits |
| Admin provisioning / password recovery | Legacy table credentials; no secure Admin provisioning flow | Local operator tool created; hosted operations not executed | Admin API only on trusted operator/server; exact UUID/email; no public role-assignment endpoint | Keep out of Flutter; no general password reset for Buyer/Seller accounts in this tool |
| Sales reports (`lib/report.dart`, `lib/report_page.dart`) | Authenticated-user reports over seller/products/order JSON; reached from customer Profile | Not an Admin dashboard capability; no Phase 1 edits | Do not broaden Seller/order access as a side effect of Admin restoration | Preserve existing behavior. Report order JSON assumptions and seller-order visibility require their own review |

No original Admin create-user UI, create-product UI, seller approval workflow,
role editor, audit log, refund action, or Admin account-settings screen was found.
The legacy baseline document is retained with a notice; this file describes the
current Admin implementation and the proposed restoration path.

## Original Phase 2 proposal (superseded by the approved restoration)

1. Preserve the five screens and agree on allowed actions: order status changes,
   product archival, and user suspension are the recommended first operations.
   Clarify retention, undo behavior, and whether seller approval is new scope.
2. Route mutations through narrowly scoped server actions (e.g. Edge Functions).
   Verify the caller's JWT with Auth, check current server application metadata,
   bind target UUIDs explicitly, and allowlist operation fields. A service key
   stays on the server. Never accept arbitrary table/filter/body forwarding.
   No Admin write RLS policies are needed if approved actions use this controlled
   server boundary; retain all existing client ownership policies.
3. For order status, define the transition graph and status constraint, reject
   stale expected-status/version values, and update only `status` in a transaction.
   Record actor/target/old/new/request ID. Decide how terminal/cancelled states
   affect Buyer/Seller views before changing their shared status vocabulary.
4. For products, propose an archival field and visibility policies that hide
   archived products from new purchases while allowing the owning Seller/Admin
   to inspect them. Review cart and order-snapshot behavior. Do not reuse hard
   deletion or grant storage delete access to clients.
5. For user lifecycle, design suspension and session handling before any account
   deletion. Prevent self-lockout and removal of the last active Admin. Review
   foreign-key cascades and historical orders. A profile-only deletion must not
   be presented as account deletion.
6. Add an append-only server-written audit trail with actor, action, target,
   timestamp, outcome, and request ID; avoid credentials and unnecessary personal
   data. Add Admin confirmation/error flows and enable only approved controls.
7. Define MFA/session freshness requirements for mutations and role revocation.
   Current JWT freshness limitations and publicly executable SECURITY DEFINER
   helper advisories need separate review. Preserve seller helpers' legitimate
   policy use; do not blindly change their grants or security mode.
8. Test no token/Buyer/Seller/spoofed metadata/demoted Admin denial, permitted
   Admin actions, parameter tampering, concurrent updates, idempotency, audit
   completeness, rollback, cascade safety, last-Admin protection, and unchanged
   Buyer/Seller flows. Use isolated fixtures. Deployment and hosted account
   operations require another explicit review after local verification.

## Verification and file manifest

Commands, final results, and the full changed-file manifest are recorded in
`ADMIN_VERIFICATION.md`. RLS and real Admin API integration must remain marked
unverified until run in an approved isolated environment.

# 5. Requirements Traceability (Original Plan → July 2026 Plan → Implementation)

This matrix compares three things for each requirement:

- the **original requirements**: the 2025 README files and the Iteration-1
  prototype, see [Initial Project Plan](02-initial-project-plan.md);
- the **improvement requirements**: the June 2026 recommendations acted on in
  July 2026, see [July 2026 Improvement Plan](04-july-2026-improvement-plan.md);
- the **implementation verified on 2026-11-06** (commit `78efb02`).

**Status** is one of PLANNED, IMPLEMENTED, MODIFIED or UNVERIFIED, as defined in
[Evidence Register §1.1](01-evidence-and-timeline.md#11-status-and-provenance-labels).
It describes the state as of 2026-11-06. "—" means the source does not state
the requirement. File and line references are to `78efb02` unless a commit is
named.

---

## 5.1 Original product requirements (2025)

| ID | Original requirement | Improvement requirement | Actual implementation | Status | Deviations and explanation | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| TR-01 | Display products for sale, with category preview (FR-I-01, FR-I-02) | — | Supabase-backed product grid with search and price chips (All / Under 100 / 100+). Products are publicly readable under RLS | **MODIFIED** | The prototype chips "Top Rated" and "Top Brands" were dropped. Price bands changed from 50 to 100 | `bc245c6:home.dart`; `lib/home.dart`; migration `20260727000000` "products: public read" |
| TR-02 | Implement user authentication (OBJ-03) | IR-02: Admin on Supabase Auth | Buyer/Seller: Supabase Auth email/password since Iteration 2. All roles: Auth-only login since 2026-11-06. Admin authorised only by `app_metadata.role = "admin"` | **IMPLEMENTED** | Mobile-number login is implied by the field label but not implemented (see TR-38) | `1871957`; `lib/login.dart`; `lib/admin_access.dart` |
| TR-03 | Shopping cart (OBJ-04, FR-I-06) | Remove the hard-coded sample cart item (K-14) | Persistent `cart` table since Iteration 3. Coupon `DISCOUNT10`. Shipping RM 25 below RM 1,000 | **IMPLEMENTED** (cart). Sample-item removal **PLANNED** | `lib/cart.dart:19` still seeds "Sample Product" | `0e1e52c`; `lib/cart.dart` |
| TR-04 | Checkout (OBJ-04, FR-I-07) | — | Orders inserted at checkout since Iteration 4, with UUID and JSON `order_items` | **MODIFIED** | The Version 2 README claimed checkout before it was implemented (Iteration 4). Initial status changed from "Processing" (v4) to "Packaging" (legacy). Payment options changed from Touch & Go/DuitNow/COD to Kidz Pay Wallet/Card/COD | `1cac8e6:checkout.dart`; E08 |
| TR-05 | Integrate Supabase for data management (OBJ-05, FR-I-15) | IR-04: enable RLS | 2025: unversioned Supabase project. July 2026: versioned migration with RLS on every table, a new Supabase project, synthetic seed | **MODIFIED** | The original schema and data were not recovered (U-06). The backend was reconstructed from the client code | `4285622`; `supabase/migrations/20260727000000_kidz_initial_schema.sql` |
| TR-06 | Improve UI/UX with interactive features (OBJ-06) | IR-07 states; IR-11 widgets; IR-15 theming | Interactive UI delivered in Iterations 2–4. 2026: loading/empty/retry states on Admin screens; image fallback; profile rework; sign-up keyboard fix | **MODIFIED** | No `ThemeData`, shared widget library or `BottomNavigationBar` was introduced | `lib/admin_access.dart`; `lib/product_image.dart`; `42c5181` |
| TR-07 | Order history and filters (FR-I-08) | IR-06: guard `order_items[0]` | DB-backed history and invoice. Filters: Packaging / Shipping / Delivering / Last 10 Days | **MODIFIED** | The prototype Cancelled/Returns/Refunds filters were replaced. No return or refund feature exists. The unguarded `order_items[0]` remains (TR-31) | `1cac8e6`; `lib/orders.dart` |
| TR-08 | Saved payment cards (FR-I-09) | IR-03: no CVV, tokenise | `bankingcard` table (legacy). Owner-only RLS since July 2026 | **MODIFIED** | The CVV is still collected and stored (`lib/addcard.dart:63`). Restricted to synthetic use by documentation (`SUPABASE.md`), not enforced by RLS. IR-03 remains **PLANNED** | `lib/addcard.dart`; migration `bankingcard` policies |
| TR-09 | Shipping address, profile and account (FR-I-10, FR-I-11) | — | Address and profile in `users`. Password-reset email. Display-name fallback | **IMPLEMENTED** | Self-service account deletion is now disabled (TR-30) | `lib/shipping.dart`; `lib/display_name.dart` |
| TR-10 | Wishlist (FR-I-12) | IR-12: wire up or remove, and persist | `lib/wishlist.dart` still has hard-coded items and cannot be reached | **PLANNED** | Neither completed nor removed | `lib/wishlist.dart` (no reference from any other screen) |
| TR-11 | Notifications (FR-I-13) | IR-12 | `lib/notification.dart` still has hard-coded data and cannot be reached | **PLANNED** | As TR-10 | `lib/notification.dart` |
| TR-12 | Terms and Privacy pages (FR-I-14; "Policy Section", README v3) | — | Present and reachable from Profile. Sign-up has an "I agree to the terms and conditions" checkbox but no link to `TermsPage` | **IMPLEMENTED** | The privacy content was added in Iteration 2, not Iteration 3 as the v3 README says. `TermsPage(isFromSignup:)` supports a sign-up mode that the current sign-up screen does not open | `1871957:privacy.dart`; `lib/profile.dart:187,194`; `lib/signup.dart:222` |
| TR-13 | Product management, stored in Supabase (README v2) | — | Seller add/edit/delete with Storage upload. RLS "seller inserts/updates/deletes own" | **IMPLEMENTED** | Storage update/delete are denied to clients by design, so old images are kept | `1871957`; `lib/seller_dashboard.dart`; migration storage policies |
| TR-14 | Payment gateway integration (README v2–v3); more payment options (README v4) | — | Payment method is a label recorded on the order. No gateway | **PLANNED** | Not implemented in any version | `lib/checkout.dart` |
| TR-15 | Product reviews and ratings (README v2–v4) | — | Read-only `products.rating` shown as stars. Crash fixed by `productStarCount` (`b4494f9`). No review submission | **PLANNED** (reviews). Rating display **IMPLEMENTED** | Customers cannot submit reviews or ratings | `lib/product_rating.dart` |
| TR-16 | Product recommendation system (README v4) | — | None found | **PLANNED** | — | — |

## 5.2 Requirements added after Version 4 (2025 legacy expansion)

These were not in the initial plan. They first appear in the legacy archive (E08).

| ID | Requirement as first implemented | Improvement requirement | Actual implementation (2026-11-06) | Status | Deviations and explanation | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| TR-17 | Guest browsing | — | Guest home and details. Products publicly readable | **IMPLEMENTED** | — | `lib/guest_home.dart`; migration "products: public read" |
| TR-18 | Seller registration and dashboard (orders containing own products, status updates) | — | Registration and product management work under RLS. Order visibility is limited to the caller's own orders | **MODIFIED** | **CONFIRMED BUG** (E26, E27): hosted catalog and an isolated exact-migration reproduction show that the Seller cannot read a Buyer-owned order containing its product; its status UPDATE affects zero rows. Final `main` merge blocked | migration "orders: read own" / "update own"; `ADMIN_PHASES.md` |
| TR-19 | Seller sales reports (daily, monthly, yearly, Top 10) | — | `report.dart` unchanged | **MODIFIED** | **CONFIRMED BUG** (E26, E27): date-range and Top-10 queries receive no other buyers' order rows. Sales are missing or understated; only visible purchases involving the Seller's own products can contribute. Final `main` merge blocked | `lib/report.dart`; `ADMIN_PHASES.md` inventory |
| TR-20 | Admin dashboard (counts and chart) | IR-02 | Guarded by `AdminGate`. Exact HEAD/count queries. Refreshes after management actions | **MODIFIED** | Counts are now exact rather than the length of a capped result page | `lib/admin_dashboard.dart`; E18 |
| TR-21 | Admin: Manage Users (delete profile row) | IR-02 | `admin_delete_record` RPC: preview, typed `DELETE` confirmation, deletion of the **Auth account** with cascades. Orders retained with `user_id` set to NULL. Admin accounts protected | **MODIFIED** | The original operation deleted only `public.users` and left the Auth account. The replacement deletes the account but keeps order history | `lib/manage_users.dart`; `20261106034711_admin_management.sql`; `ADMIN_PHASE2.md` |
| TR-22 | Admin: Manage Sellers (list) | — | Same list, guarded, reads all pages | **IMPLEMENTED** | No Seller-approval workflow existed originally, and none was added | `lib/manage_sellers.dart` |
| TR-23 | Admin: Manage Products (delete) | — | `admin_delete_record` (product): confirmed deletion. Cart rows cascade. Order snapshots and image objects retained | **MODIFIED** | Effects are now disclosed and audited | `lib/manage_products.dart`; `ADMIN_PHASE2.md` |
| TR-24 | Admin: Manage Orders (change status) | — | `admin_set_order_status`: the three original statuses only, with an `updated_at` stale-edit check and audit | **MODIFIED** | Unknown stored statuses are shown as stored instead of being relabelled "Packaging" | `lib/manage_orders.dart`; `ADMIN_PHASE2.md` |

## 5.3 Improvement requirements (June 2026 recommendations)

| ID | Original state | Improvement requirement | Actual implementation | Status | Deviations and explanation | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| TR-25 | Credentials hard-coded in `main.dart` (K-01) | IR-01 | `--dart-define` `SUPABASE_URL` / `SUPABASE_PUBLISHABLE_KEY`. The app refuses to start without them | **IMPLEMENTED** (July 2026) | The 2025 key in public history is a legacy public `anon` key, not a privileged key (E28). Its different legacy project hostname does not resolve; deletion/revocation remain **UNVERIFIED** (U-07) | `4285622`; `lib/supabase_config.dart`; `lib/main.dart` |
| TR-26 | Plaintext Admin table (K-02) | IR-02 | July 2026: table locked (RLS, no policies). November 2026: Auth-only login, `app_metadata.role`, server-verified sessions, operator tool for provisioning | **MODIFIED** (July 2026: locked). **IMPLEMENTED** (November 2026) | The legacy table is kept, locked, rather than dropped | `4285622`; `lib/login.dart`; `tools/admin-account.ps1`; E18 |
| TR-27 | Client-side authorisation only (K-05) | IR-04 | RLS on all tables. Admin reads use live role and session checks (`kidz_private.is_admin()`) | **IMPLEMENTED** | Stricter than recommended: Admin writes go only through RPCs, with no broad write policies | migrations `20260727000000`, `20261106030934`, `20261106034711` |
| TR-28 | CVV and card number in plaintext (K-03) | IR-03 | Unchanged in the client. Table owner-locked | **PLANNED** | Deferred (`SUPABASE.md`) | `lib/addcard.dart:63` |
| TR-29 | Missing assets (K-10) | IR-05 | 15 assets restored and declared. `default.jpg` used as a typed fallback | **MODIFIED** | `placeholder.jpg` was not added. The fallback design changed instead | `4c4b82b`; `077eca7`; `lib/product_image.dart` |
| TR-30 | Account deletion crashes or leaves partial state (K-04, K-06, K-07) | IR-06 | Self-service deletion **disabled** (informational dialog). Edge Function planned but not deployed. Admin-initiated deletion available through RPC (TR-21) | **MODIFIED** | The crash paths were removed by disabling the feature, not by repairing it | `42c5181`; `lib/account.dart:142`; `SUPABASE.md` |
| TR-31 | Unguarded `order_items[0]` (K-08) | IR-06 | Unchanged | **PLANNED** | Still at `lib/orders.dart:126` | `lib/orders.dart` |
| TR-32 | `phone` vs `mobile_number` (K-09) | E10 §12 | Admin list reads `mobile_number` | **IMPLEMENTED** (November 2026) | — | `lib/manage_users.dart:62,91` |
| TR-33 | Missing `mounted` checks and error handling (K-15) | IR-07 | Added in the splash, login and all Admin screens. Not applied across the Buyer and Seller screens | **MODIFIED** (partial) | `mounted` appears in 9 of the 42 `lib/` files | `grep mounted lib/*.dart` |
| TR-34 | No central router | IR-08 | None (`MaterialApp(home:)` with imperative navigation) | **PLANNED** | — | `lib/main.dart` |
| TR-35 | Untyped maps, no service layer | IR-09 | No general models. A scoped service exists for Admin RPCs only | **MODIFIED** (Admin service only); app-wide typed models/service extraction **PLANNED** | — | `lib/admin_management.dart` |
| TR-36 | Duplicate and dead code (K-11, K-12) | IR-10 | `seller.dart`, `add_product.dart`, both no-op extensions and the `home.dart` `main()` remain | **PLANNED** | — | `lib/account.dart:388`; `lib/seller_dashboard.dart:644`; `lib/home.dart:12` |
| TR-37 | Repeated widgets | IR-11 | Original bottom-navigation/product-card/form duplication remains. Shared Admin gate and empty/error UI helpers exist | **MODIFIED** (Admin helpers only); original widget extraction **PLANNED** | No app-wide widget extraction was delivered | `lib/admin_access.dart`; existing Buyer/Seller screens |
| TR-38 | Mobile login and validation (K-20) | IR-14 | No Luhn check or phone login | **PLANNED** | — | — |
| TR-39 | Inconsistent theming (K-18) | IR-15 | No `ThemeData` in `lib/` | **PLANNED** | — | — |
| TR-40 | No session restoration (K-17) | IR-13 | `startupDestinationFor`: Buyer/Seller restored offline. Admin restored only after online `getUser` verification | **IMPLEMENTED** (July 2026). **MODIFIED** for Admin (November 2026) | — | `b4494f9`; `lib/session_routing.dart` |
| TR-41 | Debug `print()` | IR-16 | `print()` remains in 8 `lib/` files | **PLANNED** | — | `grep print( lib/*.dart` |
| TR-42 | No real tests (K-16) | IR-17 | 9 Flutter test files. **137 tests passed** on 2026-11-06 (E24). pgTAP and SQL suites added | **IMPLEMENTED** | The cart-total test given as an example in IR-17 was not added | `test/`; `supabase/tests/`; `tools/admin-db/` |
| TR-43 | Default metadata (K-19) | IR-18 | `pubspec.yaml` description unchanged. README replaced by this documentation change | **MODIFIED** (README only) | `pubspec.yaml:2` still says "A new Flutter project." | `pubspec.yaml`; `README.md` |
| TR-44 | Android release builds lacked INTERNET permission (found in July 2026 testing) | — (not in the June recommendations) | Permission declared in the main manifest | **IMPLEMENTED** | Found during emulator validation, not planned in advance | `b4494f9`; `android/app/src/main/AndroidManifest.xml` |

**Merge gate:** all 44 IDs were checked against their cited code/history. TR-18
and TR-19 are confirmed current defects, not unverified feature claims. A
separately approved minimal Seller fix is required before merging to `main`.

## 5.4 Summary

Some rows carry two labels because one part was delivered and another was not.
Those rows appear under both labels, marked with the part concerned.

| Status | IDs |
| --- | --- |
| IMPLEMENTED | TR-02, TR-03 (cart), TR-09, TR-12, TR-13, TR-15 (rating display), TR-17, TR-22, TR-25, TR-26 (November 2026), TR-27, TR-32, TR-40 (Buyer/Seller), TR-42, TR-44 |
| MODIFIED | TR-01, TR-04, TR-05, TR-06, TR-07, TR-08, TR-18, TR-19, TR-20, TR-21, TR-23, TR-24, TR-26 (July 2026), TR-29, TR-30, TR-33, TR-35 (Admin service), TR-37 (Admin helpers), TR-40 (Admin), TR-43 |
| PLANNED (not implemented as of 2026-11-06) | TR-03 (sample item), TR-08 / TR-28 (CVV), TR-10, TR-11, TR-14, TR-15 (reviews), TR-16, TR-31, TR-34, TR-35, TR-36, TR-37, TR-38, TR-39, TR-41 |
| UNVERIFIED | Original 2025 backend behavior. Client-key revocation in TR-25. All items in [Register §1.5](01-evidence-and-timeline.md#15-register-of-information-that-could-not-be-verified) |

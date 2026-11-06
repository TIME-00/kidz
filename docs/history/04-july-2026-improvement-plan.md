# 4. July 2026 Improvement Plan

> **Provenance: [RECONSTRUCTED].** No document titled "Improvement Plan" was
> found (U-02). The evidenced plan consists of two parts:
>
> 1. **Written recommendations** from two technical assessments. The `kidz_store`
>    assessment (`KIDZ_PROJECT_DOCUMENTATION.md`, self-dated 2026-06-17, E10,
>    §12–14) was committed into the repository as part of the July baseline
>    `5ead0d7` on 2026-07-27. The legacy `kidz` assessment
>    (`Backups/KIDZ_legacy_app_documentation_2026-06-18.md`, E11, §13–15) was
>    preserved on 2026-07-28.
> 2. **The execution record:** six local commits made on 2026-07-27/28
>    (E12–E17), and the `SUPABASE.md` written in those commits.
>
> The recommendations were **written in June 2026** and **acted on in July 2026**.
> This document keeps the two apart. §4.2–4.8 describe what was recommended
> (the plan). §4.9 describes what July 2026 actually carried out. Whether each
> recommendation was met is shown in
> [Requirements Traceability](05-requirements-traceability.md).
>
> Both assessment documents describe themselves as "auto-generated technical
> documentation". No record of who approved the recommendations, or which of
> them were adopted as formal decisions, was found (U-10).

---

## 4.1 Starting point

The baseline is the codebase described in
[Development History §3.7–3.9](03-development-history.md): the March 2025 legacy
application copied into the `kidz_store` project. Its backend was a 2025
Supabase project whose schema was never put under version control (U-06).

## 4.2 Problems identified in the original application

The source assessments list these problems. Detailed entries K-01 to K-20 are in
[Development History §3.9](03-development-history.md#39-known-bugs-and-limitations-of-the-original-application).

| Group | Problems | Source |
| --- | --- | --- |
| Security | Hard-coded Supabase credentials (K-01). Plaintext Admin passwords (K-02). Plaintext card number and CVV (K-03). Service-role API called from the client (K-04). No evidence of RLS (K-05) | E10 §12, E11 §13 |
| Runtime defects | `/login` named-route crash (K-06). Nullable confirmation (K-07). Unguarded `order_items[0]` (K-08). `phone` vs `mobile_number` (K-09) | E10 §12, E11 §13 |
| Build and assets | Missing and undeclared `assets/` (K-10) | E10 §12 |
| Code quality | Duplicate screens and dead code (K-11, K-12). Missing `mounted` checks, inconsistent error handling, `print()` (K-15). Untyped `Map` data. No central router. No tests (K-16) | E10 §12–13, E11 §13 |
| UX and functional gaps | Unreachable Wishlist and Notifications. Favourite and Share not persisted or implemented (K-13). Sample cart item (K-14). No session restoration (K-17). Inconsistent theming (K-18). Weak validation (K-20). No real payment processing | E10 §12, E11 §13 |
| Metadata | Default `pubspec.yaml` description and README (K-19) | E10 §12, E11 §13 |

## 4.3 Improvement objectives [RECONSTRUCTED groupings]

The sources give numbered recommendations, not objectives. The objectives below
group those recommendations without adding to them.

| ID | Objective | Derived from |
| --- | --- | --- |
| IO-1 | Remove secrets and insecure credential handling from the client | E10 #1, E11 #1–3 |
| IO-2 | Enforce data access on the server with Supabase RLS | E10 #11, E11 #4 |
| IO-3 | Restore a working, complete build (assets and fallbacks) | E10 #2, E11 #11 |
| IO-4 | Remove known crash paths and improve runtime robustness | E10 #3, #7, E11 #5–6 |
| IO-5 | Improve maintainability (routing, models and services, de-duplication, logging) | E10 #4–6, #12, E11 #7–10 |
| IO-6 | Complete or remove partial features, and improve validation and UX consistency | E10 #8–10, E11 #12, #14 |
| IO-7 | Add meaningful automated tests and correct project metadata | E11 #13, #15 |

## 4.4 Planned technical changes [ORIGINAL recommendations]

The two recommendation lists are merged below. Wording is condensed but keeps
the original meaning. The reference shows the item number in each source.

| ID | Recommendation | E10 §13 | E11 §14 |
| --- | --- | --- | --- |
| IR-01 | Load the Supabase URL and key from `--dart-define` or config, not source | #1 | #1 |
| IR-02 | Use Supabase Auth for Admin (role column or RLS policy). Never compare plaintext passwords. Hash Admin passwords | #1 | #2 |
| IR-03 | Do not store CVV. Mask or tokenise card numbers | #1 | #3 |
| IR-04 | Enable Row-Level Security so users can only access their own rows | #11 | #4 |
| IR-05 | Create and declare `assets/img` and `assets/anime`, and fix the missing `placeholder.jpg` or use `default.jpg` consistently | #2 | #11 |
| IR-06 | Fix the `/login` route crash, make the confirmation null-safe and guard `order_items[0]` | #3 | #6 |
| IR-07 | Add `mounted` checks, loading and error states, and `try`/`catch` around network calls | #7 | #5, #14 |
| IR-08 | Centralise routing (`routes:`, `onGenerateRoute` or `go_router`) | #4 | #7 |
| IR-09 | Introduce a service/repository layer and typed models (`Product`, `Order`, `CartItem`, `UserProfile`) | #5 | #10 |
| IR-10 | Remove duplicate and dead code (`seller.dart`, `add_product.dart`, no-op extensions, stray `main()`) | #6 | #8 |
| IR-11 | Extract reusable widgets (bottom navigation, product card, text field, gender selector) | — | #9 |
| IR-12 | Wire up or remove Wishlist and Notifications. Persist favourites | #8 | #8, #12 |
| IR-13 | Persist sessions so users are not sent to login on every launch | — | #12 |
| IR-14 | Improve validation: email vs phone, card length/Luhn check, price parsing | #9 | — |
| IR-15 | Standardise theming with one `ThemeData` or colour constants. Consider a real `BottomNavigationBar` | #10 | #14 |
| IR-16 | Replace `print()` with logging | #12 | — |
| IR-17 | Replace the template test with meaningful tests (for example, the cart total) | — | #13 |
| IR-18 | Update the `pubspec.yaml` description and README | — | #15 |

## 4.5 UI/UX improvements (where evidenced)

The recommendations call for UI/UX work in IR-07 (loading, empty and error
states), IR-11 (shared widgets), IR-12 (Wishlist and favourites) and IR-15
(theming and navigation bar). **No mock-ups, design specifications or visual
redesign plans were found (UNVERIFIED).** The only UI changes made in July 2026
were corrective (§4.9).

## 4.6 Database and authentication improvements

| Planned change | Source |
| --- | --- |
| Server-side authorisation with RLS on owner data (`cart`, `orders`, `bankingcard`, profiles) | IR-04 |
| Admin moved onto Supabase Auth with a role. Plaintext `admin` table retired | IR-02 |
| No CVV storage. Card data tokenised | IR-03 |
| Client configuration without committed credentials | IR-01 |
| Session persistence | IR-13 |

## 4.7 Feature improvements

| Planned change | Source |
| --- | --- |
| Wishlist and favourites persisted to the database, or removed | IR-12 |
| Notifications wired into navigation, or removed | IR-12 |
| Login that really handles email vs mobile number, as the field label suggests | IR-14 |

The 2025 README enhancements (payment gateway, more payment options, reviews and
ratings, product recommendations) are **not repeated** in the June 2026
recommendations. They remain earlier plans and are traced separately.

## 4.8 Priorities and expected outcomes

**Stated priority.** The only explicit prioritisation in the sources is E10's
severity marking of weaknesses: 🔴 high or 🟠 medium (see K-01 to K-20). E10 also
singles out the assets fix: "This alone fixes a large number of broken images"
(E10 §13 #2). Neither document gives a phased schedule.

**Expected outcomes [ORIGINAL]:**

> "would move from 'good' to 'excellent' by adding typed models and a service
> layer, declaring assets, hardening security, and cleaning up the
> duplicated/dead code and the handful of crash-prone spots noted above."
> (E10 §14)

> "Resolving these would significantly raise the app's robustness and
> maintainability." (E11 §15)

---

## 4.9 What July 2026 actually executed (observed order)

The commit order below is the **observed** implementation priority. It is not a
written plan.

| Order | Commit | Change | Recommendations addressed |
| --- | --- | --- | --- |
| 1 | `5ead0d7` 2026-07-27 01:43 | Captured the unchanged codebase and the 2026-06-17 assessment as the baseline | — |
| 2 | `4c4b82b` 02:11 | Restored 15 asset files (byte-identical to the legacy archive E08). Declared `assets/img/` and `assets/anime/`. Android adaptive launcher icon and colours | IR-05 |
| 3 | `077eca7` 14:16 | New `lib/product_image.dart`: only `http(s)` URLs go to `Image.network`, with a local `assets/img/default.jpg` fallback, so an asset path is never persisted as a URL. Android label "Kidz". 252-line `test/product_image_test.dart` | IR-05 (MODIFIED approach), IR-17 |
| 4 | `4285622` 17:06 | **Backend reconstruction:** `supabase/migrations/20260727000000_kidz_initial_schema.sql` (tables "derived directly from the Supabase calls in lib/"), RLS on every table, `handle_new_user` profile trigger, `product-images` bucket policies, `seed.sql` (synthetic products), pgTAP RLS contract tests. `lib/supabase_config.dart` and the `MissingConfigApp` screen for `--dart-define` configuration. `SUPABASE.md` | IR-01, IR-04, IR-17. IR-02 partly: the plaintext `admin` table was **locked** (RLS with no policies), not replaced |
| 5 | `b4494f9` 22:28 | Android: INTERNET permission in the main manifest (release builds had none). **Session restoration** (`session_routing.dart`). Splash no longer waits on the DB check, and has a `mounted` guard. `product_rating.dart` fixes a `double`→`int` crash on product cards. Sign-up made scrollable (keyboard overflow) | IR-13, IR-07 (partial) |
| 6 | `42c5181` 2026-07-28 03:30 | Account deletion **disabled**: it now shows an informational dialog and performs no writes (removes K-04, K-06 and K-07 by removal). `display_name.dart` prevents "null null" names. Profile screen rework. Sign-up uses `upsert` because of the new trigger. Edge-Function deletion plan documented in `SUPABASE.md` (not deployed) | IR-06 (partial), K-04 |

### Consequences of the July 2026 changes for the original features

These follow from the July schema and code, and were recorded later in E18 and
E19. **MODIFIED:**

- **Admin login stopped working.** The `admin` table returns no rows to any
  client, so the legacy Admin login could never match. Admin functionality was
  unavailable from July 2026 until the November 2026 restoration (E18
  `ADMIN_PHASES.md`, inventory row "Admin login").
- **Self-service account deletion was disabled** pending a server-side function.
  As of 2026-11-06 it is still disabled (`lib/account.dart`).
- **Seller workflow mismatch: CONFIRMED BUG (E26, E27).** The July migration
  permits Buyer-owned order reads/updates and has no Seller order policy. The
  November migrations add Admin access but preserve these owner policies. With
  the exact migrations loaded into isolated Postgres, a Buyer-owned order
  containing the Seller's product is invisible to that Seller; report queries
  return zero rows and its status update affects zero rows. This contradicts
  the original client workflow. The 2025 backend policies were not preserved,
  so its historical live behavior cannot be established. No fix was made here;
  the final `main` merge is blocked pending separate approval.


### Recommendations deliberately deferred in July 2026

| Item | Evidence of deferral |
| --- | --- |
| CVV and card-number storage (IR-03) | `SUPABASE.md`: "must only ever hold synthetic demo values. Replace with a payment provider token before any real use." The table is owner-locked by RLS |
| Account deletion through an Edge Function | `SUPABASE.md` "Edge Function plan (`delete-account`)": "Not deployed" |
| Admin on Supabase Auth (IR-02) | Comment in `20260727000000_kidz_initial_schema.sql` (`admin` section): "Proper admin access should be modelled with a role claim, not this table." Implemented in November 2026 |

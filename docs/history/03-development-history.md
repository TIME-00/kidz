# 3. Development History (2025 – July 2026 baseline)

This document records how the original application was built, from the GitHub
iterations of March 2025 to the codebase that was assessed in June 2026 and
committed as the July 2026 baseline. Work done after that baseline is covered in
[July 2026 Improvement Plan](04-july-2026-improvement-plan.md) and
[Current State](../current-state-2026-11-06.md).

Evidence IDs refer to the [Evidence Register](01-evidence-and-timeline.md).

Historical **IMPLEMENTED** labels establish that client logic exists in the cited
snapshot. They do not verify the original backend RLS, live deployments or
payment processing; the original Supabase configuration is unavailable (U-06).

---

## 3.1 Overview of the development stages

| Stage | Where the source lives | Dart files | Evidence |
| --- | --- | --- | --- |
| Iteration 1 (Version 1) | GitHub `Iteration-1`, `bc245c6` | 19 | E04 |
| Iteration 2 (Version 2) | GitHub `Iteration-2`, `1871957` | 22 | E05 |
| Iteration 3 (Version 3) | GitHub `Iteration-3`, `0e1e52c` | 23 | E06 |
| Iteration 4 (Version 4) | GitHub `Iteration-4`, source commit `1cac8e6`, merged into `main` as `1fe679e` | 24 | E07 |
| Post-release legacy expansion | `Backups/kidz_legacy_2025-11-21.7z` (`kidz/lib`) | 35 | E08 |
| `kidz_store` baseline | local commit `5ead0d7` | 35 | E09, E12 |

The two June 2026 assessments give different file counts: E10 says "36 Dart
files" and E11 says "34". A direct count of both `lib/` folders gives **35**.

---

## 3.2 Iteration 1: UI prototype (2025-03-10)

**Commit:** `bc245c6` "Upload the initial page" (19 files, 3,483 lines). Merged
in PR #1, tag `Version_1_(Release_on_11-3-2025)`.

**IMPLEMENTED** as a non-functional prototype, consistent with the README
statement (E03):

- Splash screen, login and sign-up screens. There is no authentication logic and
  no Supabase import.
- Home grid of hard-coded sample products with search and filter chips (All,
  Top Rated, Top Brands, Under 50, 50+).
- Product details with size and colour selectors. Cart with coupon field and a
  flat RM 15 shipping fee.
- Checkout offering Touch & Go, DuitNow and Cash on Delivery. Confirmation screen.
- Order history with sample orders and filters (Cancelled, Returns, Refunds,
  Last 10 Days).
- Saved-card list, add and edit screens. Shipping address. Profile. Account.
  Notifications. Wishlist. Terms. `privacy.dart` is present but empty (0 lines).

## 3.3 Iteration 2: Supabase integration and Seller pages (2025-03-11)

**Commit:** `1871957` "Update the source code and add several pages" (20 files,
+2,002/−845). Merged in PR #2, tag `Version_2`.

**IMPLEMENTED:**

- **Supabase Auth:** `auth.signUp`, then insert into `users` (`signup.dart`).
  `signInWithPassword` (`login.dart`).
- **Product catalogue from Supabase:** `home.dart` reads `from('products')`.
- **Seller registration:** `seller.dart` inserts into `sellers`. `profile.dart`
  detects Seller status from that table.
- **Product creation and editing with image upload:** `add_product.dart` and
  `edit_product.dart` upload to Supabase Storage bucket `product-images`, then
  insert into or update `products`.
- **Account:** profile update and password-reset email (`account.dart`).
- **Privacy Policy content** added (`privacy.dart`, +77 lines).

**Discrepancy:** the Version 2 README (E05) lists "Checkout Functionality: Users
can complete their purchases" and says "order data" is stored in Supabase.
Commit `1871957` contains no `orders` or `cart` table access. The only tables
used are `users`, `products` and `sellers`. Order persistence first appears in
Iteration 4.

## 3.4 Iteration 3: Persistent cart and shared state (2025-03-11)

**Commit:** `0e1e52c` "Fix bugs and improve UI" (11 files, +1,027/−627). Merged
in PR #3, tag `Version_3`.

**IMPLEMENTED:**

- **Persistent cart:** add-to-cart insert or quantity merge (`product_details.dart`).
  Quantity update and delete (`cart.dart`) against the `cart` table.
- **Shared user state:** new `user_provider.dart` (`ChangeNotifier`, `provider`
  package).
- **Shipping address** saved to `users` (`shipping.dart`).
- **Profile deletion:** deletes the `users` row (`account.dart`).
- UI changes to account, cart, checkout, login, product details and shipping.

**Discrepancy:** the Version 3 README (E06) gives "Policy Section Added" as a
Version 3 feature. The policy text was added in Iteration 2 (`1871957`), and
`0e1e52c` does not modify `privacy.dart` or `terms.dart`.

## 3.5 Iteration 4: Orders and invoices (2025-03-11)

**Commit:** `1cac8e6` "Fix some bugs" (8 files, +313/−129). Merged in PR #4, tag
`Version_4`. This is the last original commit on GitHub `main`.

**IMPLEMENTED:**

- **Order creation at checkout:** `checkout.dart` inserts into `orders` with
  initial status `"Processing"`. Payment options are now "Kidz Pay Wallet",
  "Card" and "Cash on Delivery".
- **Order history from the database:** `orders.dart` reads `from('orders')`.
  The prototype filters (Cancelled, Returns, Refunds, Last 10 Days) are kept.
- **Order invoice page:** new `order_invoice.dart`.
- **Account deletion:** copies user, seller and product data to `past_users`,
  deletes orders, cart, products, seller and profile rows, then calls
  `supabase.auth.admin.deleteUser`.
- Sign-up and login fixes.

**State of Version 4** [RECONSTRUCTED from E07]: there is no Guest mode, Admin
area, Seller dashboard or sales report. `payment.dart` makes no Supabase calls
(saved cards are UI only).

## 3.6 Post-release legacy expansion (≈ 2025-03-24 to 2025-03-27, not published in 2025)

The legacy `kidz` archive (E08) contains **11 Dart files absent from the original 2025
GitHub snapshot**:

`guest_home.dart`, `guest_product_details.dart`, `seller_reg.dart`,
`seller_dashboard.dart`, `report.dart`, `report_page.dart`, `admin_dashboard.dart`,
`manage_users.dart`, `manage_sellers.dart`, `manage_products.dart`,
`manage_orders.dart`.

The dates are **[INFERRED]** from file modification times (U-05). Compared with
Version 4, this expansion **IMPLEMENTED**:

| Area | Change | Evidence |
| --- | --- | --- |
| Guest mode | "Continue as Guest" → browse-only product grid and read-only details | `guest_home.dart`, `guest_product_details.dart` |
| Seller | Active registration flow (`seller_reg.dart`, with SSM number, company, company type, category, location) → Seller Dashboard: add product with image upload, view and update the status of orders that contain the Seller's products, edit or delete own products | `seller_reg.dart`, `seller_dashboard.dart`, `edit_product.dart` |
| Sales reports | Daily, monthly and yearly sales, plus Top-10 best sellers, for the logged-in Seller | `report.dart`, `report_page.dart` |
| Admin | Dashboard with four counts and an `fl_chart` bar chart. Manage Users (delete profile row), Manage Sellers (list), Manage Products (delete), Manage Orders (change status) | `admin_dashboard.dart`, `manage_*.dart` |
| Admin login | `login.dart` queries an `admin` table and compares the password in plaintext, before falling back to Supabase Auth | `login.dart` |
| Saved cards | Persisted to a `bankingcard` table, including card number and CVV | `addcard.dart`, `editcard.dart`, `payment.dart`, `checkout.dart` |
| Order lifecycle | Initial status changed from "Processing" to **"Packaging"**. Vocabulary Packaging → Shipping → Delivering. Customer filters changed to those statuses | `checkout.dart`, `orders.dart`, `manage_orders.dart` |

## 3.7 `kidz_store` project (≈ 2025-11-21) and July 2026 baseline

[INFERRED from E09] A new Flutter project named `kidz_store` was created, and the
legacy `lib/` was copied into it. The comparison with E08 shows:

- Imports changed from `package:kidz/` to `package:kidz_store/`.
- Four files have non-package-name edits: braces in `orders.dart`, string escapes
  in `report_page.dart`, and `value` → `initialValue` in `seller.dart` and
  `seller_reg.dart`. Imports in `login.dart`/`main.dart` account for package-name changes.
- Dependencies updated: `supabase_flutter` ^2.8.3 → ^2.10.3, `image_picker` and
  `provider` minor versions.
- **The `assets/` folder and its `pubspec.yaml` declarations were not carried
  over.** This is why E10 records broken images, splash and animations.

This codebase was committed unchanged as baseline `5ead0d7` on 2026-07-27 (E12).

---

## 3.8 Original functionality by role (as of the baseline)

The table below shows the functionality as it existed in code before any 2026
change. It is based on E10 and E11 and checked against the baseline source.

### Buyer (customer)

| Function | Implementation |
| --- | --- |
| Register | `signup.dart`: Supabase `auth.signUp`, `users` insert, email-confirmation dialog. Validates email regex, password ≥ 8 characters, accepted terms. |
| Log in | `login.dart`: email and password. Blocks unconfirmed email. The field is labelled "Email ID / Mobile No." but only email works. |
| Browse and search | `home.dart`: product grid, search, price chips (All / Under 100 / 100+). |
| Product details | `product_details.dart`: images, size/colour, rating stars, Add to Cart, Buy Now. |
| Cart | `cart.dart`: select items, change quantity, swipe to delete. Coupon `DISCOUNT10` (RM 10). Shipping RM 25 below RM 1,000. |
| Checkout | `checkout.dart`: address, Kidz Pay Wallet / Card / COD, UUID order id, JSON `order_items`, status "Packaging". **No real payment processing.** |
| Orders | `orders.dart`, `order_invoice.dart`: history with status filters, invoice. |
| Account | Profile edit, shipping address, saved cards, password-reset email, account deletion. |
| Guest | Browse and view products without an account. |

### Seller

| Function | Implementation |
| --- | --- |
| Become a Seller | `seller_reg.dart` inserts into `sellers`. Seller status is derived from the existence of that row. |
| Product management | Add (with Storage upload), edit and delete own products (`seller_dashboard.dart`, `edit_product.dart`). |
| Order handling | Lists orders that contain the Seller's products and updates their status. |
| Sales reports | Date-range sales and Top-10 by quantity (`report.dart`). |

### Admin

| Function | Original implementation | Evidence |
| --- | --- | --- |
| Login | Plaintext comparison against the `admin` table | `login.dart` |
| Dashboard | Counts of users, sellers, products and orders (length of selected IDs) plus bar chart | `admin_dashboard.dart` |
| Users | List. Delete the `users` row only (the Auth account remained) | `manage_users.dart` |
| Sellers | List only (company, SSM, product type) | `manage_sellers.dart` |
| Products | List and delete | `manage_products.dart` |
| Orders | List and change status (Packaging / Shipping / Delivering) | `manage_orders.dart` |

No original Admin create-user, edit-profile, Seller-approval, refund or
role-editor function exists (E19, `ADMIN_PHASE2.md`).

---

## 3.9 Known bugs and limitations of the original application

The historical key has independently been classified as a public `anon` client
key, not a service-role secret (E28). Its publication alone does not establish
privileged credential exposure; the original backend RLS remains unknown.

These were recorded in the June 2026 assessments (E10 §12, E11 §13). They are
listed here as the "before" state for the improvement plan. E10's severity
markers are kept: 🔴 = high, 🟠 = medium.

| # | Issue | Severity (E10) | Source |
| --- | --- | --- | --- |
| K-01 | Supabase URL and legacy public `anon` key hard-coded in `main.dart` (also present in public GitHub `main`) | 🔴 | E10, E11 |
| K-02 | Admin passwords stored and compared in plaintext (`admin` table) | 🔴 | E10, E11 |
| K-03 | Full card number and CVV stored in plaintext (`bankingcard`) | 🔴 | E10, E11 |
| K-04 | Client calls `auth.admin.deleteUser` (service-role API), which fails with the client key after the business data has been deleted | 🟠 | E10 |
| K-05 | Authorisation enforced only on the client. No evidence of Row-Level Security | — | E10 §13.11, E11 |
| K-06 | `Navigator.pushNamedAndRemoveUntil('/login')` with no registered route crashes on account deletion | 🔴 | E10, E11 |
| K-07 | Nullable `bool` from the delete-confirmation dialog | 🔴 | E10 |
| K-08 | `order_items[0]` accessed without a guard in the order search | 🟠 | E10, E11 |
| K-09 | `manage_users.dart` reads `phone`, but sign-up stores `mobile_number` | 🟠 | E10, E11 |
| K-10 | `assets/` missing and undeclared in `kidz_store` (broken splash, images, animations). `placeholder.jpg` referenced but absent | 🟠 | E10, E11 |
| K-11 | Duplicate `SellerRegisterPage` (`seller.dart` and `seller_reg.dart`). `add_product.dart` duplicates the dashboard form | 🟠 | E10, E11 |
| K-12 | Dead code: no-op `extension` blocks. Stray `main()` in `home.dart` | 🟠 | E10, E11 |
| K-13 | Wishlist and Notifications use hard-coded data and cannot be reached. Favourite heart and Share are not persisted or implemented | 🟠 | E10, E11 |
| K-14 | Cart is seeded with a hard-coded "Sample Product" | 🟠 | E10, E11 |
| K-15 | Missing `mounted` checks after `await`. Inconsistent `try`/`catch`. Heavy use of `print()` | 🟠 | E10, E11 |
| K-16 | No real tests (default counter template) | — | E11 |
| K-17 | No session restoration: users are sent to login on every launch | — | E11 §14.12 |
| K-18 | Mixed brand-colour literals. No central `ThemeData` | 🟠 | E10 |
| K-19 | Default project metadata (`pubspec.yaml` description, README) | — | E10, E11 |
| K-20 | Login field implies mobile-number login, which is not implemented. Minimal card and price validation | 🟠 | E10 |

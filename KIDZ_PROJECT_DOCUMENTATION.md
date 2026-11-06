# KIDZ Mobile Application Documentation

> Admin restoration update: the Admin descriptions below preserve the original
> pre-Phase 1 behavior for reference. Secure Auth, read-only Admin access, the
> operator runbook, and the Phase 2 management inventory are documented in
> [ADMIN_PHASES.md](ADMIN_PHASES.md). Local checks are in
> [ADMIN_VERIFICATION.md](ADMIN_VERIFICATION.md). The plaintext login is removed.
> Phase 2 now restores the evidenced management mutations securely; see
> [ADMIN_PHASE2.md](ADMIN_PHASE2.md) for current permissions and deletion behavior.

> Auto-generated technical documentation based on a full read-through of the
> project source code. No source files were modified during this analysis.
>
> Project name (pubspec): `kidz_store` · Marketing name: **Kidz** · Platform: Flutter (Dart)

---

## 1. Project Overview

**Kidz** is a mobile **e-commerce / online shopping application** focused on
children's products (kids' shoes, bags, dresses, and play things). It is built
with **Flutter** and uses **Supabase** as the backend (authentication, database,
and file storage).

The app is a multi-role shopping platform. A visitor can browse products as a
**guest**, register as a **customer**, shop and place orders, and optionally
upgrade to become a **seller** who lists and manages their own products. There is
also an **admin** area for platform-wide management and statistics.

From the code, the core flow is:

1. Splash screen → Login/Register screen.
2. Users log in, register, or continue as a guest.
3. Logged-in customers browse products, add to cart, checkout, pay, and track orders.
4. Customers can register as sellers, add/edit/delete products, manage incoming orders, and view sales reports.
5. Admins manage users, sellers, products, and orders, and see statistics with charts.

The visual theme is consistently **orange/amber** (`Color(0xFFF16601)`,
`Color(0xFFFF7B00)`, `Color(0xFFFFB300)`), with a baby/kids brand identity.

---

## 2. Technology Stack

### Framework & Language
- **Framework:** Flutter (Material Design, `uses-material-design: true`)
- **Language:** Dart (`sdk: ^3.6.1`)
- **Backend-as-a-Service:** Supabase (PostgreSQL DB + Auth + Storage)

### Dependencies (from `pubspec.yaml`)
| Package | Version | Purpose in this app |
|---|---|---|
| `supabase_flutter` | ^2.10.3 | Auth, database queries, storage (image upload) |
| `provider` | ^6.1.5+1 | State management (`UserProvider` / `ChangeNotifier`) |
| `shared_preferences` | ^2.5.2 | Local key/value storage (stores `loggedInUserId`) |
| `image_picker` | ^1.2.1 | Pick product images from gallery (seller) |
| `lottie` | ^3.3.1 | Animations (splash login, order success) |
| `fl_chart` | ^0.70.2 | Bar chart on the Admin dashboard |
| `intl` | ^0.20.2 | Date formatting in reports |
| `uuid` | ^3.0.4 | Generate unique order IDs |
| `cupertino_icons` | ^1.0.8 | iOS-style icons |

### Dev dependencies
- `flutter_test`, `flutter_lints: ^5.0.0`

### Platform Support
The repository contains build folders for **Android, iOS, Web, Windows, macOS,
and Linux** (default Flutter scaffolding). The code is primarily designed for
**mobile**, but the seller image upload explicitly handles **web** via `kIsWeb`
(`Uint8List` vs `File`).

### Backend tables referenced in code
`users`, `admin`, `sellers`, `products`, `cart`, `orders`, `bankingcard`, and a
mentioned `past_users`. Supabase Storage bucket: **`product-images`**.

---

## 3. Folder Structure

Only the relevant, non-generated folders are described (build artifacts and
platform tooling are ignored as requested).

```
kidz_store/
├── pubspec.yaml              # Dependencies & Flutter config
├── pubspec.lock
├── analysis_options.yaml     # Lint rules (flutter_lints)
├── README.md                 # Default Flutter README (not customized)
├── lib/                      # ALL application source code (36 Dart files)
├── android/ ios/ web/        # Platform projects (default scaffolding)
├── windows/ macos/ linux/    # Desktop platform projects
├── test/                     # Test folder (default)
└── build/                    # Generated output (ignored)
```

### `lib/` contents (grouped by responsibility)

**App entry & shared state**
- `main.dart` — App entry point, Supabase init, splash screen.
- `user_provider.dart` — `ChangeNotifier` holding current user data.

**Authentication / onboarding**
- `login.dart` — Login / Register entry, admin login, guest entry.
- `signup.dart` — Customer registration.

**Customer shopping**
- `home.dart` — Logged-in customer home (product grid, search, filter, bottom nav).
- `product_details.dart` — Product detail page (size/color, add-to-cart, buy now).
- `cart.dart` — Shopping cart, quantity, coupon, totals.
- `checkout.dart` — Address, payment method, order placement.
- `confirmpay.dart` — Order success / confirmation page.
- `orders.dart` — Customer order list with status filters.
- `order_invoice.dart` — Read-only invoice for a single order.

**Guest mode**
- `guest_home.dart` — Browse-only product grid for guests.
- `guest_product_details.dart` — Read-only product details for guests.

**Account / profile**
- `profile.dart` — Profile hub / menu navigation.
- `account.dart` — Edit personal info, reset password, delete account.
- `shipping.dart` — Shipping address management.
- `payment.dart` — Saved banking cards list.
- `addcard.dart` / `editcard.dart` — Add / edit / delete a banking card.
- `terms.dart` / `privacy.dart` — Static legal pages.

**Seller**
- `seller_reg.dart` — Seller registration (→ Seller Dashboard). **Used by app.**
- `seller.dart` — Near-identical duplicate seller registration (→ Add Product). **Appears unused.**
- `seller_dashboard.dart` — Seller hub: add products, view/manage orders, list products.
- `add_product.dart` — Standalone add-product page (duplicate of dashboard form).
- `edit_product.dart` — Edit / delete a single product.
- `report.dart` — Sales report logic (data layer functions).
- `report_page.dart` — Sales report UI (daily/monthly/yearly/top 10).

**Admin**
- `admin_dashboard.dart` — Admin home with statistics + bar chart.
- `manage_users.dart` — List / delete users.
- `manage_sellers.dart` — List sellers.
- `manage_products.dart` — List / delete products.
- `manage_orders.dart` — List orders + change status.

**Unconnected / sample-only screens**
- `wishlist.dart` — Wishlist UI built on hardcoded sample data (not wired into navigation or DB).
- `notification.dart` — Promotions list built on hardcoded sample data.

> ⚠️ **Note:** An `assets/` folder is **not present** in the project, and
> `pubspec.yaml` does **not declare any assets**, yet the code references many
> images and animations (e.g. `assets/img/splashscreen.png`,
> `assets/img/babyboy.jpg`, `assets/anime/*.json`, `assets/img/placeholder.jpg`).
> See Section 12.

---

## 4. Application Flow

```
main() → Supabase.initialize() → ChangeNotifierProvider(UserProvider) → MyApp
   │
   ▼
SplashScreen (main.dart)
   │  (tests DB connection, waits 3 seconds)
   ▼
LoginRegisterScreen (login.dart)
   ├── "CONTINUE" (email + password)
   │        ├── matches `admin` table  → AdminDashboard
   │        └── Supabase Auth sign-in  → (email confirmed?) → HomePage
   ├── "New to Kidz? Sign Up"          → SignupScreen → (email verify) → back to login
   └── "Continue as Guest"             → GuestHomePage (browse only)

HomePage (customer)
   ├── tap product            → ProductDetailsPage → Add to Cart / Buy Now
   ├── Cart FAB               → CartPage → Proceed to Checkout
   ├── Orders nav             → OrdersPage → OrderInvoicePage
   └── Profile avatar         → ProfilePage
                                   ├── Account / Shipping / Payment
                                   ├── "Become a Seller" → SellerRegisterPage → SellerDashboard
                                   ├── "Seller Dashboard" (if already a seller)
                                   ├── "Report Generation" (sellers only) → ReportPage
                                   ├── Terms / Privacy
                                   └── Logout → LoginRegisterScreen

CheckoutPage → confirmOrder() inserts into `orders` → ConfirmPaymentPage
   (clears purchased cart items) → Continue Shopping / View Orders
```

**Navigation style:** Imperative `Navigator.push` / `pushReplacement` /
`pushAndRemoveUntil` with `MaterialPageRoute`. There is essentially **no named
route table** (see Section 9).

---

## 5. Main Features

Only features that **actually exist in the code** are listed.

- **Login** — Email/password via Supabase Auth, with a separate admin-table check (`login.dart`).
- **Signup** — Customer registration with email verification flow (`signup.dart`).
- **Guest browsing** — Browse and view products without an account (`guest_home.dart`, `guest_product_details.dart`).
- **Product listing** — Grid of products fetched from Supabase, with search and price filter (`home.dart`).
- **Product details** — Images, thumbnails, size/color selection, rating stars, description (`product_details.dart`).
- **Add to cart / Buy now** — Persisted to a `cart` table; quantity merging for duplicate items (`product_details.dart`).
- **Cart** — Item selection, quantity +/−, swipe-to-delete, coupon code, subtotal/shipping/total (`cart.dart`).
- **Checkout** — Delivery address, payment method (Wallet / Card / COD), order creation (`checkout.dart`).
- **Payment methods** — Saved bank cards: list, add, edit, delete (`payment.dart`, `addcard.dart`, `editcard.dart`).
- **Order confirmation** — Animated success page that clears purchased cart items (`confirmpay.dart`).
- **Order management (customer)** — Order history, status filters, invoice view (`orders.dart`, `order_invoice.dart`).
- **Seller registration** — Company/SSM details, becomes a seller (`seller_reg.dart`).
- **Seller dashboard** — Add product (with image upload), view orders, update order status, manage own products (`seller_dashboard.dart`).
- **Add / edit / delete product** — Full product CRUD for sellers (`add_product.dart`, `edit_product.dart`).
- **Sales reports** — Daily / monthly / yearly sales and Top-10 best sellers for the logged-in seller (`report.dart`, `report_page.dart`).
- **Admin dashboard** — Counts of users/sellers/products/orders + bar chart (`admin_dashboard.dart`).
- **Admin management** — Manage users, sellers, products, orders (`manage_*.dart`).
- **Account settings** — Edit personal info, password reset email, account deletion (`account.dart`).
- **Shipping address** — Country/address/city/postcode stored in `users` (`shipping.dart`).
- **Static pages** — Terms of Service, Privacy Policy (`terms.dart`, `privacy.dart`).

**Present in code but NOT fully integrated:**
- **Wishlist** (`wishlist.dart`) — hardcoded sample data, no navigation entry, no DB.
- **Notifications** (`notification.dart`) — hardcoded promotions, no navigation entry.
- **Favorite / heart toggle** on product cards — visual only (local `setState`), not persisted.
- **Share button** on product details — placeholder, no implementation.

---

## 6. User Roles

| Role | How identified in code | Capabilities |
|---|---|---|
| **Guest** | "Continue as Guest" → `GuestHomePage` (no auth) | Browse products and view details only. Cannot add to cart, checkout, or save anything. |
| **Customer / User** | Supabase Auth user with a row in `users` table | Browse, search, cart, checkout, pay, view orders/invoices, manage profile/address/cards, become a seller. |
| **Seller** | Has a matching row in `sellers` (`user_id = auth uid`) | Everything a customer can do, **plus** add/edit/delete products, view & update statuses of orders containing their products, and generate sales reports. Determined dynamically in `profile.dart` (`isSeller`). |
| **Admin** | Email + password match a row in the `admin` table (checked in `login.dart`) | Access Admin Dashboard: statistics + manage users, sellers, products, orders. |

Notes:
- Roles are **not** stored as a single role field; customer-vs-seller is derived
  by checking the `sellers` table, and admin is a separate table lookup at login.

---

## 7. Screen-by-Screen Explanation

### `main.dart` — App Entry & `SplashScreen`
- **Purpose:** Initialize Supabase, set up `UserProvider`, show a full-screen splash image, then route to login after 3 seconds.
- **UI:** Full-screen `Image.asset("assets/img/splashscreen.png")`.
- **Actions:** `_checkDatabaseConnection()` queries `products` to verify connectivity (logs only), then `Timer` → `LoginRegisterScreen`.
- **Role:** All users.

### `login.dart` — `LoginRegisterScreen`
- **Purpose:** Authenticate users; entry to signup and guest mode.
- **UI:** Lottie animation, white card with email/phone + password fields, "CONTINUE", "Sign Up", "Continue as Guest".
- **Actions:** `_loginUser()` — checks `admin` table first (plaintext compare), otherwise `signInWithPassword`; requires confirmed email; routes to AdminDashboard / HomePage / GuestHomePage.
- **Role:** Guest → Customer/Admin.

### `signup.dart` — `SignupScreen`
- **Purpose:** Register a new customer.
- **UI:** First/last name, gender toggle, mobile, email, password, terms checkbox.
- **Actions:** `_registerUser()` — `auth.signUp`, insert into `users`, store id in `SharedPreferences`, success dialog about email verification. Validates email regex and password length ≥ 8.
- **Role:** Guest → Customer.

### `home.dart` — `HomePage` (+ `ProductCard`)
- **Purpose:** Main customer landing; product catalog.
- **UI:** Greeting (time-based) + user name, search bar, filter chips (All / Under 100 / 100+), 2-column product grid, floating bottom nav (Home / Orders / Cart FAB).
- **Actions:** `fetchUserData()`, `fetchProducts()`, `getFilteredProducts()`; `ProductCard` has an animated favorite heart (local only) and navigates to details.
- **Role:** Customer.

### `product_details.dart` — `ProductDetailsPage`
- **Purpose:** Show one product and allow purchase.
- **UI:** Main image + thumbnails, back/share/favorite, name + star rating, size/color selectors, description, sticky bottom bar with price + Add to Cart + Buy Now.
- **Actions:** `addToCart()` (insert/merge into `cart`), `buyNow()` (jump straight to `CheckoutPage`). Requires size & color selected.
- **Role:** Customer.

### `cart.dart` — `CartPage`
- **Purpose:** Review and edit cart, apply coupon, proceed to checkout.
- **UI:** Dismissible item cards (image, name, size/color, price, select radio, quantity +/−), summary (subtotal/shipping/discount/total), coupon field, "Proceed to Checkout".
- **Actions:** `fetchCartItems()`, `updateCartItemQuantity()`, `deleteCartItem()`, `getSubtotal/ShippingFee/Total()`, `proceedToCheckout()`. Coupon `DISCOUNT10` = RM10; shipping RM25 if subtotal < RM1000.
- **Role:** Customer.

### `checkout.dart` — `CheckoutPage`
- **Purpose:** Confirm address, choose payment, place order.
- **UI:** Delivery address tile, payment method radios (Kidz Pay Wallet / Card / Cash on Delivery), item list, totals, "Continue".
- **Actions:** `fetchUserAddress()`, `fetchUserCards()`, `selectCard()` (bottom sheet), `confirmOrder()` — generates UUID order id, serializes items to JSON, inserts into `orders` with status `Packaging`, → `ConfirmPaymentPage`.
- **Role:** Customer.

### `confirmpay.dart` — `ConfirmPaymentPage`
- **Purpose:** Post-order success screen.
- **UI:** Lottie animation, "Congratulations", Continue Shopping / View all Orders.
- **Actions:** `clearPurchasedItems()` deletes the purchased cart rows by id.
- **Role:** Customer.

### `orders.dart` — `OrdersPage`
- **Purpose:** Customer's order history.
- **UI:** Greeting header, search, status filter chips (All / Packaging / Shipping / Delivering / Last 10 Days), order cards, same floating bottom nav as home.
- **Actions:** `fetchOrders()` (decodes JSON `order_items`), `getFilteredOrders()`; tap → `OrderInvoicePage`.
- **Role:** Customer.

### `order_invoice.dart` — `OrderInvoicePage`
- **Purpose:** Read-only invoice for one order.
- **UI:** Order id/date, list of items (image, name, size/color, price, qty), total price, payment method.
- **Role:** Customer.

### `guest_home.dart` — `GuestHomePage`
- **Purpose:** Browse-only catalog for non-authenticated users.
- **UI:** "Guest" header (tapping avatar returns to login), search bar, product grid.
- **Actions:** `fetchProducts()`, search filter; tap → `GuestProductDetailsPage`.
- **Role:** Guest.

### `guest_product_details.dart` — `GuestProductDetailsPage`
- **Purpose:** Read-only product details for guests (no cart/buy).
- **UI:** Image, name, price, description.
- **Role:** Guest.

### `profile.dart` — `ProfilePage`
- **Purpose:** Account/menu hub.
- **UI:** Avatar + full name, menu items (Account, Shipping Address, Payment Method, Become a Seller/Seller Dashboard, Report Generation [sellers only], Terms, Privacy), Logout.
- **Actions:** `fetchUserProfile()` (detects seller), `handleSellerNavigation()`, sign out.
- **Role:** Customer / Seller.

### `account.dart` — `AccountSettingsPage`
- **Purpose:** View/edit personal info; reset password; delete account.
- **UI:** Avatar, editable first/last name, read-only email, phone, gender toggle, "Save Changes" (enabled only when changed).
- **Actions:** `fetchUserData()`, `updateUser()` (via `UserProvider`), `resetPassword()`, `deleteAccount()` (cascade deletes orders/cart/cards/products/seller/user then signs out).
- **Role:** Customer / Seller.

### `shipping.dart` — `ShippingAddressPage`
- **Purpose:** Manage delivery address.
- **UI:** Country bottom-sheet picker (Malaysia/Singapore/Indonesia), address/city/postcode fields, "Save Changes" (enabled when changed).
- **Actions:** `fetchShippingAddress()`, `saveAddress()` updates `users`.
- **Role:** Customer.

### `payment.dart` — `PaymentMethodsPage`
- **Purpose:** Manage saved cards.
- **UI:** Dropdown of masked card numbers, card image preview, settings (edit) button, FAB to add card.
- **Actions:** `_fetchCards()`; opens `AddCardPage` / `EditCardPage` bottom sheets.
- **Role:** Customer.

### `addcard.dart` — `AddCardPage`
- **Purpose:** Add a banking card.
- **UI:** Bottom sheet with card holder, number, valid (MM/YY auto-format), CVV.
- **Actions:** `_saveCard()` validates and inserts into `bankingcard`. (CVV stored — see Section 12.)
- **Role:** Customer.

### `editcard.dart` — `EditCardPage`
- **Purpose:** Edit or delete an existing card.
- **UI:** Bottom sheet with prefilled fields, delete icon, Save.
- **Actions:** `_loadCardDetails()`, `_updateCard()`, `_deleteCard()`.
- **Role:** Customer.

### `seller_reg.dart` — `SellerRegisterPage` (active)
- **Purpose:** Register the current user as a seller.
- **UI:** SSM number, company name, company type dropdown, product category dropdown, location, "Register & Add Product".
- **Actions:** `registerSeller()` checks for existing seller, inserts into `sellers`, → `SellerDashboard`.
- **Role:** Customer → Seller.

### `seller.dart` — `SellerRegisterPage` (duplicate, appears unused)
- **Purpose:** Near-identical to `seller_reg.dart` but navigates to `SellerAddProductPage` instead of the dashboard. Same class name. Not imported by `profile.dart`.
- **Role:** Seller (legacy/duplicate).

### `seller_dashboard.dart` — `SellerDashboard`
- **Purpose:** Seller control center.
- **UI:** "Add Product" toggle (image picker, name, sizes, colors, price with "RM " prefix, description, submit), "Orders Section" toggle (orders for this seller's products with status dropdown), grid of the seller's own products.
- **Actions:** `fetchSellerProducts()`, `pickImage()`, `uploadImages()` (Supabase Storage), `submitProduct()`, `fetchOrders()` (filters orders containing this seller's products), `updateOrderStatus()`. Tap product → `EditProductPage`.
- **Role:** Seller.
- **Note:** Contains a dead, no-op `extension on PostgrestTransformBuilder { void or(String s) {} }` at the bottom.

### `add_product.dart` — `SellerAddProductPage`
- **Purpose:** Standalone add-product screen (largely duplicates the dashboard's form + product grid).
- **Role:** Seller.

### `edit_product.dart` — `EditProductPage`
- **Purpose:** Edit or delete a product.
- **UI:** Name, price, description, size/color chips, Update button, delete icon in app bar.
- **Actions:** `updateProduct()`, `confirmDeleteProduct()` → `deleteProduct()`.
- **Role:** Seller.

### `report_page.dart` — `ReportPage`
- **Purpose:** Seller sales reporting UI.
- **UI:** Report-type dropdown (Daily / Monthly / Yearly / Top 10), date or month picker, "Generate Report", results list.
- **Actions:** `_loadReport()`, `_fetchTop10()`, `_pickDate()`, `_pickMonthCustom()` — delegates to functions in `report.dart`.
- **Role:** Seller.

### `report.dart` — report logic (no widgets)
- **Purpose:** Data layer for reports.
- **Functions:** `generateAllInvolvingMeReport()` (aggregates sales of the seller's products within a date range), `fetchTop10BestSellers()` (ranks products by quantity sold), `_emptySalesReport()`.
- **Role:** Seller (backing logic).

### `admin_dashboard.dart` — `AdminDashboard`
- **Purpose:** Admin overview.
- **UI:** 2×2 management buttons, stat cards (Users/Sellers/Products/Orders), `fl_chart` bar chart.
- **Actions:** `fetchStatistics()` counts rows in each table.
- **Role:** Admin.

### `manage_users.dart` — `ManageUsersScreen`
- **Purpose:** List and delete users.
- **UI:** List of user cards with name/email/phone and a delete button.
- **Actions:** `fetchUsers()`, `deleteUser()`.
- **Role:** Admin.
- **Note:** Reads `user["phone"]` but signup stores `mobile_number` (mismatch → null).

### `manage_sellers.dart` — `ManageSellers`
- **Purpose:** List sellers (company name, SSM, product type). Read-only.
- **Role:** Admin.

### `manage_products.dart` — `ManageProducts`
- **Purpose:** List and delete products.
- **Actions:** `fetchProducts()`, `_deleteProduct()`.
- **Role:** Admin.

### `manage_orders.dart` — `ManageOrders`
- **Purpose:** List orders and change their status.
- **UI:** Order cards with date, total, status dropdown (Packaging/Shipping/Delivering).
- **Actions:** `fetchOrders()`, `_updateOrderStatus()`.
- **Role:** Admin.

### `terms.dart` — `TermsPage`
- **Purpose:** Terms of Service. Has a `isFromSignup` mode (interactive checkbox + agree button) vs read-only mode.
- **Role:** All.

### `privacy.dart` — `PrivacyPolicyPage`
- **Purpose:** Static privacy policy text.
- **Role:** All.

### `wishlist.dart` — `WishlistPage` (not wired in)
- **Purpose:** Wishlist grid using **hardcoded** items (`p1.jpg`…`p4.jpg`).
- **Note:** No navigation route reaches this screen; favorites are local only.

### `notification.dart` — `NotificationPage` (not wired in)
- **Purpose:** Promotions list using **hardcoded** data.
- **Note:** No navigation route reaches this screen.

### `user_provider.dart` — `UserProvider`
- **Purpose:** Shared user state via `ChangeNotifier`.
- **Functions:** `fetchUserData()`, `updateUserData()`.

---

## 8. Data Handling

**Backend (Supabase):** Primary data store. Direct table queries via
`supabase.from('table').select()/.insert()/.update()/.delete()`. Auth via
`supabase.auth`. Image files uploaded to Storage bucket `product-images`.

**Tables used:**
- `users` — profile (first/last name, gender, mobile_number, email, country, address, city, postcode).
- `admin` — admin credentials (email, password in plaintext).
- `sellers` — seller profile (user_id, ssm_number, company_name, company_type, product_type, location).
- `products` — product_name, product_price, product_images (array), product_sizes, product_colors, product_description, seller_id, rating, created_at.
- `cart` — user_id, product_id, size, color, quantity.
- `orders` — id (UUID), user_id, order_date, total_price, payment_method, delivery_address, status, `order_items` (JSON-encoded string), order_name.
- `bankingcard` — user_id, cardholdername, cardnumber, valid, cvv.

**Local state:**
- `provider` / `UserProvider` for the current user.
- `setState` lists for products, cart, orders, etc.
- `SharedPreferences` stores `loggedInUserId` at signup (not heavily used afterward).

**Forms:** `Form` + `GlobalKey<FormState>` with `TextFormField` validators in
login, signup, seller registration, product add/edit. `TextEditingController`s
throughout.

**JSON handling:** `order_items` is stored as a JSON string (`jsonEncode` on
write, `jsonDecode` on read) and defensively normalized in several places.

**Hardcoded / sample data found:**
- `cart.dart` initializes a hardcoded "Sample Product" item before fetching.
- `wishlist.dart` — entirely hardcoded products.
- `notification.dart` — entirely hardcoded promotions.
- Coupon code `DISCOUNT10` and shipping thresholds are hardcoded.
- Supabase URL and anon key are hardcoded in `main.dart`.
- Placeholder image URL `https://via.placeholder.com/150` used as a fallback in many places.

---

## 9. Navigation / Routing

- Navigation is **imperative**: `Navigator.push`, `Navigator.pushReplacement`,
  and `Navigator.pushAndRemoveUntil` with `MaterialPageRoute`. Data is passed via
  **constructor parameters** (e.g. `CheckoutPage(cartItems: ..., total: ...)`,
  `OrderInvoicePage(order: ...)`, `EditProductPage(productData: ...)`).
- `MaterialApp` defines only `home: SplashScreen()` — there is **no `routes:`
  table** and no `onGenerateRoute`.
- ⚠️ **Inconsistency:** `account.dart`'s `deleteAccount()` calls
  `Navigator.pushNamedAndRemoveUntil(context, '/login', ...)`, but `'/login'` is
  **not registered** anywhere. This named route will fail at runtime.
- Bottom navigation on `home.dart` and `orders.dart` is a custom floating bar
  using `pushReplacement` between Home / Orders and a Cart FAB.
- Several screens use `Icons.keyboard_arrow_up` as the "back" leading icon
  (a stylistic choice consistent across the app).

---

## 10. Important Business Logic

**Login validation (`login.dart`):**
1. Look up the email in the `admin` table and compare the password (plaintext). If matched → AdminDashboard.
2. Otherwise `signInWithPassword`. If `user.emailConfirmedAt == null`, block login and ask to verify email; else → HomePage.

**Signup validation (`signup.dart`):** Required fields, email regex, password
length ≥ 8, terms checkbox must be ticked; duplicate-email handled via
`AuthException`.

**Product management:**
- Sellers add products with images uploaded to Supabase Storage; URLs saved in `product_images`.
- Price field is forced to carry a `"RM "` prefix and parsed by stripping `"RM"`.
- Edit/delete update or remove the `products` row.

**Cart calculation (`cart.dart`):**
- Subtotal = Σ(price × quantity) of **selected** items only.
- Shipping = RM25 if subtotal < RM1000, else RM0.
- Total = subtotal + shipping − discount.
- Coupon: `DISCOUNT10` → RM10 discount, else invalid.

**Checkout / payment flow (`checkout.dart` → `confirmpay.dart`):**
- Address fetched from `users`; payment defaults to "Kidz Pay Wallet" (Card requires selecting a saved card; COD available).
- `confirmOrder()` builds the order with a UUID, JSON-encodes items, sets status `Packaging`, inserts into `orders`.
- On success, navigates to the confirmation page which **deletes the purchased cart rows**.
- Note: payment is **not actually processed** — selecting a method and placing the order is the extent of the flow (no real gateway).

**Order status lifecycle:** `Packaging → Shipping → Delivering`. Updatable by
the seller (their products) and by admin (`manage_orders.dart`). Customers filter
by these statuses.

**Seller/admin management:**
- Seller status derived by presence of a `sellers` row for the auth uid.
- Sellers only see orders that contain at least one of their own products (filtered in `seller_dashboard.dart`/`fetchOrders`).
- Admin sees aggregate counts and can delete users/products and change order statuses.

**Report generation (`report.dart`):**
- `generateAllInvolvingMeReport()` filters `orders` by date range, decodes items,
  matches products owned by the current seller, and aggregates quantity & total
  per product plus an overall total.
- `fetchTop10BestSellers()` ranks the seller's products by total quantity sold and
  returns the top 10.

**Account deletion (`account.dart`):** Cascades deletes across
orders/cart/bankingcard/(products+seller if applicable)/users, signs out, then
attempts `supabase.auth.admin.deleteUser()`.

---

## 11. Strengths of the Current Application

- **Complete end-to-end e-commerce flow** implemented: browse → details → cart → checkout → order → invoice.
- **Multi-role support** (guest, customer, seller, admin) with sensible role detection.
- **Real backend integration** with Supabase Auth, database, and Storage (including real image upload that handles both mobile and web via `kIsWeb`).
- **Good UI consistency** — coherent orange theme, reusable widget helpers (`_buildTextField`, `_buildMenuItem`, `categoryChip`, etc.), card-based layouts.
- **Defensive data parsing** for `order_items` (handles String/List/null), null-coalescing defaults, and image `errorBuilder` fallbacks.
- **Form validation** present on the critical auth and registration forms.
- **Nice touches:** time-based greetings, Lottie animations, animated favorite heart, swipe-to-delete cart items, change-detection that enables/disables Save buttons, MM/YY card formatter, custom month/year report picker.
- **Reasonable seller analytics** (date-ranged sales report + top-10 best sellers) and an admin chart via `fl_chart`.

---

## 12. Weaknesses / Missing Parts / Possible Bugs

**Security**
- 🔴 **Hardcoded Supabase URL and anon key** in `main.dart` (committed to source).
- 🔴 **Admin passwords stored & compared in plaintext** in the `admin` table (`login.dart`).
- 🔴 **Full card numbers and CVV stored in plaintext** in `bankingcard` (`addcard.dart`). Storing CVV is against PCI guidelines.
- 🟠 `supabase.auth.admin.deleteUser()` is an **admin/service-role API called from the client** — it will not work with the anon key and exposes a design flaw. `account.dart` also defines an empty `extension on User { delete() {} }` (dead/placeholder code).

**Likely runtime bugs**
- 🔴 `Navigator.pushNamedAndRemoveUntil(context, '/login', ...)` in `account.dart` — `'/login'` route is **not registered** → crash on account deletion.
- 🔴 `deleteAccount()`: `bool confirmDelete = await showDialog(...)` can return **null** if dismissed; `if (!confirmDelete)` then throws on a null bool.
- 🟠 `orders.dart` build filters with `order["order_items"][0]["product_name"]` — will throw if any order has an **empty** `order_items` list.
- 🟠 `manage_users.dart` reads `user["phone"]`, but signup writes `mobile_number` → shows `null`.
- 🟠 Missing assets: there is **no `assets/` folder** and **no `assets:` section in `pubspec.yaml`**, yet code references `assets/img/*.jpg`, `assets/anime/*.json`, `placeholder.jpg`, `debitcard.jpg`. Splash image, avatars, Lottie animations, wishlist/notification images, and placeholders will fail to load.

**Duplication / dead code**
- 🟠 Two files declare the **same class `SellerRegisterPage`** (`seller.dart` and `seller_reg.dart`) with slightly different navigation; `seller.dart` appears unused.
- 🟠 `add_product.dart` (`SellerAddProductPage`) heavily **duplicates** the add-product form and product grid already in `seller_dashboard.dart`.
- 🟠 No-op `extension on PostgrestTransformBuilder { void or(String s){} }` in `seller_dashboard.dart` and empty `extension on User` in `account.dart`.
- 🟠 `home.dart` also declares its own `main()`/`MyApp` (leftover scaffolding) even though the real entry is `main.dart`.

**Incomplete / not integrated**
- 🟠 **Wishlist** and **Notifications** screens are sample-only and unreachable from the UI.
- 🟠 Favorite heart and **Share** button do nothing persistent.
- 🟠 **No real payment processing** — checkout just records the order.
- 🟠 Cart starts with a hardcoded "Sample Product".

**Validation / robustness**
- 🟠 Login field labeled "Email ID / Mobile No." but only **email** actually works with Supabase Auth; mobile-number login is not implemented.
- 🟠 Minimal validation on card fields (e.g. card length / Luhn check) and on product price beyond the `RM` strip.
- 🟠 Many async DB calls call `setState`/`ScaffoldMessenger` **after `await`** without `mounted` checks (potential "use after dispose" warnings).
- 🟠 Error handling is inconsistent — several fetches have **no try/catch** (e.g. `fetchProducts`, `fetchCartItems`), failing silently.
- 🟠 Heavy use of `print()` for debugging instead of proper logging.
- 🟠 `withOpacity` (deprecated in recent Flutter) is used in a few places.

**UI consistency**
- 🟠 Mixed color definitions for the same brand orange (`0xFFF16601`, `0xFFFF7B00`, `Color.fromARGB(255,255,123,0)`, `fromRGBO(245,124,0,1)`).
- 🟠 The custom floating bottom nav uses `pushReplacement`, which rebuilds pages and can feel janky and lose state.

---

## 13. Improvement Recommendations

Practical, assignment-appropriate improvements:

1. **Move secrets out of source.** Load the Supabase URL/key from
   `--dart-define` or a config file, and don't store admin passwords or CVV in
   the database. Hash admin passwords; never store CVV.
2. **Declare and add assets.** Create the `assets/img` and `assets/anime`
   folders, add the referenced files, and register them under `flutter: assets:`
   in `pubspec.yaml`. This alone fixes a large number of broken images.
3. **Fix the known crashes:** register a `/login` named route (or use a direct
   `MaterialPageRoute`), and make `confirmDelete` null-safe
   (`final confirm = await showDialog<bool>(...) ?? false;`). Guard
   `order_items[0]` with an `isNotEmpty` check.
4. **Add a centralized router** (`routes:`/`onGenerateRoute` or `go_router`) to
   replace scattered `MaterialPageRoute` calls and make navigation consistent.
5. **Introduce a service/repository layer and model classes.** Replace
   `Map<String,dynamic>` everywhere with typed models (`Product`, `Order`,
   `CartItem`, `UserProfile`) and centralize Supabase calls. This removes
   field-name mismatches like `phone` vs `mobile_number`.
6. **Remove duplication.** Delete the unused `seller.dart`, merge
   `add_product.dart` into `seller_dashboard.dart`, and remove the dead
   `extension` hacks and the stray `main()` in `home.dart`.
7. **Add proper loading & error states** (try/catch + user-visible error
   messages + `mounted` checks) around every network call.
8. **Wire up or remove** Wishlist and Notifications; persist favorites to the
   database if kept.
9. **Improve validation:** real email-vs-phone handling, card number length/Luhn,
   stronger price parsing, and consistent form validators across all forms.
10. **Standardize theming** with a single `ThemeData`/color constants instead of
    repeated literal colors, and consider a real `BottomNavigationBar`.
11. **Use Supabase Row-Level Security (RLS)** so a user can only read/modify their
    own cart/orders/cards — currently many queries rely on client-side filtering.
12. **Replace `print()`** with a logging utility and remove debug logs before
    submission.

---

## 14. Summary

**Kidz (`kidz_store`)** is a fairly complete Flutter + Supabase e-commerce app for
children's products. It implements a real multi-role experience — guests browse,
customers shop and order, sellers list and manage products and view sales
analytics, and admins oversee the platform — backed by Supabase Auth, a
PostgreSQL database, and Storage for product images. The full purchase journey
(catalog → details → cart → checkout → order → invoice) works against the live
backend, and the UI is consistent and feature-rich (search, filters, charts,
Lottie animations, reports).

The project's main weaknesses are around **security** (hardcoded keys, plaintext
admin passwords and CVV), **a missing/undeclared `assets` folder** that breaks
image loading, **a few concrete runtime bugs** (unregistered `/login` route,
nullable delete-confirmation, unguarded `order_items[0]`), and **code hygiene**
issues (duplicate seller screens, dead `extension` code, hardcoded sample data in
Cart/Wishlist/Notifications, inconsistent error handling and theming). Payment is
recorded but not actually processed.

As a student mobile-application assignment it demonstrates strong breadth —
authentication, CRUD, file upload, role-based access, reporting, and charts — and
would move from "good" to "excellent" by adding typed models and a service layer,
declaring assets, hardening security, and cleaning up the duplicated/dead code and
the handful of crash-prone spots noted above.

---

*Document generated on 2026-06-17. Based on a complete read of all 36 Dart files in `lib/`, `pubspec.yaml`, and `README.md`. No source code was modified.*

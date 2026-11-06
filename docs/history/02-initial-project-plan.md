# 2. Initial Project Plan (March 2025)

> **Provenance: [RECONSTRUCTED].** No standalone Initial Project Plan document
> was found (see [Evidence Register](01-evidence-and-timeline.md), U-01). The
> earliest written statement of intent is the Iteration-1 README, committed on
> 2025-03-10 (E03). It is reproduced below as **[ORIGINAL]**. Everything else in
> this document is reconstructed from the Iteration-1 source code (E04) and the
> README revisions (E05–E07), and each statement cites its evidence. Nothing has
> been added that these sources do not support.

---

## 2.1 Original statement of intent [ORIGINAL]

Below is the README text at commit `4a6fb60` (Iteration-1 branch, 2025-03-10 17:36 +08:00), reproduced verbatim:

> **Kidz Toy Store**
> **Overview**
> Kidz Toy Store is a mobile application designed for selling kids' toys. This
> first version focuses on showcasing the products that will be available for
> sale in the application. Currently, the app features a non-functional user
> interface, providing a preview of the toy collection without any interactive
> features.
>
> **Features**
> - Display of various kids' toys available for purchase
> - Simple and user-friendly interface
> - Preview of product categories
>
> **Tech Stack**
> Framework: Flutter
> Backend: Not implemented yet
> Database: Supabase (planned for future versions)
> Development Tools: Android Studio, Visual Studio Code
>
> **Future Enhancements**
> - Implement user authentication
> - Add shopping cart and checkout functionality
> - Integrate with Supabase for data management
> - Improve UI/UX with interactive features

---

## 2.2 Project background

- **Product:** "Kidz Toy Store", later branded **Kidz**: a mobile shopping
  application for children's products (E03).
- **Delivery model:** four numbered iterations, each with its own branch
  (`Iteration-1` to `Iteration-4`), merged through pull requests #1–#4 and
  tagged `Version_1` to `Version_4` (E04–E07).
- **Market indicators [RECONSTRUCTED]:** prices are shown in **RM** (Malaysian
  Ringgit). The Iteration-1 checkout offers **Touch & Go**, **DuitNow** and
  **Cash on Delivery** (`checkout.dart` at `bc245c6`). The README does not name a
  target market.
- **Scope note:** the README says "kids' toys". The Iteration-1 sample catalogue
  already contains footwear ("Babyoye kids shoes", "Kids shoes camoflagde" in
  `home.dart` at `bc245c6`). Later Seller categories are "Kidz Shoes", "Kidz
  Bags", "Kidz Dresses" and "Kidz Play Things" (E08). The range therefore grew
  from toys to children's products in general.

## 2.3 Problem statement

**UNVERIFIED (U-03).** No original problem statement, business case or academic
brief was found. The only evidenced purpose is the one in §2.1: a mobile
application "designed for selling kids' toys". No problem statement has been
written here, because one would have to be invented.

## 2.4 Objectives and scope

| ID | Objective | Provenance | Evidence |
| --- | --- | --- | --- |
| OBJ-01 | Showcase the products to be sold, with a preview of product categories (Version 1). | [ORIGINAL] | E03 "Features" |
| OBJ-02 | Provide a simple and user-friendly interface. | [ORIGINAL] | E03 "Features" |
| OBJ-03 | Implement user authentication in a later version. | [ORIGINAL] | E03 "Future Enhancements" |
| OBJ-04 | Add shopping cart and checkout functionality. | [ORIGINAL] | E03 "Future Enhancements" |
| OBJ-05 | Integrate Supabase for data management. | [ORIGINAL] | E03 "Tech Stack", "Future Enhancements" |
| OBJ-06 | Improve UI/UX with interactive features. | [ORIGINAL] | E03 "Future Enhancements" |

**Scope of Version 1** [ORIGINAL]: a non-functional UI preview with no backend
(E03). **Out of scope for Version 1** [ORIGINAL]: backend, authentication,
cart/checkout behaviour and persistence (all listed as future enhancements).

## 2.5 Target users

| User group | Provenance | Evidence |
| --- | --- | --- |
| Shoppers buying children's products | [ORIGINAL] implied by "selling kids' toys … available for purchase" | E03 |
| Registered customers (sign-up and login screens) | [RECONSTRUCTED] | `signup.dart` and `login.dart` at `bc245c6` |
| Sellers | **Not evidenced in the initial snapshot.** First appears in Iteration 2 (`seller.dart`, `add_product.dart`). | E05 |
| Guests (browse without an account) | **Not evidenced in the initial snapshot.** First appears after Version 4 (`guest_home.dart`). | E08 |
| Administrators | **Not evidenced in the initial snapshot.** First appears after Version 4 (`admin_dashboard.dart`, `manage_*.dart`). | E08 |

## 2.6 Initial functional requirements

These requirements are **[RECONSTRUCTED]** from the Version 1 README and from the
screens that were in the Iteration-1 prototype. A screen in the prototype shows
that the feature was intended. It does not show that the feature worked: the
Version 1 UI used hard-coded data and had no backend (E03, E04).

| ID | Requirement | Basis | Evidence |
| --- | --- | --- | --- |
| FR-I-01 | Display a catalogue of children's products with images, names and RM prices. | README feature + prototype | E03; `home.dart` (hard-coded product list) |
| FR-I-02 | Preview product categories and filter the catalogue (prototype chips: All, Top Rated, Top Brands, Under 50, 50+), with search. | README feature + prototype | E03; `home.dart` |
| FR-I-03 | Show product details with size and colour selection. | Prototype | `product_details.dart` |
| FR-I-04 | Register a customer (first and last name, gender, mobile number, email, password). | Prototype + README future enhancement | `signup.dart` |
| FR-I-05 | Log in. | Prototype + README future enhancement | `login.dart` |
| FR-I-06 | Shopping cart with coupon/promo code entry and shipping fee (prototype flat RM 15). | Prototype + README future enhancement | `cart.dart` |
| FR-I-07 | Checkout with delivery address and payment-method choice (Touch & Go, DuitNow, Cash on Delivery), followed by a confirmation screen. | Prototype + README future enhancement | `checkout.dart`, `confirmpay.dart` |
| FR-I-08 | Order history with filters (Cancelled, Returns, Refunds, Last 10 Days). | Prototype | `orders.dart` (sample orders) |
| FR-I-09 | Saved payment cards: list, add, edit. | Prototype | `payment.dart`, `addcard.dart`, `editcard.dart` |
| FR-I-10 | Shipping address management. | Prototype | `shipping.dart` |
| FR-I-11 | Profile and account settings, with logout. | Prototype | `profile.dart`, `account.dart` |
| FR-I-12 | Wishlist. | Prototype | `wishlist.dart` |
| FR-I-13 | Notifications/promotions. | Prototype | `notification.dart` |
| FR-I-14 | Terms of Service and Privacy Policy pages. | Prototype (`privacy.dart` was an empty file in Iteration 1) | `terms.dart`, `privacy.dart` |
| FR-I-15 | Persist application data in Supabase. | README future enhancement | E03 |

## 2.7 Later planned enhancements recorded in the README [ORIGINAL]

Each iteration rewrote the README's "Future Enhancements" list. These lists are
the only record of how the plan changed during 2025.

| Version | Commit | Future enhancements stated |
| --- | --- | --- |
| 1 | `4a6fb60` | Implement user authentication. Add shopping cart and checkout functionality. Integrate with Supabase for data management. Improve UI/UX with interactive features. |
| 2 | `d2e6572` | Improve UI/UX with more interactive elements. **Add payment gateway integration.** **Implement product reviews and ratings.** |
| 3 | `9b8a76e` | Same as Version 2. |
| 4 | `fb0a6c4` | **Adding more payment options.** **Enhancing the product recommendation system.** Implementing customer reviews and ratings. |

What happened to each item is traced in
[Requirements Traceability](05-requirements-traceability.md).

## 2.8 Technology selection

| Layer | Initial selection [ORIGINAL, E03] | Notes |
| --- | --- | --- |
| Framework | Flutter | Dart. The Iteration-1 entry point is `main.dart` with a splash screen and a timer that leads to login. |
| Backend | "Not implemented yet" | Supabase adopted from Iteration 2 (E05). |
| Database | Supabase, "planned for future versions" | Supabase Auth, PostgreSQL tables and Storage from Iteration 2 (E05). |
| Development tools | Android Studio, Visual Studio Code | — |

Packages are not recorded in the original 2025 GitHub snapshots: `pubspec.yaml`
was absent from that history (E07). The package list in the 2025 legacy project (E08) is
`supabase_flutter`, `provider`, `shared_preferences`, `image_picker`, `lottie`,
`fl_chart`, `intl`, `uuid` and `cupertino_icons`. **UNVERIFIED:** which of these
were part of the initial plan and which were added during the iterations.

## 2.9 Original application architecture (Version 1) [RECONSTRUCTED]

```
┌──────────────────────────────────────────────┐
│ Flutter client (Iteration 1, 19 Dart files)  │
│                                              │
│  main.dart ── SplashScreen ── 3 s timer      │
│                   │                          │
│                   ▼                          │
│  LoginRegisterScreen ──► HomePage (grid)     │
│        │                    │                │
│        ▼                    ▼                │
│  SignupScreen        ProductDetails ► Cart   │
│                      ► Checkout ► Confirm    │
│                      Orders, Profile,        │
│                      Account, Shipping,      │
│                      Payment cards, Terms,   │
│                      Wishlist, Notifications │
│                                              │
│  Data: hard-coded Dart lists + local assets  │
│  Navigation: imperative Navigator.push       │
└──────────────────────────────────────────────┘
          (no backend; Supabase planned)
```

Evidence: E03 ("Backend: Not implemented yet"). The Iteration-1 files contain
no Supabase import (`main.dart` at `bc245c6` calls only `runApp`).

**Repository layout note:** original GitHub `main` at `1fe679e` stores Dart files at the repository
root (not under `lib/`). It has no `pubspec.yaml`, `assets/` or platform folders
(E07). It is therefore a source record and cannot be built as a Flutter project
on its own.

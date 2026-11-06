# Kidz Store

Kidz Store is a Flutter mobile shopping application for children's products,
backed by Supabase (Auth, PostgreSQL with Row-Level Security, and Storage). It
supports four roles:

- **Guests** browse the catalogue.
- **Buyers** shop, check out and track orders.
- **Sellers** manage their own products.
- **Admins** oversee users, Sellers, products and orders.

## Documentation

Start with the [documentation index](docs/README.md).

- [Current State (2026-11-06)](docs/current-state-2026-11-06.md): architecture,
  Supabase Auth, RLS, Admin permissions, Android status
- [Evidence Register and Timeline](docs/history/01-evidence-and-timeline.md)
- [Initial Project Plan (March 2025)](docs/history/02-initial-project-plan.md)
- [Development History](docs/history/03-development-history.md)
- [July 2026 Improvement Plan](docs/history/04-july-2026-improvement-plan.md)
- [Requirements Traceability](docs/history/05-requirements-traceability.md)

Technical references:

- [SUPABASE.md](SUPABASE.md): backend configuration, migrations, tests
- [ADMIN_PHASE2.md](ADMIN_PHASE2.md): current Admin permissions and
  integration steps
- [KIDZ_PROJECT_DOCUMENTATION.md](KIDZ_PROJECT_DOCUMENTATION.md): screen-level
  analysis of the baseline application

## Running the app

The current application reads its Supabase settings at build time; no key
literal is present in the current source tree. A legacy public `anon` key remains
in the original 2025 Git history; see the [evidence register](docs/history/01-evidence-and-timeline.md#15-register-of-information-that-could-not-be-verified).

**Integration status:** final `main` merge is blocked by a confirmed Seller order
visibility and sales-report regression. See [Current State](docs/current-state-2026-11-06.md#seller-order-visibility-confirmed-bug) for the isolated reproduction. No RLS or application fix was made during this documentation review.

Run with:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_YOUR_KEY
```

See [SUPABASE.md](SUPABASE.md) for build, migration and test instructions.

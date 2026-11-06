-- Kidz store — initial backend schema.
--
-- Derived directly from the Supabase calls in lib/. Table and column names match
-- what the Flutter source already expects; nothing here is speculative.
--
-- Every table has RLS enabled. The guiding rules:
--   * products are the only publicly readable data (guest browsing)
--   * everything else is owner-scoped via auth.uid()
--   * sellers act through their own sellers row, never by claiming a seller_id
--
-- This migration is additive only: no DROP, no TRUNCATE, no destructive DDL.

create extension if not exists "pgcrypto" with schema extensions;

-- ---------------------------------------------------------------------------
-- Shared helpers
-- ---------------------------------------------------------------------------

-- Keeps updated_at honest without the client having to remember.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- users — buyer/seller profile, keyed by the auth user id
-- ---------------------------------------------------------------------------
-- lib/signup.dart writes id/first_name/last_name/gender/mobile_number/email.
-- lib/shipping.dart writes country/address/city/postcode.

create table if not exists public.users (
  id            uuid primary key references auth.users (id) on delete cascade,
  first_name    text,
  last_name     text,
  email         text,
  mobile_number text,
  gender        text,
  country       text,
  address       text,
  city          text,
  postcode      text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

comment on table public.users is
  'Application profile for an authenticated user. One row per auth.users row.';

create trigger users_set_updated_at
  before update on public.users
  for each row execute function public.set_updated_at();

alter table public.users enable row level security;

create policy "users: read own profile"
  on public.users for select
  to authenticated
  using ((select auth.uid()) = id);

create policy "users: insert own profile"
  on public.users for insert
  to authenticated
  with check ((select auth.uid()) = id);

create policy "users: update own profile"
  on public.users for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

create policy "users: delete own profile"
  on public.users for delete
  to authenticated
  using ((select auth.uid()) = id);

-- Profile bootstrap: guarantees a profile row exists for every auth user, even
-- when the account is created outside the signup screen. lib/signup.dart upserts
-- the same row immediately afterwards to fill in the remaining fields, so this
-- must not conflict.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.users (id, email)
  values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- sellers — a user's seller registration
-- ---------------------------------------------------------------------------
-- lib/seller_reg.dart and lib/seller.dart insert user_id/ssm_number/
-- company_name/company_type/product_type/location.

create table if not exists public.sellers (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null unique references auth.users (id) on delete cascade,
  ssm_number   text,
  company_name text,
  company_type text,
  product_type text,
  location     text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

comment on table public.sellers is
  'Seller registration. The unique user_id enforces at most one seller per user.';

create index if not exists sellers_user_id_idx on public.sellers (user_id);

create trigger sellers_set_updated_at
  before update on public.sellers
  for each row execute function public.set_updated_at();

alter table public.sellers enable row level security;

create policy "sellers: read own registration"
  on public.sellers for select
  to authenticated
  using ((select auth.uid()) = user_id);

-- A user may only register themselves as a seller, never someone else.
create policy "sellers: register self"
  on public.sellers for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "sellers: update own registration"
  on public.sellers for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "sellers: delete own registration"
  on public.sellers for delete
  to authenticated
  using ((select auth.uid()) = user_id);

-- True when the given sellers.id belongs to the calling user. Used by the
-- products and storage policies so a seller can never act as another seller.
create or replace function public.is_own_seller(seller uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.sellers s
    where s.id = seller
      and s.user_id = (select auth.uid())
  );
$$;

-- True when the calling user has any seller registration.
create or replace function public.is_seller()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.sellers s
    where s.user_id = (select auth.uid())
  );
$$;

-- ---------------------------------------------------------------------------
-- products — publicly readable catalogue
-- ---------------------------------------------------------------------------
-- lib/add_product.dart and lib/seller_dashboard.dart insert seller_id/
-- product_name/product_sizes/product_colors/product_description/product_price/
-- product_images. lib/home.dart also reads rating; lib/*_dashboard order by
-- created_at.

create table if not exists public.products (
  id                  uuid primary key default gen_random_uuid(),
  seller_id           uuid not null references public.sellers (id) on delete cascade,
  product_name        text not null,
  product_description text,
  product_price       numeric(10, 2) not null default 0 check (product_price >= 0),
  product_sizes       text[] not null default '{}',
  product_colors      text[] not null default '{}',
  product_images      text[] not null default '{}',
  rating              numeric(2, 1) not null default 3 check (rating >= 0 and rating <= 5),
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

comment on column public.products.product_images is
  'Remote image URLs only. Local Flutter asset paths are a rendering fallback '
  'and must never be persisted here (see lib/product_image.dart).';

create index if not exists products_seller_id_idx on public.products (seller_id);
create index if not exists products_created_at_idx on public.products (created_at desc);

create trigger products_set_updated_at
  before update on public.products
  for each row execute function public.set_updated_at();

alter table public.products enable row level security;

-- Guest browsing: the catalogue is the only publicly readable table.
create policy "products: public read"
  on public.products for select
  to anon, authenticated
  using (true);

create policy "products: seller inserts own"
  on public.products for insert
  to authenticated
  with check (public.is_own_seller(seller_id));

create policy "products: seller updates own"
  on public.products for update
  to authenticated
  using (public.is_own_seller(seller_id))
  with check (public.is_own_seller(seller_id));

create policy "products: seller deletes own"
  on public.products for delete
  to authenticated
  using (public.is_own_seller(seller_id));

-- ---------------------------------------------------------------------------
-- cart — per-buyer basket
-- ---------------------------------------------------------------------------
-- lib/cart.dart treats cart.id as an int (deleteCartItem(int id)) and reads the
-- embedded products relationship, so product_id must be a real FK.

create table if not exists public.cart (
  id         bigint generated always as identity primary key,
  user_id    uuid not null references auth.users (id) on delete cascade,
  product_id uuid not null references public.products (id) on delete cascade,
  size       text,
  color      text,
  quantity   integer not null default 1 check (quantity > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.cart is
  'Buyer basket. Private to its owner — never publicly readable.';

create index if not exists cart_user_id_idx on public.cart (user_id);
create index if not exists cart_product_id_idx on public.cart (product_id);

-- lib/product_details.dart looks up an existing row by
-- (user_id, product_id, size, color) before inserting, so that combination must
-- be unique. COALESCE keeps the constraint meaningful when size/color are null,
-- which a plain UNIQUE would not (SQL treats NULLs as distinct).
create unique index if not exists cart_user_product_variant_key
  on public.cart (user_id, product_id, coalesce(size, ''), coalesce(color, ''));

create trigger cart_set_updated_at
  before update on public.cart
  for each row execute function public.set_updated_at();

alter table public.cart enable row level security;

create policy "cart: read own"
  on public.cart for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "cart: insert own"
  on public.cart for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "cart: update own"
  on public.cart for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "cart: delete own"
  on public.cart for delete
  to authenticated
  using ((select auth.uid()) = user_id);

-- ---------------------------------------------------------------------------
-- orders — per-buyer order history
-- ---------------------------------------------------------------------------
-- lib/checkout.dart supplies its own uuid for id and an ISO-8601 order_date.
-- order_items is written with jsonEncode(...), and lib/orders.dart decodes a
-- string back into a list, so jsonb round-trips correctly here.

create table if not exists public.orders (
  id               uuid primary key,
  user_id          uuid not null references auth.users (id) on delete cascade,
  order_date       timestamptz not null default now(),
  total_price      numeric(10, 2) not null default 0 check (total_price >= 0),
  payment_method   text,
  delivery_address text,
  status           text not null default 'Packaging',
  order_items      jsonb not null default '[]'::jsonb,
  order_name       text,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

comment on table public.orders is
  'Order history. Private to the buyer who placed it.';

create index if not exists orders_user_id_idx on public.orders (user_id);
create index if not exists orders_order_date_idx on public.orders (order_date desc);

create trigger orders_set_updated_at
  before update on public.orders
  for each row execute function public.set_updated_at();

alter table public.orders enable row level security;

create policy "orders: read own"
  on public.orders for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "orders: create own"
  on public.orders for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "orders: update own"
  on public.orders for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "orders: delete own"
  on public.orders for delete
  to authenticated
  using ((select auth.uid()) = user_id);

-- ---------------------------------------------------------------------------
-- bankingcard — saved payment cards
-- ---------------------------------------------------------------------------
-- SECURITY NOTE: lib/addcard.dart writes a raw card number and CVV. Storing a
-- CVV is prohibited by PCI-DSS and no production deployment should do this.
-- The table exists because lib/checkout.dart reads it to populate the card
-- picker; it is locked to its owner and must only ever hold synthetic demo
-- values. Replace with a payment provider token before any real use.

create table if not exists public.bankingcard (
  id             bigint generated always as identity primary key,
  user_id        uuid not null references auth.users (id) on delete cascade,
  cardholdername text not null,
  cardnumber     text not null,
  valid          text,
  cvv            text,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

comment on table public.bankingcard is
  'Demo-only saved cards. Never store real card data or a CVV here.';

create index if not exists bankingcard_user_id_idx on public.bankingcard (user_id);

create trigger bankingcard_set_updated_at
  before update on public.bankingcard
  for each row execute function public.set_updated_at();

alter table public.bankingcard enable row level security;

create policy "bankingcard: read own"
  on public.bankingcard for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "bankingcard: insert own"
  on public.bankingcard for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "bankingcard: update own"
  on public.bankingcard for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "bankingcard: delete own"
  on public.bankingcard for delete
  to authenticated
  using ((select auth.uid()) = user_id);

-- ---------------------------------------------------------------------------
-- admin — intentionally unreachable from any client
-- ---------------------------------------------------------------------------
-- lib/login.dart queries this table and compares a plaintext password in Dart.
-- Exposing such a table to anon/authenticated would hand every guest a list of
-- administrator credentials, so RLS is enabled with NO policies: the table
-- exists (the query resolves) but returns zero rows to every client role.
-- maybeSingle() therefore yields null and login falls through to real Supabase
-- authentication, which is the correct and safe behaviour.
-- Proper admin access should be modelled with a role claim, not this table.

create table if not exists public.admin (
  id         bigint generated always as identity primary key,
  email      text not null unique,
  password   text not null,
  created_at timestamptz not null default now()
);

comment on table public.admin is
  'Deliberately inaccessible: RLS is on with no policies, so all client reads '
  'return zero rows and the legacy plaintext admin login can never match.';

alter table public.admin enable row level security;

-- ---------------------------------------------------------------------------
-- Storage: product-images
-- ---------------------------------------------------------------------------
-- lib/add_product.dart and lib/seller_dashboard.dart upload to
-- 'product-images' at path 'products/<millis>.jpg' and then call getPublicUrl,
-- so the bucket must be public for reads.

insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do nothing;

-- Public read: required for getPublicUrl to resolve in the app and in browsers.
create policy "product-images: public read"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'product-images');

-- Only a registered seller may upload, and only beneath products/.
create policy "product-images: seller upload"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'product-images'
    and public.is_seller()
    and (storage.foldername(name))[1] = 'products'
  );

-- No UPDATE or DELETE policy is defined for this bucket, so both are denied for
-- every client role. That is deliberate: the upload path is a flat
-- 'products/<millis>.jpg' with no seller segment, so ownership cannot be proven
-- from the path. Denying overwrite and delete outright is what guarantees one
-- seller can never clobber another seller's image. Removing an image is an
-- administrative action performed with elevated credentials.

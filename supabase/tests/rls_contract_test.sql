-- pgTAP contract tests for the Kidz RLS rules.
--
-- Run locally with Docker:  supabase test db
-- These never touch the remote project.
--
-- The point of these tests is the negative cases: that a guest cannot write,
-- that one buyer cannot see another buyer's cart or orders, and that a seller
-- cannot touch another seller's products.

begin;
select plan(26);

-- ---------------------------------------------------------------------------
-- Structure
-- ---------------------------------------------------------------------------
select has_table('public', 'users',       'users table exists');
select has_table('public', 'sellers',     'sellers table exists');
select has_table('public', 'products',    'products table exists');
select has_table('public', 'cart',        'cart table exists');
select has_table('public', 'orders',      'orders table exists');
select has_table('public', 'bankingcard', 'bankingcard table exists');
select has_table('public', 'admin',       'admin table exists');

-- Every application table must have RLS switched on. A table exposed through
-- PostgREST without RLS is world-writable.
select is(
  (select count(*)::int
   from pg_tables
   where schemaname = 'public'
     and tablename in ('users','sellers','products','cart','orders','bankingcard','admin')
     and not rowsecurity),
  0,
  'every public application table has RLS enabled'
);

-- ---------------------------------------------------------------------------
-- Fixtures: two buyers and two sellers
-- ---------------------------------------------------------------------------
insert into auth.users (id, email)
values
  ('aaaaaaaa-0000-4000-8000-000000000001', 'buyer-a@example.test'),
  ('aaaaaaaa-0000-4000-8000-000000000002', 'buyer-b@example.test'),
  ('bbbbbbbb-0000-4000-8000-000000000001', 'seller-a@example.test'),
  ('bbbbbbbb-0000-4000-8000-000000000002', 'seller-b@example.test');

insert into public.sellers (id, user_id, company_name)
values
  ('cccccccc-0000-4000-8000-000000000001', 'bbbbbbbb-0000-4000-8000-000000000001', 'Seller A Sdn Bhd'),
  ('cccccccc-0000-4000-8000-000000000002', 'bbbbbbbb-0000-4000-8000-000000000002', 'Seller B Sdn Bhd');

insert into public.products (id, seller_id, product_name, product_price)
values
  ('dddddddd-0000-4000-8000-000000000001', 'cccccccc-0000-4000-8000-000000000001', 'A Product', 10.00),
  ('dddddddd-0000-4000-8000-000000000002', 'cccccccc-0000-4000-8000-000000000002', 'B Product', 20.00);

insert into public.cart (user_id, product_id, size, color, quantity)
values ('aaaaaaaa-0000-4000-8000-000000000001', 'dddddddd-0000-4000-8000-000000000001', 'M', 'Red', 1);

insert into public.orders (id, user_id, total_price)
values ('eeeeeeee-0000-4000-8000-000000000001', 'aaaaaaaa-0000-4000-8000-000000000001', 30.00);

-- ---------------------------------------------------------------------------
-- Guest (anon)
-- ---------------------------------------------------------------------------
set local role anon;

select is(
  (select count(*)::int from public.products),
  2,
  'guest can read the public product catalogue'
);

select throws_ok(
  $$ insert into public.products (seller_id, product_name, product_price)
     values ('cccccccc-0000-4000-8000-000000000001', 'Hacked', 1.00) $$,
  '42501',
  null,
  'guest cannot create products'
);

select is((select count(*)::int from public.cart),        0, 'guest cannot read any cart');
select is((select count(*)::int from public.orders),      0, 'guest cannot read any order');
select is((select count(*)::int from public.users),       0, 'guest cannot read any profile');
select is((select count(*)::int from public.bankingcard), 0, 'guest cannot read saved cards');
select is((select count(*)::int from public.admin),       0, 'guest cannot read the admin table');

reset role;

-- ---------------------------------------------------------------------------
-- Buyer A
-- ---------------------------------------------------------------------------
set local role authenticated;
set local request.jwt.claims = '{"sub":"aaaaaaaa-0000-4000-8000-000000000001","role":"authenticated"}';

select is((select count(*)::int from public.cart),   1, 'buyer A sees only their own cart row');
select is((select count(*)::int from public.orders), 1, 'buyer A sees only their own order');

select throws_ok(
  $$ insert into public.orders (id, user_id, total_price)
     values ('eeeeeeee-0000-4000-8000-000000000009',
             'aaaaaaaa-0000-4000-8000-000000000002', 5.00) $$,
  '42501',
  null,
  'buyer A cannot create an order for another buyer'
);

select throws_ok(
  $$ insert into public.products (seller_id, product_name, product_price)
     values ('cccccccc-0000-4000-8000-000000000001', 'Not mine', 1.00) $$,
  '42501',
  null,
  'a buyer cannot create seller products'
);

-- ---------------------------------------------------------------------------
-- Buyer B — must not see buyer A's private data
-- ---------------------------------------------------------------------------
set local request.jwt.claims = '{"sub":"aaaaaaaa-0000-4000-8000-000000000002","role":"authenticated"}';

select is((select count(*)::int from public.cart),   0, 'buyer B cannot see buyer A''s cart');
select is((select count(*)::int from public.orders), 0, 'buyer B cannot see buyer A''s orders');

-- ---------------------------------------------------------------------------
-- Seller A
-- ---------------------------------------------------------------------------
set local request.jwt.claims = '{"sub":"bbbbbbbb-0000-4000-8000-000000000001","role":"authenticated"}';

select lives_ok(
  $$ insert into public.products (seller_id, product_name, product_price)
     values ('cccccccc-0000-4000-8000-000000000001', 'A New Product', 12.00) $$,
  'seller A can create a product under their own seller id'
);

select throws_ok(
  $$ insert into public.products (seller_id, product_name, product_price)
     values ('cccccccc-0000-4000-8000-000000000002', 'Impersonated', 12.00) $$,
  '42501',
  null,
  'seller A cannot create a product under seller B''s id'
);

-- An UPDATE blocked by RLS is silently a no-op rather than an error, so assert
-- on the row count actually affected.
update public.products
set product_name = 'Tampered'
where id = 'dddddddd-0000-4000-8000-000000000002';

select is(
  (select product_name from public.products
   where id = 'dddddddd-0000-4000-8000-000000000002'),
  'B Product',
  'seller A cannot modify seller B''s product'
);

delete from public.products where id = 'dddddddd-0000-4000-8000-000000000002';

select isnt(
  (select count(*)::int from public.products
   where id = 'dddddddd-0000-4000-8000-000000000002'),
  0,
  'seller A cannot delete seller B''s product'
);

select throws_ok(
  $$ insert into public.sellers (user_id, company_name)
     values ('aaaaaaaa-0000-4000-8000-000000000002', 'Privilege grab') $$,
  '42501',
  null,
  'a user cannot register someone else as a seller'
);

reset role;

select * from finish();
rollback;

-- Run ONLY in a fresh, isolated LOCAL test database. All fixtures roll back.
begin;
select no_plan();

select is((select count(*)::int from pg_policies
  where schemaname = 'public' and policyname in
    ('users: admin read', 'sellers: admin read', 'orders: admin read')
    and cmd = 'SELECT' and roles = array['authenticated']::name[]),
  3, 'exactly three authenticated-only Admin SELECT policies');
select is((select count(*)::int from pg_policies
  where schemaname = 'public' and policyname like '%admin%' and cmd <> 'SELECT'),
  0, 'no Admin write policies');
select is((select count(*)::int from pg_policies
  where schemaname = 'public' and tablename = 'admin'),
  0, 'legacy admin remains without policies');

insert into auth.users (id, email, raw_app_meta_data, email_confirmed_at) values
 ('10000000-0000-4000-8000-000000000001','admin@example.test','{"role":"admin"}',now()),
 ('10000000-0000-4000-8000-000000000002','buyer-a@example.test','{}',now()),
 ('10000000-0000-4000-8000-000000000003','buyer-b@example.test','{}',now()),
 ('10000000-0000-4000-8000-000000000004','seller@example.test','{}',now());
insert into auth.sessions(id,user_id) values
 ('50000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001');
insert into public.sellers (id,user_id) values
 ('20000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000004'),
 ('20000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000003');
insert into public.products (id,seller_id,product_name) values
 ('30000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001','Seller product'),
 ('30000000-0000-4000-8000-000000000002','20000000-0000-4000-8000-000000000002','Other product');
insert into public.orders (id,user_id,total_price) values
 ('40000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000002',10),
 ('40000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000003',20);
insert into public.cart(user_id,product_id) values
 ('10000000-0000-4000-8000-000000000002','30000000-0000-4000-8000-000000000001');
insert into public.bankingcard(user_id,cardholdername,cardnumber) values
 ('10000000-0000-4000-8000-000000000002','Synthetic test','synthetic');
insert into public.admin(email,password) values ('legacy@example.test','unused-synthetic-fixture');

set local role anon;
set local request.jwt.claims = '{}';
select is((select count(*)::int from public.users),0,'guest cannot read profiles');
select is((select count(*)::int from public.sellers),0,'guest cannot read sellers');
select is((select count(*)::int from public.orders),0,'guest cannot read orders');
select is((select count(*)::int from public.products),2,'guest retains catalogue reads');
select is((select count(*)::int from public.admin),0,'guest cannot read legacy credentials');
reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"10000000-0000-4000-8000-000000000002","role":"authenticated","user_metadata":{"role":"admin"}}';
select is((select count(*)::int from public.users),1,'user_metadata cannot grant Admin profile reads');
select is((select count(*)::int from public.sellers),0,'buyer cannot read sellers');
select is((select count(*)::int from public.orders),1,'buyer still sees own orders only');
select is((select count(*)::int from public.cart),1,'buyer retains own cart');
select is((select count(*)::int from public.bankingcard),1,'buyer retains own saved card');
select is((select count(*)::int from public.admin),0,'authenticated buyer cannot read legacy credentials');
set local request.jwt.claims = '{"sub":"10000000-0000-4000-8000-000000000002","role":"authenticated","app_metadata":{"role":true}}';
select is((select count(*)::int from public.users),1,'boolean role cannot grant Admin');
set local request.jwt.claims = '{"sub":"10000000-0000-4000-8000-000000000002","role":"authenticated","app_metadata":{"role":"Admin"}}';
select is((select count(*)::int from public.users),1,'role must match exact lowercase admin');
set local request.jwt.claims = '{"sub":"10000000-0000-4000-8000-000000000002","role":"authenticated","app_metadata":{"role":{"name":"admin"}}}';
select is((select count(*)::int from public.users),1,'object role cannot grant Admin');
set local request.jwt.claims = '{"role":"authenticated","app_metadata":{"role":"admin"}}';
select is((select count(*)::int from public.users),0,'Admin claim without identity is denied');

set local request.jwt.claims = '{"sub":"10000000-0000-4000-8000-000000000004","role":"authenticated"}';
select is((select count(*)::int from public.users),1,'seller retains own profile only');
select is((select count(*)::int from public.sellers),1,'seller retains own registration only');
select is((select count(*)::int from public.orders),0,'seller does not gain buyer order reads');
select lives_ok($$update public.products set product_name='Own edit'
  where id='30000000-0000-4000-8000-000000000001'$$,'seller can still edit own product');
with changed as (update public.products set product_name='Forbidden'
  where id='30000000-0000-4000-8000-000000000002' returning id)
select is((select count(*)::int from changed),0,'seller cannot edit another seller product');

set local request.jwt.claims = '{"sub":"10000000-0000-4000-8000-000000000001","role":"authenticated","session_id":"50000000-0000-4000-8000-000000000001","exp":4102444800,"app_metadata":{"role":"admin"}}';
select is((select count(*)::int from public.users),4,'Admin can read every profile');
select is((select count(*)::int from public.sellers),2,'Admin can read every seller');
select is((select count(*)::int from public.orders),2,'Admin can read every order');
select is((select count(*)::int from public.products),2,'Admin can read catalogue');
select is((select count(*)::int from public.cart),0,'Admin does not gain private cart access');
select is((select count(*)::int from public.bankingcard),0,'Admin does not gain private card access');
select is((select count(*)::int from public.admin),0,'Admin cannot read legacy credentials');
with changed as (update public.users set first_name='Forbidden'
  where id='10000000-0000-4000-8000-000000000002' returning id)
select is((select count(*)::int from changed),0,'Admin cannot update other profiles');
with changed as (delete from public.users
  where id='10000000-0000-4000-8000-000000000002' returning id)
select is((select count(*)::int from changed),0,'Admin cannot delete other profiles');
with changed as (update public.sellers set company_name='Forbidden' returning id)
select is((select count(*)::int from changed),0,'Admin cannot update sellers');
with changed as (delete from public.sellers returning id)
select is((select count(*)::int from changed),0,'Admin cannot delete sellers');
with changed as (update public.products set product_name='Forbidden' returning id)
select is((select count(*)::int from changed),0,'Admin cannot update products');
with changed as (delete from public.products returning id)
select is((select count(*)::int from changed),0,'Admin cannot delete products');
with changed as (update public.orders set status='Shipping' returning id)
select is((select count(*)::int from changed),0,'Admin cannot update orders');
with changed as (delete from public.orders returning id)
select is((select count(*)::int from changed),0,'Admin cannot delete orders');
select throws_ok($$insert into public.products(seller_id,product_name)
  values ('20000000-0000-4000-8000-000000000001','Forbidden')$$,
  '42501',null,'Admin cannot create products as another seller');
select throws_ok($$insert into public.orders(id,user_id) values
  ('40000000-0000-4000-8000-000000000009','10000000-0000-4000-8000-000000000002')$$,
  '42501',null,'Admin cannot create orders as another buyer');

-- Revocation is effective in RLS when the JWT is refreshed/expired.
set local request.jwt.claims = '{"sub":"10000000-0000-4000-8000-000000000001","role":"authenticated","app_metadata":{}}';
select is((select count(*)::int from public.users),1,'refreshed demoted Admin sees own profile only');
select is((select count(*)::int from public.orders),0,'refreshed demoted Admin loses order reads');
reset role;
select * from finish();
rollback;

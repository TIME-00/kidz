begin;
select plan(22);
insert into auth.users(id,email,raw_app_meta_data,email_confirmed_at) values
 ('71000000-0000-4000-8000-000000000001','synthetic-admin@example.test','{"role":"admin"}',now()),
 ('71000000-0000-4000-8000-000000000002','synthetic-buyer@example.test','{}',now()),
 ('71000000-0000-4000-8000-000000000003','synthetic-a@example.test','{}',now()),
 ('71000000-0000-4000-8000-000000000004','synthetic-b@example.test','{}',now());
insert into auth.sessions(id,user_id) select
 replace(id::text,'71000000','81000000')::uuid,id from auth.users where id::text like '71000000-%';
insert into public.sellers(id,user_id) values
 ('71000000-0000-4000-8000-000000000031','71000000-0000-4000-8000-000000000003'),
 ('71000000-0000-4000-8000-000000000032','71000000-0000-4000-8000-000000000004');
insert into public.products(id,seller_id,product_name,product_price) values
 ('71000000-0000-4000-8000-000000000011','71000000-0000-4000-8000-000000000031','Product A',999),
 ('71000000-0000-4000-8000-000000000012','71000000-0000-4000-8000-000000000032','Product B',888);
insert into public.orders(id,user_id,order_date,total_price,delivery_address,order_items) values
 ('71000000-0000-4000-8000-000000000021','71000000-0000-4000-8000-000000000002',
 '2026-01-31 23:59:59.999999Z',40,'PRIVATE CUSTOMER',
 '[{"product_id":"71000000-0000-4000-8000-000000000011","product_name":"Historic A","price":19.99,"quantity":2,"buyer_email":"must-not-leak@example.test"}]'),
 ('71000000-0000-4000-8000-000000000022','71000000-0000-4000-8000-000000000002',
 '2026-02-01Z',120,'PRIVATE CUSTOMER',
 to_jsonb('[{"product_id":"71000000-0000-4000-8000-000000000011","price":10,"quantity":2},{"product_id":"71000000-0000-4000-8000-000000000012","price":50,"quantity":2}]'::text));
select set_config('request.jwt.claims',jsonb_build_object('sub','71000000-0000-4000-8000-000000000003','role','authenticated','session_id','81000000-0000-4000-8000-000000000003','exp',extract(epoch from now())::bigint+3600)::text,true);
set local role authenticated;
select is(jsonb_array_length(public.seller_order_page()->'orders'),2,'Seller sees both relevant orders');
select is(jsonb_array_length(public.seller_order_page()->'orders'->0->'order_items'),1,'Mixed order contains only own item');
select is(public.seller_order_page()->'orders'->1->'order_items'->0->>'price_cents','1999','Historic unit price, not current catalogue');
select ok(not (public.seller_order_page()->'orders'->0 ? 'user_id'),'Buyer identity excluded');
select ok(not (public.seller_order_page()->'orders'->0 ? 'delivery_address'),'Address excluded');
select ok(not (public.seller_order_page()->'orders'->0 ? 'total_price'),'Other sellers totals excluded');
select ok(not (public.seller_order_page()->'orders'->1->'order_items'->0 ? 'buyer_email'),'Arbitrary snapshot keys excluded');
select is((select count(*)::int from public.orders),0,'No broad raw order SELECT policy');
select throws_ok('select * from kidz_private.seller_order_snapshots','42501',null,'Private snapshot not readable');
select throws_ok($$select public.seller_set_order_status('71000000-0000-4000-8000-000000000022','Shipping',now())$$,'42501',null,'Mixed order status denied');
select throws_ok($$select public.seller_set_order_status('71000000-0000-4000-8000-000000000021','Shipping','2000-01-01')$$,'PT409',null,'Stale status denied');
select is(public.seller_set_order_status('71000000-0000-4000-8000-000000000021','Shipping',
 (public.seller_order_page()->'orders'->1->>'updated_at')::timestamptz)->>'status','Shipping','Exclusive order status works');
select throws_ok($$select public.seller_set_order_status('71000000-0000-4000-8000-000000000021','Refunded',now())$$,'22023',null,'Unknown status denied');
select is(jsonb_array_length(public.seller_order_page('2026-01-01Z','2026-02-01Z')->'orders'),1,'Half-open period keeps fractional last second');
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub','71000000-0000-4000-8000-000000000004','role','authenticated','session_id','81000000-0000-4000-8000-000000000004','exp',extract(epoch from now())::bigint+3600)::text,true);
set local role authenticated;
select is(jsonb_array_length(public.seller_order_page()->'orders'),1,'Seller B sees no Seller-A-only order');
select is(public.seller_order_page()->'orders'->0->'order_items'->0->>'product_id','71000000-0000-4000-8000-000000000012','Seller B sees only own mixed item');
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub','71000000-0000-4000-8000-000000000002','role','authenticated','session_id','81000000-0000-4000-8000-000000000002','exp',extract(epoch from now())::bigint+3600)::text,true);
set local role authenticated;
select is((select count(*)::int from public.orders),2,'Buyer history intact');
select throws_ok('select public.seller_order_page()','42501',null,'Buyer cannot invoke Seller API');
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub','71000000-0000-4000-8000-000000000001','role','authenticated','app_metadata',jsonb_build_object('role','admin'),'session_id','81000000-0000-4000-8000-000000000001','exp',extract(epoch from now())::bigint+3600)::text,true);
set local role authenticated;
select is((select count(*)::int from public.orders),2,'Admin still sees all orders');
select is(public.admin_set_order_status('71000000-0000-4000-8000-000000000022','Delivering',
 (select updated_at from public.orders where id='71000000-0000-4000-8000-000000000022'))->>'status','Delivering','Admin still manages shared order status');
reset role;
set local role anon;
select throws_ok('select public.seller_order_page()','42501',null,'Guest denied Seller read');
select throws_ok($$select public.seller_set_order_status('71000000-0000-4000-8000-000000000021','Shipping',now())$$,'42501',null,'Guest denied Seller write');
select * from finish();
rollback;

-- Supabase-stack pgTAP integration suite. ONLY fresh isolated local databases.
-- Node/PGlite scenarios additionally exercise the same migration with explicit
-- synthetic Auth/Storage interfaces; they do not verify the managed services.
begin;
select no_plan();
insert into auth.users(id,email,raw_app_meta_data,email_confirmed_at) values
 ('70000000-0000-4000-8000-000000000001','admin-mutations@example.test','{"role":"admin"}',now()),
 ('70000000-0000-4000-8000-000000000002','buyer-mutations@example.test','{}',now()),
 ('70000000-0000-4000-8000-000000000003','seller-mutations@example.test','{}',now());
insert into auth.sessions(id,user_id) values
 ('71000000-0000-4000-8000-000000000001','70000000-0000-4000-8000-000000000001');
insert into public.sellers(id,user_id) values
 ('72000000-0000-4000-8000-000000000001','70000000-0000-4000-8000-000000000003');
insert into public.products(id,seller_id,product_name,updated_at) values
 ('73000000-0000-4000-8000-000000000001','72000000-0000-4000-8000-000000000001','Mutation fixture','2026-01-01');
insert into public.cart(user_id,product_id) values
 ('70000000-0000-4000-8000-000000000002','73000000-0000-4000-8000-000000000001');
insert into public.orders(id,user_id,total_price,order_items,updated_at) values
 ('74000000-0000-4000-8000-000000000001','70000000-0000-4000-8000-000000000002',12,
 '[{"product_id":"73000000-0000-4000-8000-000000000001","product_name":"Historical fixture"}]','2026-01-01');
insert into public.bankingcard(user_id,cardholdername,cardnumber) values
 ('70000000-0000-4000-8000-000000000002','Synthetic fixture','synthetic');
create temporary table mutation_preview(kind text primary key,data jsonb);
grant all on mutation_preview to authenticated;

set local role anon;
select throws_ok($$select public.admin_preview_delete('product','73000000-0000-4000-8000-000000000001')$$,
 '42501',null,'guest cannot invoke preview');
select throws_ok($$select public.admin_set_order_status('74000000-0000-4000-8000-000000000001','Shipping','2026-01-01')$$,
 '42501',null,'guest cannot invoke mutation');
reset role;
set local role authenticated;
set local request.jwt.claims='{"sub":"70000000-0000-4000-8000-000000000002","role":"authenticated","user_metadata":{"role":"admin"}}';
select throws_ok($$select public.admin_delete_record('product','73000000-0000-4000-8000-000000000001','forged','DELETE')$$,
 '42501',null,'Buyer cannot call deletion API even with spoofed metadata');
set local request.jwt.claims='{"sub":"70000000-0000-4000-8000-000000000003","role":"authenticated","app_metadata":{"role":"admin"}}';
select throws_ok($$select public.admin_preview_delete('user','70000000-0000-4000-8000-000000000002')$$,
 '42501',null,'Seller cannot forge Admin claims or omit live session');

set local request.jwt.claims='{"sub":"70000000-0000-4000-8000-000000000001","role":"authenticated","session_id":"71000000-0000-4000-8000-000000000001","exp":4102444800,"app_metadata":{"role":"admin"}}';
select throws_ok($$select public.admin_preview_delete('user','70000000-0000-4000-8000-000000000001')$$,
 '42501',null,'self/last Admin deletion is refused');
select throws_ok($$select public.admin_set_order_status('74000000-0000-4000-8000-000000000001','Completed','2026-01-01')$$,
 '22023',null,'only original status vocabulary is accepted');
select lives_ok($$select public.admin_set_order_status('74000000-0000-4000-8000-000000000001','Shipping','2026-01-01')$$,
 'Admin can update another buyer order');
select is((select status from public.orders where id='74000000-0000-4000-8000-000000000001'),
 'Shipping','status is persisted');
select is((select total_price from public.orders where id='74000000-0000-4000-8000-000000000001'),
 12::numeric,'financial value is unchanged');
select throws_ok($$select public.admin_set_order_status('74000000-0000-4000-8000-000000000001','Delivering','2026-01-01')$$,
 'PT409',null,'stale status edits are refused');
select throws_ok($$select * from kidz_private.admin_audit$$,'42501',null,'audit cannot be read by client Admin');

insert into mutation_preview values ('product',public.admin_preview_delete('product','73000000-0000-4000-8000-000000000001'));
select is((select (data->>'cart_rows_deleted')::int from mutation_preview where kind='product'),1,'preview discloses cart impact');
select throws_ok($$select public.admin_delete_record('product','73000000-0000-4000-8000-000000000001','forged','DELETE')$$,
 'PT409',null,'forged deletion token is refused');
select throws_ok($$select public.admin_delete_record('product','73000000-0000-4000-8000-000000000001',
 (select data->>'token' from mutation_preview where kind='product'),'delete')$$,
 '22023',null,'confirmation must match exact DELETE');
select lives_ok($$select public.admin_delete_record('product','73000000-0000-4000-8000-000000000001',
 (select data->>'token' from mutation_preview where kind='product'),'DELETE')$$,'confirmed product deletion succeeds');
select is((select count(*)::int from public.products where id='73000000-0000-4000-8000-000000000001'),0,'product is actually deleted');
select is((select order_items->0->>'product_name' from public.orders where id='74000000-0000-4000-8000-000000000001'),
 'Historical fixture','historical order snapshot is retained');

insert into mutation_preview values ('user',public.admin_preview_delete('user','70000000-0000-4000-8000-000000000002'));
select lives_ok($$select public.admin_delete_record('user','70000000-0000-4000-8000-000000000002',
 (select data->>'token' from mutation_preview where kind='user'),'DELETE')$$,'confirmed user account deletion succeeds');
reset role;
select is((select count(*)::int from auth.users where id='70000000-0000-4000-8000-000000000002'),0,'Auth account is removed');
select is((select count(*)::int from public.users where id='70000000-0000-4000-8000-000000000002'),0,'profile is removed');
select is((select count(*)::int from public.bankingcard where user_id='70000000-0000-4000-8000-000000000002'),0,'private saved card is removed');
select is((select count(*)::int from public.cart where product_id='73000000-0000-4000-8000-000000000001'),0,'product cart entries were removed');
select ok((select user_id is null from public.orders where id='74000000-0000-4000-8000-000000000001'),'order survives deleted buyer FK');
select is((select count(*)::int from kidz_private.admin_audit where actor_id='70000000-0000-4000-8000-000000000001'),3,'status and deletions have audit entries');

-- Original signed claim stays unchanged; live role/session removal denies it.
update auth.users set raw_app_meta_data='{}' where id='70000000-0000-4000-8000-000000000001';
set local role authenticated;
select throws_ok($$select public.admin_preview_delete('user','70000000-0000-4000-8000-000000000003')$$,
 '42501',null,'live role demotion takes effect before JWT expiry');
reset role;
update auth.users set raw_app_meta_data='{"role":"admin"}' where id='70000000-0000-4000-8000-000000000001';
delete from auth.sessions where id='71000000-0000-4000-8000-000000000001';
set local role authenticated;
select throws_ok($$select public.admin_preview_delete('user','70000000-0000-4000-8000-000000000003')$$,
 '42501',null,'logged-out session cannot invoke API with an old token');
reset role;
select * from finish();
rollback;

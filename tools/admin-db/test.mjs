import { readFile } from 'node:fs/promises';
import assert from 'node:assert/strict';
import { PGlite } from '@electric-sql/pglite';
import { pgcrypto } from '@electric-sql/pglite/contrib/pgcrypto';

// No connection string, environment secret, socket, or persisted database.
const db = await PGlite.create({ extensions: { pgcrypto } });
const root = new URL('../../', import.meta.url);
const sql = async (path) => readFile(new URL(path, root), 'utf8');
const id = (n) => `10000000-0000-4000-8000-${String(n).padStart(12, '0')}`;
const admin = id(1), buyer = id(2), buyerB = id(3), seller = id(4), sellerB = id(5), adminB = id(6);
const product = id(11), productB = id(12), order = id(21), orderB = id(22);
const session = (user) => user.replace('10000000', '90000000');
const claims = (user, role) => ({ sub: user, role: 'authenticated',
  session_id: session(user), exp: Math.floor(Date.now() / 1000) + 3600,
  app_metadata: role ? { role } : {} });
const tests = [];
function test(name, run) { tests.push({ name, run }); }
async function one(query, args = []) { return (await db.query(query, args)).rows[0]; }
async function count(table, where = 'true') { return Number((await one(`select count(*) as n from ${table} where ${where}`)).n); }
async function actor(user, role, overrides = {}) {
  await db.exec('reset role');
  await db.query("select set_config('request.jwt.claims',$1,true)", [JSON.stringify({ ...claims(user, role), ...overrides })]);
  await db.exec('set local role authenticated');
}
async function owner() { await db.exec('reset role'); }
async function rejected(query, args, code) {
  await db.exec('savepoint rejection');
  let caught;
  try { await db.query(query, args); } catch (error) { caught = error; }
  await db.exec('rollback to savepoint rejection; release savepoint rejection');
  assert.ok(caught, 'expected database rejection');
  assert.equal(caught.code, code);
}
async function preview(kind, target) {
  return (await one('select public.admin_preview_delete($1,$2) as data', [kind, target])).data;
}
async function remove(kind, target, token, confirmation = 'DELETE') {
  return (await one('select public.admin_delete_record($1,$2,$3,$4) as data', [kind, target, token, confirmation])).data;
}
async function orderVersion() { return (await one('select updated_at::text as v from public.orders where id=$1', [order])).v; }

async function fixtures() {
  for (const [user, role] of [[admin,'admin'],[buyer,null],[buyerB,null],[seller,null],[sellerB,null],[adminB,'admin']]) {
    await db.query('insert into auth.users(id,email,raw_app_meta_data,email_confirmed_at) values($1,$2,$3,now())',
      [user, `synthetic-${user.slice(-2)}@example.test`, JSON.stringify(role ? { role } : {})]);
    await db.query('insert into auth.sessions(id,user_id) values($1,$2)', [session(user),user]);
    await db.query('insert into auth.identities(user_id) values($1)',[user]);
    await db.query('insert into auth.refresh_tokens(user_id,session_id) values($1,$2),($1,null)',[user,session(user)]);
    await db.query('insert into auth.flow_state(user_id) values($1)',[user]);
  }
  await db.query('insert into public.sellers(id,user_id) values($1,$2),($3,$4)',[id(31),seller,id(32),sellerB]);
  await db.query(`insert into public.products(id,seller_id,product_name,product_images,updated_at)
    values($1,$2,'Product A',ARRAY['https://synthetic.invalid/shared.jpg'],'2026-01-01'),
    ($3,$4,'Product B',ARRAY['https://synthetic.invalid/shared.jpg'],'2026-01-01')`,[product,id(31),productB,id(32)]);
  await db.query(`insert into public.orders(id,user_id,total_price,status,order_items,updated_at)
    values($1,$2,12,'Packaging',$3::jsonb,'2026-01-01'),($4,$5,20,'Packaging','[]','2026-01-01')`,
    [order,buyer,JSON.stringify([{ product_id: product, product_name:'Product A', product_images:['https://synthetic.invalid/shared.jpg'] }]),orderB,buyerB]);
  await db.query('insert into public.cart(user_id,product_id) values($1,$2),($3,$2),($3,$4)',[buyer,product,buyerB,productB]);
  await db.query("insert into public.bankingcard(user_id,cardholdername,cardnumber) values($1,'Synthetic','synthetic')",[buyer]);
  await db.query("insert into storage.objects(bucket_id,name,owner,owner_id) values('product-images','products/shared.jpg',$1,$2)",[seller,seller]);
}

for (const [who, role] of [[buyer,null],[seller,null],[buyer,'admin']]) {
  test(`direct RPC rejects ${who === seller ? 'Seller' : role ? 'spoofed Admin' : 'Buyer'}`, async () => {
    await actor(who,role,{ user_metadata:{role:'admin'} });
    await rejected('select public.admin_preview_delete($1,$2)',['product',product],'42501');
    await rejected('select public.admin_delete_record($1,$2,$3,$4)',['product',product,'forged','DELETE'],'42501');
    await rejected('select public.admin_set_order_status($1,$2,$3)',[order,'Shipping','2026-01-01'],'42501');
  });
}
test('guest cannot execute any Admin wrapper', async () => {
  await db.exec('set local role anon');
  await rejected('select public.admin_preview_delete($1,$2)',['product',product],'42501');
  await rejected('select public.admin_delete_record($1,$2,$3,$4)',['product',product,'forged','DELETE'],'42501');
  await rejected('select public.admin_set_order_status($1,$2,$3)',[order,'Shipping','2026-01-01'],'42501');
});
for (const scenario of ['expired','logout','demoted','banned','session-expired','missing-session','malformed-session']) {
  test(`${scenario} is rejected by database reads and mutations`, async () => {
    if(scenario==='logout') await db.query('delete from auth.sessions where user_id=$1',[admin]);
    if(scenario==='demoted') await db.query("update auth.users set raw_app_meta_data='{}' where id=$1",[admin]);
    if(scenario==='banned') await db.query("update auth.users set banned_until=now()+interval '1 day' where id=$1",[admin]);
    if(scenario==='session-expired') await db.query("update auth.sessions set not_after=now()-interval '1 second' where user_id=$1",[admin]);
    await actor(admin,'admin',scenario==='expired'?{exp:1}:scenario==='missing-session'?{session_id:null}:scenario==='malformed-session'?{session_id:'invalid'}:{});
    assert.equal(await count('public.users'),1);
    await rejected('select public.admin_preview_delete($1,$2)',['product',product],'42501');
  });
}
test('Admin sees every application record but no private carts/cards/legacy credentials',async()=>{
  await actor(admin,'admin');
  assert.equal(await count('public.users'),6); assert.equal(await count('public.sellers'),2);
  assert.equal(await count('public.products'),2); assert.equal(await count('public.orders'),2);
  assert.equal(await count('public.cart'),0); assert.equal(await count('public.bankingcard'),0);
  assert.equal(await count('public.admin'),0);
});
test('no direct global Admin UPDATE/DELETE is granted',async()=>{
  await actor(admin,'admin');
  for(const table of ['users','sellers','products','orders']) {
    const result=await one(`with gone as (delete from public.${table} where id<>$1 returning id) select count(*) as n from gone`,[admin]);
    assert.equal(Number(result.n),0);
  }
});
test('order status can be corrected across owners, with immutable financial/owner fields',async()=>{
  const before=await one('select * from public.orders where id=$1',[order]);
  await actor(admin,'admin');
  await one('select public.admin_set_order_status($1,$2,$3)',[order,'Delivering',await orderVersion()]);
  await one('select public.admin_set_order_status($1,$2,$3)',[order,'Packaging',await orderVersion()]);
  await owner(); const after=await one('select * from public.orders where id=$1',[order]);
  for(const key of ['user_id','total_price','order_items','delivery_address','payment_method']) assert.deepEqual(after[key],before[key]);
  assert.equal(after.status,'Packaging'); assert.equal(await count('kidz_private.admin_audit'),2);
});
test('invalid or stale order updates are rejected atomically',async()=>{
  await actor(admin,'admin'); const old=await orderVersion();
  await rejected('select public.admin_set_order_status($1,$2,$3)',[order,'Completed',old],'22023');
  await one('select public.admin_set_order_status($1,$2,$3)',[order,'Shipping',old]);
  await rejected('select public.admin_set_order_status($1,$2,$3)',[order,'Delivering',old],'PT409');
  assert.equal((await one('select status from public.orders where id=$1',[order])).status,'Shipping');
});
test('product deletion removes exactly its carts, retains snapshots and shared images',async()=>{
  const snapshots=(await one('select order_items from public.orders where id=$1',[order])).order_items;
  await actor(admin,'admin'); const p=await preview('product',product);
  assert.equal(p.cart_rows_deleted,2);
  assert.equal((await remove('product',product,p.token)).deleted,true);
  await owner(); assert.equal(await count('public.products'),1); assert.equal(await count('public.cart'),1);
  assert.deepEqual((await one('select order_items from public.orders where id=$1',[order])).order_items,snapshots);
  assert.equal(await count('storage.objects'),1); assert.equal(await count('public.orders'),2);
  assert.equal(await count('kidz_private.admin_audit'),1);
});
test('typed confirmation, forged tokens and changed effects cannot delete',async()=>{
  await actor(admin,'admin'); const p=await preview('product',product);
  await rejected('select public.admin_delete_record($1,$2,$3,$4)',['product',product,p.token,'delete'],'22023');
  await rejected('select public.admin_delete_record($1,$2,$3,$4)',['product',product,'forged','DELETE'],'PT409');
  await owner(); await db.query('delete from public.cart where user_id=$1 and product_id=$2',[buyer,product]);
  await actor(admin,'admin');
  await rejected('select public.admin_delete_record($1,$2,$3,$4)',['product',product,p.token,'DELETE'],'PT409');
  assert.equal(await count('public.products'),2);
});
test('buyer deletion removes Auth identities/sessions/profile/private data and retains orders',async()=>{
  await actor(admin,'admin'); const p=await preview('user',buyer);
  assert.equal(p.orders_retained,1); assert.equal(p.cards_deleted,1);
  await remove('user',buyer,p.token);
  await owner();
  for(const table of ['auth.users','auth.sessions','auth.identities','auth.refresh_tokens','auth.flow_state','public.users','public.cart','public.bankingcard']) {
    const col=table==='auth.users'||table==='public.users'?'id':'user_id';
    assert.equal(await count(table,`${col}='${buyer}'`),0);
  }
  assert.equal(await count('public.orders'),2);
  assert.equal((await one('select user_id from public.orders where id=$1',[order])).user_id,null);
  assert.equal(await count('public.products'),2);
});
test('seller deletion discloses cascading products/carts and retains image metadata/URLs',async()=>{
  await actor(admin,'admin'); const p=await preview('user',seller);
  assert.equal(p.products_deleted,1); assert.equal(p.cart_rows_deleted,2); assert.equal(p.images_retained,1);
  await remove('user',seller,p.token); await owner();
  assert.equal(await count('auth.users',`id='${seller}'`),0);
  assert.equal(await count('public.sellers'),1); assert.equal(await count('public.products'),1);
  assert.equal(await count('public.cart'),1); assert.equal(await count('public.orders'),2);
  const object=await one('select owner,owner_id,name from storage.objects');
  assert.equal(object.owner,admin); assert.equal(object.owner_id,admin); assert.equal(object.name,'products/shared.jpg');
});
test('self and all Admin targets are protected, including the last Admin',async()=>{
  await actor(admin,'admin');
  for(const target of [admin,adminB]) await rejected('select public.admin_preview_delete($1,$2)',['user',target],'42501');
  await owner(); await db.query("update auth.users set raw_app_meta_data='{}' where id=$1",[adminB]);
  await actor(admin,'admin'); await rejected('select public.admin_preview_delete($1,$2)',['user',admin],'42501');
});
test('unrelated Storage ownership is refused without partial effects',async()=>{
  await db.exec("insert into storage.buckets(id,name) values('unrelated','Unrelated')");
  await db.query("insert into storage.objects(bucket_id,name,owner,owner_id) values('unrelated','private',$1,$2)",[buyer,buyer]);
  await actor(admin,'admin'); await rejected('select public.admin_preview_delete($1,$2)',['user',buyer],'23514');
  await owner(); assert.equal(await count('auth.users'),6); assert.equal(await count('storage.objects'),2);
});
test('any downstream failure rolls back Auth, business data, storage ownership and audit',async()=>{
  await db.exec(`create function pg_temp.reject_audit() returns trigger language plpgsql as $$begin raise exception 'synthetic failure'; end;$$;
    create trigger reject_test_audit before insert on kidz_private.admin_audit for each row execute function pg_temp.reject_audit()`);
  await actor(admin,'admin'); const p=await preview('user',seller);
  await rejected('select public.admin_delete_record($1,$2,$3,$4)',['user',seller,p.token,'DELETE'],'P0001');
  await owner(); assert.equal(await count('auth.users'),6); assert.equal(await count('public.products'),2);
  assert.equal((await one('select owner_id from storage.objects')).owner_id,seller);
  assert.equal(await count('kidz_private.admin_audit'),0);
});
test('Buyer/Seller registration, profile, catalogue, cart and order isolation remains intact',async()=>{
  await actor(buyer,null); assert.equal(await count('public.users'),1); assert.equal(await count('public.orders'),1);
  assert.equal(await count('public.products'),2);
  await db.query("update public.users set first_name='Buyer' where id=$1",[buyer]);
  await db.query('insert into public.sellers(user_id) values($1)',[buyer]);
  await db.query('insert into public.cart(user_id,product_id,size) values($1,$2,$3)',[buyer,productB,'S']);
  await rejected('insert into public.cart(user_id,product_id) values($1,$2)',[buyerB,product],'42501');
  await actor(seller,null);
  await db.query("update public.products set product_name='Own edit' where id=$1",[product]);
  assert.equal(Number((await one('with changed as (update public.products set product_name=$1 where id=$2 returning id) select count(*) as n from changed',['Forbidden',productB])).n),0);
  assert.equal(await count('public.orders'),0);
});
test('audit is not readable or writable by Admin, Buyer or guest',async()=>{
  await actor(admin,'admin');
  await rejected('select * from kidz_private.admin_audit',[],'42501');
  await rejected('insert into kidz_private.admin_audit(actor_id,action,target_id) values($1,$2,$3)',[admin,'fake',buyer],'42501');
});

test('privileged implementations are private; exposed wrappers are invokers with least privilege',async()=>{
  const wrappers=await db.query("select proname,prosecdef from pg_proc where pronamespace='public'::regnamespace and proname like 'admin_%'");
  assert.equal(wrappers.rows.length,3);
  assert.ok(wrappers.rows.every(row=>row.prosecdef===false));
  for(const signature of ['public.admin_preview_delete(text,uuid)','public.admin_delete_record(text,uuid,text,text)','public.admin_set_order_status(uuid,text,timestamptz)']) {
    assert.equal((await one("select has_function_privilege('anon',$1,'execute') as allowed",[signature])).allowed,false);
    assert.equal((await one("select has_function_privilege('authenticated',$1,'execute') as allowed",[signature])).allowed,true);
  }
  await actor(admin,'admin');
  await rejected('delete from auth.users where id=$1',[buyer],'42501');
});
test('nullable retained-order ownership cannot be abused by Buyer writes',async()=>{
  await actor(buyer,null);
  await rejected('insert into public.orders(id,user_id) values($1,null)',[id(99)],'42501');
  await rejected('insert into public.orders(id,user_id) values($1,$2)',[id(99),buyerB],'42501');
  await db.query('insert into public.orders(id,user_id) values($1,$2)',[id(99),buyer]);
  assert.equal(await count('public.orders'),2);
});
test('profile bootstrap and Seller own create/delete survive the new migration',async()=>{
  await db.query("insert into auth.users(id,email) values($1,'new-synthetic@example.test')",[id(90)]);
  assert.equal(await count('public.users',`id='${id(90)}'`),1);
  await actor(seller,null);
  await db.query("insert into public.products(id,seller_id,product_name) values($1,$2,'Own new product')",[id(91),id(31)]);
  await rejected('insert into public.products(id,seller_id,product_name) values($1,$2,$3)',[id(92),id(32),'Impersonated'],'42501');
  await db.query('delete from public.products where id=$1',[id(91)]);
  assert.equal(await count('public.products'),2);
});
test('an old deleted-Buyer token cannot read retained orders or recreate FK-owned data',async()=>{
  await actor(admin,'admin'); const p=await preview('user',buyer); await remove('user',buyer,p.token);
  await actor(buyer,null);
  assert.equal(await count('public.orders'),0); assert.equal(await count('public.users'),0);
  await rejected('insert into public.orders(id,user_id) values($1,$2)',[id(93),buyer],'23503');
});
test('Admin cannot turn scoped RPCs into unrelated table or SQL operations',async()=>{
  await actor(admin,'admin');
  for(const kind of ['order','seller','admin',"product; drop table public.orders"]) {
    await rejected('select public.admin_preview_delete($1,$2)',[kind,product],'22023');
  }
  assert.equal(await count('public.products'),2); assert.equal(await count('public.orders'),2);
});

let failed = 0;
try {
  await db.exec(await sql('tools/admin-db/bootstrap.sql'));
  for(const file of ['20260727000000_kidz_initial_schema.sql','20261106030934_admin_read_access.sql','20261106034711_admin_management.sql','20261106094017_seller_order_access.sql']) {
    await db.exec(await sql(`supabase/migrations/${file}`));
  }
  console.log('PASS: all four migrations loaded unchanged into isolated Postgres');
  for(const {name,run} of tests) {
    await db.exec('begin');
    try { await fixtures(); await run(); console.log(`PASS: ${name}`); }
    catch(error) { failed++; console.log(`FAIL: ${name}: ${error.code ?? ''} ${error.message}`); }
    finally { await db.exec('rollback'); }
  }
  console.log(`Isolated SQL scenarios: ${tests.length-failed} PASS, ${failed} FAIL`);
  console.log('UNVERIFIED: real GoTrue/Storage services, PostgREST transport and concurrent multi-connection races.');
} catch(error) {
  failed++; console.error(`FAIL: isolated database setup: ${error.code ?? ''} ${error.message}`);
} finally { await db.close(); }
process.exitCode = failed ? 1 : 0;

import {readFile} from 'node:fs/promises';
import assert from 'node:assert/strict';
import {PGlite} from '@electric-sql/pglite';
import {pgcrypto} from '@electric-sql/pglite/contrib/pgcrypto';
const db=await PGlite.create({extensions:{pgcrypto}});
const root=new URL('../../',import.meta.url);
const sql=async f=>readFile(new URL(f,root),'utf8');
const id=n=>`70000000-0000-4000-8000-${String(n).padStart(12,'0')}`;
const admin=id(1),buyer=id(2),buyerB=id(3),seller=id(4),sellerB=id(5),spoof=id(6);
const pa=id(11),pb=id(12),sa=id(31),sb=id(32);
const session=u=>u.replace('70000000','80000000');
const q=async(s,args=[]) => (await db.query(s,args)).rows;
const item=(pid,price=10,quantity=2)=>({product_id:pid,product_name:'Snapshot name',price,quantity,size:'M',color:'Blue',buyer_email:'must-not-leak@example.test',seller_id:sa});
async function actor(u,extra={}) {
 await db.exec('reset role');
 await db.query("select set_config('request.jwt.claims',$1,true)",[JSON.stringify({sub:u,role:'authenticated',session_id:session(u),exp:Math.floor(Date.now()/1000)+3600,app_metadata:u===admin?{role:'admin'}:{},...extra})]);
 await db.exec('set local role authenticated');
}
async function owner(){await db.exec('reset role');}
async function page(args={}) {
 return (await q('select public.seller_order_page($1,$2,$3,$4,$5) data',[args.start??null,args.end??null,args.date??null,args.id??null,args.limit??200]))[0].data.orders;
}
async function denied(statement,args=[],code='42501') {
 await db.exec('savepoint deny');let error;
 try {await q(statement,args);}catch(e){error=e;}
 await db.exec('rollback to savepoint deny; release savepoint deny');assert.equal(error?.code,code);
}
const tests=[];const test=(name,run)=>tests.push({name,run});
try {
 await db.exec(await sql('tools/admin-db/bootstrap.sql'));
 for(const f of ['20260727000000_kidz_initial_schema.sql','20261106030934_admin_read_access.sql','20261106034711_admin_management.sql'])await db.exec(await sql('supabase/migrations/'+f));
 for(const u of [admin,buyer,buyerB,seller,sellerB,spoof]) {
  await q('insert into auth.users(id,email,raw_app_meta_data,email_confirmed_at) values($1,$2,$3,now())',[u,'synthetic-'+u.slice(-2)+'@example.test',JSON.stringify(u===admin?{role:'admin'}:{})]);
  await q('insert into auth.sessions(id,user_id) values($1,$2)',[session(u),u]);
 }
 await q('insert into public.sellers(id,user_id) values($1,$2),($3,$4)',[sa,seller,sb,sellerB]);
 await q("insert into public.products(id,seller_id,product_name,product_price) values($1,$2,'Current price changed',999),($3,$4,'Other Seller',888)",[pa,sa,pb,sb]);
 const fixtures=[
  [21,buyer,[item(pa,0.10,2)],'2026-01-31T23:59:59.999999Z'],
  [22,buyerB,[item(pa,20,3),item(pb,50,7)],'2026-02-01T00:00:00Z'],
  [23,buyer,[item(pb)],'2026-01-15T00:00:00Z'],
  [24,buyer,JSON.stringify([item(pa,19.99,2)]),'2026-01-10T00:00:00Z'],
  [25,buyer,[item(id(99))],'2026-01-12T00:00:00Z'],
  [26,buyer,[item(pa),item(id(99))],'2026-01-13T00:00:00Z'],
 ];
 for(const [n,u,items,date] of fixtures)await q("insert into public.orders(id,user_id,order_items,total_price,delivery_address,order_date) values($1,$2,$3::jsonb,999,'PRIVATE CUSTOMER ADDRESS',$4)",[id(n),u,JSON.stringify(items),date]);
 await db.exec(await sql('supabase/migrations/20261106094017_seller_order_access.sql'));
 test('backfill decodes JSONB arrays and JSON strings; original order values unchanged',async()=>{
  await actor(seller);const rows=await page();assert.deepEqual(rows.map(r=>r.id),[22,21,26,24].map(id));
  assert.equal(rows.find(r=>r.id===id(24)).order_items[0].price_cents,1999);
  await owner();assert.equal((await q('select order_items,total_price,delivery_address from public.orders where id=$1',[id(21)]))[0].delivery_address,'PRIVATE CUSTOMER ADDRESS');
 });
 test('mixed order includes only caller items and no buyer, address, payment or other totals',async()=>{
  await actor(seller);const row=(await page()).find(r=>r.id===id(22));assert.equal(row.order_items.length,1);assert.equal(row.order_items[0].product_id,pa);
  assert.deepEqual(Object.keys(row).sort(),['id','order_date','status','updated_at','can_update_status','order_items'].sort());
  assert.equal(row.order_items[0].buyer_email,undefined);assert.equal(row.order_items[0]._seller_id,undefined);assert.equal(row.can_update_status,false);
  await actor(sellerB);const b=(await page()).find(r=>r.id===id(22));assert.equal(b.order_items.length,1);assert.equal(b.order_items[0].product_id,pb);
 });
 test('Buyer, guest and metadata spoofing cannot call Seller APIs',async()=>{
  for(const u of [buyer,spoof]){await actor(u,{user_metadata:{role:'seller',seller_id:sa},app_metadata:{role:'seller'}});await denied('select public.seller_order_page()');await denied('select public.seller_set_order_status($1,$2,now())',[id(21),'Shipping']);}
  await db.exec('reset role; set local role anon');await denied('select public.seller_order_page()');
 });
 test('registered Sellers still cannot select customer orders directly or read private snapshots',async()=>{
  await actor(seller);assert.equal((await q('select * from public.orders')).length,0);await denied('select * from kidz_private.seller_order_snapshots');
  await denied("select kidz_private.capture_seller_order(o) from public.orders o");
 });
 test('only wholly owned orders allow the three original status values',async()=>{
  await actor(seller);let row=(await page()).find(r=>r.id===id(21));assert.equal(row.can_update_status,true);
  for(const status of ['Shipping','Delivering','Packaging']){const r=(await q('select public.seller_set_order_status($1,$2,$3) data',[row.id,status,row.updated_at]))[0].data;assert.equal(r.status,status);row={...row,...r};}
  await denied('select public.seller_set_order_status($1,$2,$3)',[row.id,'Refunded',row.updated_at],'22023');
 });
 test('both Sellers are refused mixed-order changes; unrelated and unknown IDs use the same denial',async()=>{
  for(const u of [seller,sellerB]){await actor(u);await denied('select public.seller_set_order_status($1,$2,now())',[id(22),'Shipping']);}
  await actor(sellerB);for(const n of [21,98])await denied('select public.seller_set_order_status($1,$2,now())',[id(n),'Shipping']);
 });
 test('unknown historical product ownership is never trusted; mixed unknown lines prevent writes',async()=>{
  await actor(seller);assert.equal((await page()).some(r=>r.id===id(25)),false);assert.equal((await page()).find(r=>r.id===id(26)).can_update_status,false);
  await denied('select public.seller_set_order_status($1,$2,now())',[id(26),'Shipping']);
 });
 test('stale updates and changed order JSON fail with conflict',async()=>{
  await actor(seller);await denied('select public.seller_set_order_status($1,$2,$3)',[id(21),'Shipping','2000-01-01'],'PT409');
  await actor(buyer);await q("update public.orders set order_items='[]' where id=$1",[id(21)]);
  await actor(seller);const row=(await page()).find(r=>r.id===id(21));assert.equal(row.order_items.length,1);assert.equal(row.can_update_status,false);
  await denied('select public.seller_set_order_status($1,$2,$3)',[row.id,'Shipping',row.updated_at],'PT409');
 });
 test('date filtering is half-open and cursor pagination loses no tied-date rows',async()=>{
  await owner();await q('insert into public.orders(id,user_id,order_items,order_date) values($1,$2,$3::jsonb,$4)',[id(27),buyer,JSON.stringify([item(pa)]),'2026-01-13T00:00:00Z']);
  await actor(seller);const jan=await page({start:'2026-01-01Z',end:'2026-02-01Z'});assert(jan.some(r=>r.id===id(21)));assert(!jan.some(r=>r.id===id(22)));
  const all=await page();let rows=[],cursor={};while(true){const next=await page({...cursor,limit:2});rows.push(...next);if(next.length<2)break;cursor={date:next.at(-1).order_date,id:next.at(-1).id};}assert.deepEqual(rows,all);
 });
 test('product deletion and recreation by a different Seller do not reassign historical sales',async()=>{
  await owner();await q('delete from public.products where id=$1',[pa]);await q("insert into public.products(id,seller_id,product_name) values($1,$2,'Reused ID')",[pa,sb]);
  await actor(seller);assert.equal((await page()).find(r=>r.id===id(24)).order_items[0].price_cents,1999);
  await actor(sellerB);assert(!(await page()).some(r=>r.id===id(21)));
 });
 test('reclaiming a deleted Seller registration ID cannot steal historical order items',async()=>{
  await owner();await q('delete from public.sellers where id in ($1,$2)',[sa,sb]);
  await q('insert into public.sellers(id,user_id) values($1,$2)',[sa,sellerB]);
  await actor(sellerB);const rows=await page();assert(!rows.some(r=>r.id===id(21)));
  assert.equal(rows.find(r=>r.id===id(22)).order_items[0].product_id,pb);
 });
 test('new orders capture ownership on INSERT; raw source and private records stay immutable on edits',async()=>{
  await actor(buyer);await q('insert into public.orders(id,user_id,order_items) values($1,$2,$3::jsonb)',[id(28),buyer,JSON.stringify([item(pa,12.34,3)])]);
  await actor(seller);assert.equal((await page()).find(r=>r.id===id(28)).order_items[0].price_cents,1234);
 });
 test('invalid snapshot prices are exposed as incomplete, never replaced by current catalogue price',async()=>{
  await actor(buyer);await q('insert into public.orders(id,user_id,order_items) values($1,$2,$3::jsonb)',[id(29),buyer,JSON.stringify([item(pa,null)])]);
  await actor(seller);assert.equal((await page()).find(r=>r.id===id(29)).order_items[0].price_cents,null);
 });
 test('oversized pages and incomplete cursor parameters are rejected',async()=>{
  await actor(seller);await denied('select public.seller_order_page(null,null,null,null,201)',[],'22023');
  await denied('select public.seller_order_page(null,null,now(),null,200)',[],'22023');
 });
 test('Buyer history/isolation and highest Admin authority remain unchanged',async()=>{
  await actor(buyer);assert.equal((await q('select * from public.orders')).length,5);
  await actor(buyerB);assert.equal((await q('select * from public.orders')).length,1);
  await actor(admin);const row=(await q('select id,updated_at from public.orders where id=$1',[id(22)]))[0];assert.equal((await q('select * from public.orders')).length,6);
  assert.equal((await q('select public.admin_set_order_status($1,$2,$3) data',[row.id,'Shipping',row.updated_at]))[0].data.status,'Shipping');
 });
 for(const mode of ['expired','logout','seller-removed','unconfirmed','banned'])test(mode+' authorization is rejected',async()=>{
  await owner();if(mode==='logout')await q('delete from auth.sessions where user_id=$1',[seller]);if(mode==='seller-removed')await q('delete from public.sellers where id=$1',[sa]);if(mode==='unconfirmed')await q('update auth.users set email_confirmed_at=null where id=$1',[seller]);if(mode==='banned')await q("update auth.users set banned_until=now()+interval '1 day' where id=$1",[seller]);
  await actor(seller,mode==='expired'?{exp:1}:{});await denied('select public.seller_order_page()');
 });
 let failed=0;
 for(const t of tests){await db.exec('begin');try{await t.run();console.log('PASS: '+t.name);}catch(e){failed++;console.log('FAIL: '+t.name+': '+e.message);}finally{await db.exec('rollback');}}
 console.log(`Seller SQL scenarios: ${tests.length-failed} PASS, ${failed} FAIL`);process.exitCode=failed?1:0;
}finally{await db.close();}

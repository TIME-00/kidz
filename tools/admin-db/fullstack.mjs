import { readFile, realpath } from 'node:fs/promises';
import { execFileSync } from 'node:child_process';
import { randomUUID } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

// Deliberately no URL/key arguments or environment fallbacks. Refuse anything
// except our generated, unlinked, project-local loopback test stack.
const root = fileURLToPath(new URL('../../', import.meta.url));
const work = await realpath((await readFile(new URL('../../.dart_tool/kidz_admin_stack_location.txt', import.meta.url),'utf8')).trim());
if(!work.startsWith(path.join(root,'.dart_tool')+path.sep)) throw Error('Refusing non-test work directory');
const configText=await readFile(path.join(work,'supabase','config.toml'),'utf8');
if(!/^project_id = "kidz_admin_verify_[0-9a-f]{8}"$/m.test(configText)) throw Error('Refusing unexpected project ID');
try { await readFile(path.join(work,'supabase','.temp','project-ref')); throw Error('Refusing a linked project'); }
catch(error) { if(error.code!=='ENOENT') throw error; }
let settings;
try {
  const captured=execFileSync('supabase.exe',['status','--workdir',work,'--output','json'],
    {encoding:'utf8',stdio:['ignore','pipe','pipe']});
  settings=JSON.parse(captured);
} catch {
  throw Error('Unable to read isolated local stack status; private details suppressed.');
}
const base=new URL(settings.API_URL);
if(base.protocol!=='http:' || base.hostname!=='127.0.0.1' || base.port!=='55321') throw Error('Refusing non-isolated API URL');
const anon=settings.ANON_KEY, server=settings.SERVICE_ROLE_KEY;
if(!anon || !server) throw Error('Local stack credentials unavailable');
const password='synthetic-isolated-test-password';
let passed=0;
function check(value,label) {
  if(!value) throw Error(`Check failed: ${label}`);
  passed++; console.log(`PASS: ${label}`);
}
async function request(route,{method='GET',token=anon,key=anon,body,headers={}}={}) {
  const response=await fetch(new URL(route,base),{method,signal:AbortSignal.timeout(20000),headers:{apikey:key,Authorization:`Bearer ${token}`,
    ...(body ? {'Content-Type':'application/json'}:{}),...headers},body:body?JSON.stringify(body):undefined});
  const text=await response.text(); let data;
  try { data=JSON.parse(text); } catch { data=null; }
  return {status:response.status,data};
}
async function success(route,options,label) {
  const result=await request(route,options);
  if(result.status<200 || result.status>=300) throw Error(`${label}: HTTP ${result.status} / code ${result.data?.code ?? 'unavailable'}`);
  return result.data;
}
async function account(name,role) {
  const email=`kidz-${name}-${randomUUID()}@example.test`;
  const user=await success('/auth/v1/admin/users',{method:'POST',key:server,token:server,
    body:{email,password,email_confirm:true,app_metadata:role?{role}:{}}},'Create isolated fixture');
  const login=await success('/auth/v1/token?grant_type=password',{method:'POST',body:{email,password}},'Sign in isolated fixture');
  return {id:user.id,email,token:login.access_token,refresh:login.refresh_token};
}
async function rpc(name,params,token) {
  return request(`/rest/v1/rpc/${name}`,{method:'POST',token,body:params});
}
async function okRpc(name,params,token,label) {
  const result=await rpc(name,params,token);
  if(result.status!==200) throw Error(`${label}: HTTP ${result.status} / code ${result.data?.code ?? 'unavailable'}`);
  return result.data;
}
async function list(table,token,query='select=*') {
  return success(`/rest/v1/${table}?${query}`,{token},`Read ${table}`);
}
async function insert(table,body,token) {
  return (await success(`/rest/v1/${table}`,{method:'POST',token,body,
    headers:{Prefer:'return=representation'}},`Insert ${table}`))[0];
}
async function remove(kind,id,admin) {
  const preview=await okRpc('admin_preview_delete',{p_kind:kind,p_id:id},admin.token,'Preview deletion');
  const result=await okRpc('admin_delete_record',{p_kind:kind,p_id:id,p_token:preview.token,p_confirmation:'DELETE'},admin.token,'Delete confirmed record');
  check(result.deleted===true && result.id===id,`real ${kind} deletion confirms the exact target`);
  return preview;
}
try {
  const admin=await account('admin','admin');
  const buyer=await account('buyer');
  const seller=await account('seller');
  const other=await account('other');
  check((await list('users',admin.token,'select=id')).length===4,'Admin sees every fixture profile through actual REST/RLS');
  check((await list('users',buyer.token,'select=id')).length===1,'Buyer sees only own profile through REST');
  check((await list('users',seller.token,'select=id')).length===1,'Seller sees only own profile through REST');
  const signupEmail=`kidz-signup-${randomUUID()}@example.test`;
  const signup=await success('/auth/v1/signup',{method:'POST',body:{email:signupEmail,password}},'Normal Buyer signup');
  check(Boolean(signup.user?.id ?? signup.id),'normal Auth registration still creates a Buyer');
  const ownSeller=await insert('sellers',{user_id:seller.id,company_name:'Synthetic seller'},seller.token);
  const otherSeller=await insert('sellers',{user_id:other.id,company_name:'Synthetic other seller'},other.token);
  check(Boolean(ownSeller.id && otherSeller.id),'normal Seller self-registration works');
  const imagePath=`products/${randomUUID()}.png`;
  const imageURL=new URL(`/storage/v1/object/public/product-images/${imagePath}`,base).toString();
  const image=Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aD1sAAAAASUVORK5CYII=','base64');
  const upload=await fetch(new URL(`/storage/v1/object/product-images/${imagePath}`,base),{method:'POST',
    headers:{apikey:anon,Authorization:`Bearer ${seller.token}`,'Content-Type':'image/png'},body:image});
  check(upload.ok,'Seller upload passes actual Storage RLS');
  const product=await insert('products',{seller_id:ownSeller.id,product_name:'Synthetic A',product_price:12,product_images:[imageURL]},seller.token);
  await insert('products',{seller_id:ownSeller.id,product_name:'Synthetic A2',product_price:13,product_images:[imageURL]},seller.token);
  const otherProduct=await insert('products',{seller_id:otherSeller.id,product_name:'Synthetic B',product_price:20},other.token);
  await insert('cart',{user_id:buyer.id,product_id:product.id,quantity:1},buyer.token);
  await insert('bankingcard',{user_id:buyer.id,cardholdername:'Synthetic',cardnumber:'synthetic'},buyer.token);
  const items=JSON.stringify([{product_id:product.id,product_name:'Synthetic A',product_images:[imageURL],price:12,quantity:1}]);
  const order=await insert('orders',{id:randomUUID(),user_id:buyer.id,total_price:12,status:'Packaging',order_items:items},buyer.token);
  // New Seller scope regression cases use only this unlinked synthetic project.
  const salesBuyer=await account('sales-buyer');
  const exclusive=await insert('orders',{id:randomUUID(),user_id:salesBuyer.id,
    order_items:[{product_id:product.id,product_name:'Historical A',price:12,quantity:2}],
    total_price:24,delivery_address:'PRIVATE CUSTOMER ADDRESS'},salesBuyer.token);
  const mixed=await insert('orders',{id:randomUUID(),user_id:salesBuyer.id,
    order_items:JSON.stringify([{product_id:product.id,product_name:'Historical A',price:10,quantity:2},
      {product_id:otherProduct.id,product_name:'Historical B',price:20,quantity:3}]),
    total_price:80,delivery_address:'PRIVATE CUSTOMER ADDRESS'},salesBuyer.token);
  const sellerRows=(await okRpc('seller_order_page',{},seller.token,'Seller order projection')).orders;
  const sellerMixed=sellerRows.find(o=>o.id===mixed.id);
  check(sellerMixed?.order_items.length===1 && sellerMixed.order_items[0].product_id===product.id,
    'Seller A sees only their items in a real mixed order RPC');
  check(!('user_id' in sellerMixed) && !('delivery_address' in sellerMixed) && !('total_price' in sellerMixed),
    'Seller projection excludes private customer fields and unrelated totals');
  const otherRows=(await okRpc('seller_order_page',{},other.token,'Other Seller projection')).orders;
  check(!otherRows.some(o=>o.id===exclusive.id) && otherRows.find(o=>o.id===mixed.id)?.order_items[0].product_id===otherProduct.id,
    'Seller B is isolated from Seller A exclusive order and items');
  for(const token of [anon,buyer.token])check([401,403].includes((await rpc('seller_order_page',{},token)).status),
    'guest or Buyer cannot invoke Seller projection');
  const sellerChanged=await okRpc('seller_set_order_status',{p_id:exclusive.id,p_status:'Shipping',p_expected_updated_at:exclusive.updated_at},seller.token,'Seller exclusive status');
  check(sellerChanged.status==='Shipping','Seller updates wholly owned order through real RPC');
  for(const token of [seller.token,other.token])check((await rpc('seller_set_order_status',
    {p_id:mixed.id,p_status:'Shipping',p_expected_updated_at:mixed.updated_at},token)).status===403,
    'both Sellers are denied changing a shared mixed-order status');
  check((await rpc('seller_set_order_status',{p_id:exclusive.id,p_status:'Delivering',p_expected_updated_at:exclusive.updated_at},seller.token)).status===409,
    'Seller stale status update is an explicit HTTP conflict');
  const sellerConcurrent=await Promise.all(['Packaging','Delivering'].map(p_status=>rpc('seller_set_order_status',
    {p_id:exclusive.id,p_status,p_expected_updated_at:sellerChanged.updated_at},seller.token)));
  check(sellerConcurrent.filter(r=>r.status===200).length===1 && sellerConcurrent.filter(r=>r.status===409).length===1,
    'concurrent Seller status requests allow one update only');
  await success(`/rest/v1/products?id=eq.${product.id}`,{method:'PATCH',token:seller.token,body:{product_price:999}},'Change current catalogue price');
  check((await okRpc('seller_order_page',{},seller.token,'Historic price')).orders.find(o=>o.id===exclusive.id).order_items[0].price_cents===1200,
    'actual purchase snapshot price survives catalogue price changes');
  check((await list('orders',seller.token,'select=id')).length===0,'Seller cannot see Buyer order history');
  for(const [name,token] of [['Buyer',buyer.token],['Seller',seller.token],['Guest',anon]]) {
    const result=await rpc('admin_preview_delete',{p_kind:'product',p_id:product.id},token);
    check([401,403].includes(result.status),`${name} cannot invoke the Admin API directly`);
  }
  await success('/auth/v1/user',{method:'PUT',token:buyer.token,body:{data:{role:'admin'}}},'Spoof user metadata');
  const spoofedSession=await success('/auth/v1/token?grant_type=refresh_token',
    {method:'POST',body:{refresh_token:buyer.refresh}},'Refresh spoofed metadata fixture');
  buyer.token=spoofedSession.access_token; buyer.refresh=spoofedSession.refresh_token;
  check((await rpc('admin_preview_delete',{p_kind:'product',p_id:product.id},buyer.token)).status===403,'editable user metadata cannot grant Admin');
  check((await rpc('admin_preview_delete',{p_kind:'user',p_id:admin.id},admin.token)).status===403,'self/last Admin deletion is rejected');
  const changed=await okRpc('admin_set_order_status',{p_id:order.id,p_status:'Shipping',p_expected_updated_at:order.updated_at},admin.token,'Order status');
  check(changed.status==='Shipping','Admin changes another Buyer order status through actual RPC');
  const stale=await rpc('admin_set_order_status',{p_id:order.id,p_status:'Delivering',p_expected_updated_at:order.updated_at},admin.token);
  check(stale.status===409 && stale.data?.code==='PT409','stale HTTP updates are rejected with conflict');
  const concurrent=await Promise.all(['Packaging','Delivering'].map(p_status=>rpc('admin_set_order_status',
    {p_id:order.id,p_status,p_expected_updated_at:changed.updated_at},admin.token)));
  check(concurrent.filter(r=>r.status===200).length===1 && concurrent.filter(r=>r.status===409).length===1,
    'simultaneous status requests allow one update and reject the stale contender');
  const productPreview=await remove('product',product.id,admin);
  check(Number(productPreview.cart_rows_deleted)===1 && (await list('cart',buyer.token,'select=id')).length===0,
    'product deletion discloses and removes cart references');
  check((await list('orders',admin.token,`select=order_items&id=eq.${order.id}`))[0].order_items===items,'historical order items remain unchanged');
  const beforeImage=await fetch(imageURL);
  check(beforeImage.ok && Buffer.from(await beforeImage.arrayBuffer()).equals(image),'actual image bytes survive product deletion');
  check((await okRpc('seller_order_page',{},seller.token,'Deleted product history')).orders.some(o=>o.id===exclusive.id),
    'Seller history survives actual product deletion');
  const buyerPreview=await remove('user',buyer.id,admin);
  check(Number(buyerPreview.orders_retained)===1 && Number(buyerPreview.cards_deleted)===1,'account preview discloses retained orders and private card cleanup');
  check((await request(`/auth/v1/admin/users/${buyer.id}`,{key:server,token:server})).status===404,'real GoTrue no longer finds the deleted Auth account');
  const rejectedLogin=await request('/auth/v1/token?grant_type=password',{method:'POST',body:{email:buyer.email,password}});
  check(rejectedLogin.status===400,'deleted account can no longer sign in');
  const rejectedRefresh=await request('/auth/v1/token?grant_type=refresh_token',{method:'POST',body:{refresh_token:buyer.refresh}});
  check(rejectedRefresh.status===400,'deleted account refresh tokens cannot obtain a new session');
  const retained=(await list('orders',admin.token,`select=id,user_id,total_price,order_items&id=eq.${order.id}`))[0];
  check(retained.user_id===null && Number(retained.total_price)===12 && retained.order_items===items,'order history survives the actual Auth FK deletion');
  const oldBuyer=await request('/rest/v1/orders?select=id',{token:buyer.token});
  check(oldBuyer.status===401 || (oldBuyer.status===200 && oldBuyer.data.length===0),'deleted Buyer old token cannot read retained orders');
  const sellerPreview=await remove('user',seller.id,admin);
  check(Number(sellerPreview.products_deleted)===1 && Number(sellerPreview.images_retained)===1,'seller deletion handles remaining products and retained images');
  check([401,403].includes((await rpc('seller_order_page',{},seller.token)).status),
    'deleted Seller account cannot use an already-issued token on Seller RPCs');
  const afterImage=await fetch(imageURL);
  check(afterImage.ok && Buffer.from(await afterImage.arrayBuffer()).equals(image),'actual image bytes survive deleted-owner reassignment');
  check((await list('products',other.token,'select=id')).some(p=>p.id===otherProduct.id),'other Seller product is unaffected');
  const deletePreview=await okRpc('admin_preview_delete',{p_kind:'product',p_id:otherProduct.id},admin.token,'Concurrent deletion preview');
  const deletions=await Promise.all([0,1].map(()=>rpc('admin_delete_record',
    {p_kind:'product',p_id:otherProduct.id,p_token:deletePreview.token,p_confirmation:'DELETE'},admin.token)));
  check(deletions.filter(r=>r.status===200).length===1 && deletions.filter(r=>[404,409].includes(r.status)).length===1,
    `simultaneous deletions remove exactly one target once (${deletions.map(r=>r.status+'/'+(r.data?.code??'ok')).join(', ')})`);
  await success(`/auth/v1/admin/users/${admin.id}`,{method:'PUT',key:server,token:server,body:{app_metadata:{role:'buyer'}}},'Demote isolated Admin');
  check((await rpc('admin_preview_delete',{p_kind:'user',p_id:other.id},admin.token)).status===403,'live role removal denies the already-issued Admin token');
  check((await list('users',admin.token,'select=id')).length===1,'demoted Admin loses global profile reads immediately');
  await success(`/auth/v1/admin/users/${admin.id}`,{method:'PUT',key:server,token:server,body:{app_metadata:{role:'admin'}}},'Restore isolated test role');
  await success('/auth/v1/logout?scope=local',{method:'POST',token:admin.token},'Logout isolated Admin');
  check((await rpc('admin_preview_delete',{p_kind:'user',p_id:other.id},admin.token)).status===403,'logout denies API use with the old signed token');
  console.log(`Full local Supabase checks: ${passed} PASS, 0 FAIL`);
} catch(error) {
  // Fixed test descriptions/statuses only. Never dump requests/config/tokens.
  console.error(`FAIL: ${error.message}`); process.exitCode=1;
}

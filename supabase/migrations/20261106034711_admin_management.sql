-- Phase 2: restore only historically evidenced management actions.
-- No broad Admin write policies, client secrets, generic SQL, or deployments.
create schema if not exists kidz_private;
revoke all on schema kidz_private from public, anon;
grant usage on schema kidz_private to authenticated;

create table kidz_private.admin_audit (
  id bigint generated always as identity primary key,
  actor_id uuid not null, action text not null, target_id uuid not null,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
alter table kidz_private.admin_audit enable row level security;
revoke all on kidz_private.admin_audit from public, anon, authenticated;
revoke all on sequence kidz_private.admin_audit_id_seq from public, anon, authenticated;

-- Order history must survive an explicitly confirmed account deletion.
-- Owner predicates remain unchanged, so NULL-owned history is Admin-only.
alter table public.orders alter column user_id drop not null;
alter table public.orders drop constraint orders_user_id_fkey;
alter table public.orders add constraint orders_user_id_fkey
  foreign key (user_id) references auth.users(id) on delete set null;

-- Signed claims alone cannot outlive role demotion, logout, or account deletion.
create function kidz_private.is_admin() returns boolean
language plpgsql stable security definer set search_path = '' as $$
declare claims jsonb := auth.jwt();
begin
  if auth.uid() is null or claims->'app_metadata'->>'role' is distinct from 'admin'
    or claims->>'session_id' is null or claims->>'exp' is null then return false; end if;
  return (claims->>'exp')::bigint > extract(epoch from now())
    and exists (
      select 1 from auth.users u join auth.sessions s on s.user_id = u.id
      where u.id = auth.uid() and s.id = (claims->>'session_id')::uuid
        and u.raw_app_meta_data->>'role' = 'admin'
        and u.deleted_at is null and u.email_confirmed_at is not null
        and (u.banned_until is null or u.banned_until <= now())
        and (s.not_after is null or s.not_after > now())
    );
exception when invalid_text_representation or numeric_value_out_of_range then
  return false;
end;
$$;
revoke all on function kidz_private.is_admin() from public, anon, authenticated, service_role;
grant execute on function kidz_private.is_admin() to authenticated;

create function kidz_private.require_admin() returns uuid
language plpgsql security definer set search_path = '' as $$
begin
  if not kidz_private.is_admin() then
    raise exception using errcode='42501', message='Admin authorization required.';
  end if;
  -- Hold current identity/session stable until this short transaction commits.
  perform 1 from auth.users where id=auth.uid() for share;
  perform 1 from auth.sessions where id=(auth.jwt()->>'session_id')::uuid for share;
  if not kidz_private.is_admin() then
    raise exception using errcode='42501', message='Admin authorization required.';
  end if;
  return auth.uid();
end;
$$;
revoke all on function kidz_private.require_admin() from public, anon, authenticated, service_role;

alter policy "users: admin read" on public.users using ((select kidz_private.is_admin()));
alter policy "sellers: admin read" on public.sellers using ((select kidz_private.is_admin()));
alter policy "orders: admin read" on public.orders using ((select kidz_private.is_admin()));

create function kidz_private.preview_delete(p_kind text, p_id uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare result jsonb; target public.users%rowtype; product public.products%rowtype;
begin
  perform kidz_private.require_admin();
  if p_kind = 'product' then
    select * into product from public.products where id=p_id;
    if not found then raise exception using errcode='PT404', message='Product no longer exists.'; end if;
    result := jsonb_build_object('kind',p_kind,'id',p_id,'label',product.product_name,
      'version',product.updated_at,'products_deleted',1,
      'cart_rows_deleted',(select count(*) from public.cart where product_id=p_id),
      'orders_retained',true,'images_retained',true);
  elsif p_kind = 'user' then
    select * into target from public.users where id=p_id;
    if not found then raise exception using errcode='PT404', message='User no longer exists.'; end if;
    if p_id=auth.uid() or exists(select 1 from auth.users
      where id=p_id and raw_app_meta_data->>'role'='admin') then
      raise exception using errcode='42501', message='Admin accounts cannot be deleted from Manage Users.';
    end if;
    -- App management must not destroy unrelated buckets or bucket ownership.
    if exists(select 1 from storage.objects where (owner_id=p_id::text or owner=p_id)
        and bucket_id <> 'product-images')
      or exists(select 1 from storage.buckets where owner=p_id or owner_id=p_id::text) then
      raise exception using errcode='23514', message='Account owns storage outside the supported product-images scope.';
    end if;
    result := jsonb_build_object('kind',p_kind,'id',p_id,'label',target.email,
      'version',target.updated_at,
      'sellers_deleted',(select count(*) from public.sellers where user_id=p_id),
      'products_deleted',(select count(*) from public.products p join public.sellers s on s.id=p.seller_id where s.user_id=p_id),
      'cart_rows_deleted',(select count(*) from public.cart c where c.user_id=p_id or c.product_id in
        (select p.id from public.products p join public.sellers s on s.id=p.seller_id where s.user_id=p_id)),
      'cards_deleted',(select count(*) from public.bankingcard where user_id=p_id),
      'orders_retained',(select count(*) from public.orders where user_id=p_id),
      'images_retained',(select count(*) from storage.objects where bucket_id='product-images' and (owner_id=p_id::text or owner=p_id)),
      'product_versions',(select coalesce(jsonb_agg(jsonb_build_array(p.id,p.updated_at) order by p.id),'[]'::jsonb)
        from public.products p join public.sellers s on s.id=p.seller_id where s.user_id=p_id));
  else raise exception using errcode='22023', message='Unsupported deletion type.';
  end if;
  return (result - 'product_versions') || jsonb_build_object('token',md5(result::text));
end;
$$;
revoke all on function kidz_private.preview_delete(text,uuid) from public, anon, authenticated, service_role;
grant execute on function kidz_private.preview_delete(text,uuid) to authenticated;

create function kidz_private.delete_record(p_kind text, p_id uuid, p_token text, p_confirmation text) returns jsonb
language plpgsql security definer set search_path = '' set lock_timeout='5s' set statement_timeout='15s' as $$
declare actor uuid; preview jsonb;
begin
  actor := kidz_private.require_admin();
  -- Avoid competing Admin transactions upgrading application-table locks.
  -- Refuse contention rather than retrying a destructive request implicitly.
  if not pg_try_advisory_xact_lock(hashtextextended('kidz.admin.management',0)) then
    raise exception using errcode='PT409', message='Another Admin action is in progress. Refresh and try again.';
  end if;
  if p_confirmation is distinct from 'DELETE' then
    raise exception using errcode='22023', message='Type DELETE to confirm.';
  end if;
  -- Uniform lock order also coordinates ordinary Buyer/Seller writes. There are
  -- no HTTP calls, password operations, or user interaction inside the transaction.
  lock table public.users, public.sellers, public.products, public.cart,
    public.orders, public.bankingcard, storage.objects in share row exclusive mode;
  if p_kind='user' then
    perform 1 from auth.users where id=p_id for update;
  end if;
  preview := kidz_private.preview_delete(p_kind,p_id);
  if p_token is null or preview->>'token' is distinct from p_token then
    raise exception using errcode='PT409', message='Deletion effects changed. Preview and confirm again.';
  end if;
  if p_kind='product' then
    delete from public.products where id=p_id;
  elsif p_kind='user' then
    -- Retain physical objects and stable URLs, including shared/order images.
    -- Reassign only this app bucket's ownership metadata before Auth deletion.
    -- Both fields exist in the supported Supabase Storage schema; owner is legacy.
    update storage.objects set owner_id=actor::text, owner=actor
      where bucket_id='product-images' and (owner_id=p_id::text or owner=p_id);
    -- Direct server-side Auth deletion is atomic with business FK handling.
    -- Auth identities/sessions and profile/cart/cards/seller/products cascade;
    -- orders are retained by SET NULL. A failure rolls back EVERYTHING.
    -- Legacy refresh tokens may have no session FK; pending PKCE/recovery
    -- flow_state rows also have no user FK in the supported managed schema.
    delete from auth.refresh_tokens where user_id=p_id::text;
    delete from auth.flow_state where user_id=p_id;
    delete from auth.users where id=p_id;
    if not found then raise exception using errcode='PT404', message='Auth account no longer exists.'; end if;
  else raise exception using errcode='22023', message='Unsupported deletion type.';
  end if;
  insert into kidz_private.admin_audit(actor_id,action,target_id,details)
    values(actor,'delete_'||p_kind,p_id,preview - 'label' - 'token');
  return jsonb_build_object('deleted',true,'kind',p_kind,'id',p_id);
end;
$$;
revoke all on function kidz_private.delete_record(text,uuid,text,text) from public, anon, authenticated, service_role;
grant execute on function kidz_private.delete_record(text,uuid,text,text) to authenticated;

create function kidz_private.set_order_status(p_id uuid,p_status text,p_expected_updated_at timestamptz) returns jsonb
language plpgsql security definer set search_path = '' set lock_timeout='5s' as $$
declare actor uuid; previous public.orders%rowtype; changed public.orders%rowtype;
begin
  actor := kidz_private.require_admin();
  -- Avoid competing Admin transactions upgrading application-table locks.
  -- Refuse contention rather than retrying a destructive request implicitly.
  if not pg_try_advisory_xact_lock(hashtextextended('kidz.admin.management',0)) then
    raise exception using errcode='PT409', message='Another Admin action is in progress. Refresh and try again.';
  end if;
  if p_status is null or p_status not in ('Packaging','Shipping','Delivering') then
    raise exception using errcode='22023', message='Unsupported order status.';
  end if;
  select * into previous from public.orders where id=p_id for update;
  if not found then raise exception using errcode='PT404', message='Order no longer exists.'; end if;
  if p_expected_updated_at is null or previous.updated_at is distinct from p_expected_updated_at then
    raise exception using errcode='PT409', message='Order changed. Refresh and try again.';
  end if;
  -- Original Admin could select any of the three statuses, including corrections
  -- backwards. Preserve that business behavior; never accept arbitrary columns.
  update public.orders set status=p_status where id=p_id returning * into changed;
  insert into kidz_private.admin_audit(actor_id,action,target_id,details) values
    (actor,'set_order_status',p_id,jsonb_build_object('from',previous.status,'to',p_status));
  return jsonb_build_object('id',changed.id,'status',changed.status,'updated_at',changed.updated_at);
end;
$$;
revoke all on function kidz_private.set_order_status(uuid,text,timestamptz) from public, anon, authenticated, service_role;
grant execute on function kidz_private.set_order_status(uuid,text,timestamptz) to authenticated;

-- Exposed wrappers deliberately use INVOKER; privileged bodies remain private.
create function public.admin_preview_delete(p_kind text,p_id uuid) returns jsonb
language sql security invoker set search_path='' as $$
  select kidz_private.preview_delete(p_kind,p_id);
$$;
create function public.admin_delete_record(p_kind text,p_id uuid,p_token text,p_confirmation text) returns jsonb
language sql security invoker set search_path='' as $$
  select kidz_private.delete_record(p_kind,p_id,p_token,p_confirmation);
$$;
create function public.admin_set_order_status(p_id uuid,p_status text,p_expected_updated_at timestamptz) returns jsonb
language sql security invoker set search_path='' as $$
  select kidz_private.set_order_status(p_id,p_status,p_expected_updated_at);
$$;
revoke all on function public.admin_preview_delete(text,uuid) from public,anon,authenticated,service_role;
revoke all on function public.admin_delete_record(text,uuid,text,text) from public,anon,authenticated,service_role;
revoke all on function public.admin_set_order_status(uuid,text,timestamptz) from public,anon,authenticated,service_role;
grant execute on function public.admin_preview_delete(text,uuid) to authenticated;
grant execute on function public.admin_delete_record(text,uuid,text,text) to authenticated;
grant execute on function public.admin_set_order_status(uuid,text,timestamptz) to authenticated;

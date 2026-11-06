-- Seller projections only: no new orders SELECT/UPDATE policy or status column.
-- Private attribution is captured by the server, never accepted from metadata.
-- Bind it to the Auth identity as well as recording the Seller registration;
-- recycling a deleted sellers.id must never transfer historical sales.
create table kidz_private.seller_order_snapshots (
  order_id uuid primary key references public.orders(id) on delete cascade,
  order_date timestamptz not null,
  source_items jsonb not null,
  items jsonb not null,
  owner_ids uuid[] not null,
  source_valid boolean not null
);
alter table kidz_private.seller_order_snapshots enable row level security;
revoke all on kidz_private.seller_order_snapshots from public, anon, authenticated, service_role;
create index seller_order_snapshot_owners on kidz_private.seller_order_snapshots using gin(owner_ids);
create index seller_order_snapshot_date on kidz_private.seller_order_snapshots(order_date desc,order_id desc);

create function kidz_private.order_item_array(raw jsonb) returns jsonb
language plpgsql immutable set search_path='' as $$
declare result jsonb := raw;
begin
  if jsonb_typeof(result)='string' then result := (result #>> '{}')::jsonb; end if;
  if jsonb_typeof(result)='array' then return result; end if;
  return null;
exception when invalid_text_representation then return null;
end;
$$;
revoke all on function kidz_private.order_item_array(jsonb) from public,anon,authenticated,service_role;

create function kidz_private.capture_seller_order(o public.orders) returns void
language plpgsql security definer set search_path='' as $$
declare source jsonb := kidz_private.order_item_array(o.order_items);
  item jsonb; result jsonb := '[]'; owners uuid[] := '{}';
  product record; cents bigint; quantity integer;
begin
  for item in select value from jsonb_array_elements(coalesce(source,'[]')) loop
    -- Join by the canonical product ID. Buyer-supplied seller/user IDs are ignored.
    select p.id,s.id seller_id,s.user_id into product
      from public.products p join public.sellers s on s.id=p.seller_id
      where p.id::text=lower(item->>'product_id') for key share of p,s;
    cents := null; quantity := null;
    if coalesce(item->>'price',item->>'product_price','') ~ '^(0|[1-9][0-9]{0,7})(\.[0-9]{1,2})?$' then
      cents := (coalesce(item->>'price',item->>'product_price')::numeric*100)::bigint;
    end if;
    if coalesce(item->>'quantity','') ~ '^[1-9][0-9]{0,5}(\.0+)?$' then
      quantity := (item->>'quantity')::numeric::integer;
    end if;
    result := result || jsonb_build_array(jsonb_build_object(
      '_seller_id',product.seller_id,'_seller_user_id',product.user_id,'product_id',item->>'product_id',
      'product_name',coalesce(item->>'product_name','Unknown Product'),
      'price_cents',cents,'quantity',quantity,'product_image',item->>'product_image',
      'size',item->>'size','color',item->>'color'));
    if product.seller_id is not null and not product.user_id=any(owners) then
      owners := array_append(owners,product.user_id);
    end if;
  end loop;
  insert into kidz_private.seller_order_snapshots
    values(o.id,o.order_date,coalesce(source,'null'::jsonb),result,owners,source is not null)
    on conflict(order_id) do nothing;
end;
$$;
revoke all on function kidz_private.capture_seller_order(public.orders) from public,anon,authenticated,service_role;

create function kidz_private.snapshot_new_seller_order() returns trigger
language plpgsql security definer set search_path='' as $$
begin
  perform kidz_private.capture_seller_order(new);
  return new;
end;
$$;
revoke all on function kidz_private.snapshot_new_seller_order() from public,anon,authenticated,service_role;
create trigger capture_seller_order after insert on public.orders
  for each row execute function kidz_private.snapshot_new_seller_order();

-- Backfill only ownership provable from the surviving catalogue. Missing product
-- ownership remains unknown; never infer it from a client-supplied seller field.
do $$
declare o public.orders;
begin
  for o in select * from public.orders loop perform kidz_private.capture_seller_order(o); end loop;
end;
$$;

create function kidz_private.require_seller() returns uuid
language plpgsql stable security definer set search_path='' as $$
declare claims jsonb := auth.jwt(); seller uuid;
begin
  if auth.uid() is null or claims->>'session_id' is null or claims->>'exp' is null
    or (claims->>'exp')::numeric <= extract(epoch from now()) then
    raise exception using errcode='42501',message='Seller authorization required.';
  end if;
  select s.id into seller from public.sellers s
    join auth.users u on u.id=s.user_id join auth.sessions a on a.user_id=u.id
    where s.user_id=auth.uid() and a.id=(claims->>'session_id')::uuid
      and u.deleted_at is null and u.email_confirmed_at is not null
      and (u.banned_until is null or u.banned_until<=now())
      and (a.not_after is null or a.not_after>now());
  if seller is null then
    raise exception using errcode='42501',message='Seller authorization required.';
  end if;
  return seller;
exception when invalid_text_representation or numeric_value_out_of_range then
  raise exception using errcode='42501',message='Seller authorization required.';
end;
$$;
revoke all on function kidz_private.require_seller() from public,anon,authenticated,service_role;

create function kidz_private.seller_order_page(
  p_start timestamptz default null,p_end timestamptz default null,
  p_before_date timestamptz default null,p_before_id uuid default null,p_limit integer default 200
) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare seller uuid := kidz_private.require_seller(); result jsonb;
begin
  if p_limit is null or p_limit<1 or p_limit>200
    or (p_before_date is null)<>(p_before_id is null)
    or (p_start is not null and p_end is not null and p_start>=p_end) then
    raise exception using errcode='22023',message='Invalid order page.';
  end if;
  select coalesce(jsonb_agg(page.data order by page.order_date desc,page.order_id desc),'[]')
    into result from (
      select snap.order_date,snap.order_id,jsonb_build_object(
        'id',o.id,'order_date',snap.order_date,'status',o.status,'updated_at',o.updated_at,
        'can_update_status',snap.source_valid and jsonb_array_length(snap.items)>0
          and kidz_private.order_item_array(o.order_items) is not distinct from snap.source_items
          and not exists(select 1 from jsonb_array_elements(snap.items) item
            where item->>'_seller_user_id' is distinct from auth.uid()::text),
        'order_items',(select jsonb_agg(item-'_seller_id'-'_seller_user_id' order by position)
          from jsonb_array_elements(snap.items) with ordinality line(item,position)
          where item->>'_seller_user_id'=auth.uid()::text)
      ) data
      from kidz_private.seller_order_snapshots snap join public.orders o on o.id=snap.order_id
      where snap.owner_ids @> array[auth.uid()]
        and (p_start is null or snap.order_date>=p_start)
        and (p_end is null or snap.order_date<p_end)
        and (p_before_date is null or (snap.order_date,snap.order_id)<(p_before_date,p_before_id))
      order by snap.order_date desc,snap.order_id desc limit p_limit
    ) page;
  return jsonb_build_object('orders',result);
end;
$$;
revoke all on function kidz_private.seller_order_page(timestamptz,timestamptz,timestamptz,uuid,integer)
  from public,anon,authenticated,service_role;
grant execute on function kidz_private.seller_order_page(timestamptz,timestamptz,timestamptz,uuid,integer) to authenticated;

create function kidz_private.seller_set_order_status(p_id uuid,p_status text,p_expected_updated_at timestamptz)
returns jsonb language plpgsql security definer set search_path='' set lock_timeout='5s' as $$
declare seller uuid := kidz_private.require_seller(); o public.orders;
  snap kidz_private.seller_order_snapshots;
begin
  -- Same mutex as existing Admin actions: refuse contention, never implicitly retry.
  if not pg_try_advisory_xact_lock(hashtextextended('kidz.admin.management',0)) then
    raise exception using errcode='PT409',message='Another management action is in progress. Refresh and try again.';
  end if;
  perform 1 from auth.users where id=auth.uid() for share;
  perform 1 from auth.sessions where id=(auth.jwt()->>'session_id')::uuid for share;
  perform 1 from public.sellers where id=seller for share;
  if seller is distinct from kidz_private.require_seller() then
    raise exception using errcode='42501',message='Seller authorization required.';
  end if;
  if p_status is null or p_status not in ('Packaging','Shipping','Delivering') then
    raise exception using errcode='22023',message='Unsupported order status.';
  end if;
  select * into o from public.orders where id=p_id for update;
  select * into snap from kidz_private.seller_order_snapshots where order_id=p_id;
  -- Same denial for unknown and foreign orders: no existence oracle.
  if o.id is null or snap.order_id is null or not snap.owner_ids @> array[auth.uid()] then
    raise exception using errcode='42501',message='Order status change is not permitted.';
  end if;
  if not snap.source_valid or jsonb_array_length(snap.items)=0
    or exists(select 1 from jsonb_array_elements(snap.items) item
      where item->>'_seller_user_id' is distinct from auth.uid()::text) then
    raise exception using errcode='42501',message='Shared or unattributed order status is managed by Admin.';
  end if;
  if p_expected_updated_at is null or o.updated_at is distinct from p_expected_updated_at
    or kidz_private.order_item_array(o.order_items) is distinct from snap.source_items then
    raise exception using errcode='PT409',message='Order changed. Refresh and try again.';
  end if;
  update public.orders set status=p_status where id=p_id returning * into o;
  return jsonb_build_object('id',o.id,'status',o.status,'updated_at',o.updated_at);
end;
$$;
revoke all on function kidz_private.seller_set_order_status(uuid,text,timestamptz) from public,anon,authenticated,service_role;
grant execute on function kidz_private.seller_set_order_status(uuid,text,timestamptz) to authenticated;

create function public.seller_order_page(
  p_start timestamptz default null,p_end timestamptz default null,
  p_before_date timestamptz default null,p_before_id uuid default null,p_limit integer default 200
) returns jsonb language sql security invoker set search_path='' as $$
  select kidz_private.seller_order_page(p_start,p_end,p_before_date,p_before_id,p_limit);
$$;
create function public.seller_set_order_status(p_id uuid,p_status text,p_expected_updated_at timestamptz)
returns jsonb language sql security invoker set search_path='' as $$
  select kidz_private.seller_set_order_status(p_id,p_status,p_expected_updated_at);
$$;
revoke all on function public.seller_order_page(timestamptz,timestamptz,timestamptz,uuid,integer) from public,anon,authenticated,service_role;
revoke all on function public.seller_set_order_status(uuid,text,timestamptz) from public,anon,authenticated,service_role;
grant execute on function public.seller_order_page(timestamptz,timestamptz,timestamptz,uuid,integer) to authenticated;
grant execute on function public.seller_set_order_status(uuid,text,timestamptz) to authenticated;

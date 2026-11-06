-- Phase 1: Admin SELECT only. Existing Buyer/Seller policies are unchanged.
-- app_metadata is assigned through the server Admin API, never signup metadata.
create policy "users: admin read"
  on public.users for select to authenticated
  using (
    (select auth.uid()) is not null
    and coalesce((select auth.jwt()) -> 'app_metadata' ->> 'role', '') = 'admin'
  );

create policy "sellers: admin read"
  on public.sellers for select to authenticated
  using (
    (select auth.uid()) is not null
    and coalesce((select auth.jwt()) -> 'app_metadata' ->> 'role', '') = 'admin'
  );

create policy "orders: admin read"
  on public.orders for select to authenticated
  using (
    (select auth.uid()) is not null
    and coalesce((select auth.jwt()) -> 'app_metadata' ->> 'role', '') = 'admin'
  );

-- No access to legacy admin credentials, cart, bankingcard, or storage is added.
-- No Admin INSERT, UPDATE, or DELETE policy is introduced.

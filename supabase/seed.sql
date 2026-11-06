-- Synthetic demo catalogue for the Kidz project.
--
-- Deliberately contains NO auth users, NO passwords and NO credentials. Test
-- accounts are created through the app's normal registration flow instead, so
-- nothing secret is ever committed here.
--
-- Because every product must belong to a seller, this seed attaches its demo
-- rows to whichever seller already exists. If no one has registered as a seller
-- yet it does nothing at all — running it is always safe and repeatable.
--
-- Note: `supabase db push` does not execute this file. It runs on
-- `supabase db reset` (local only) or can be applied by hand.

do $$
declare
  demo_seller uuid;
begin
  select id into demo_seller
  from public.sellers
  order by created_at
  limit 1;

  if demo_seller is null then
    raise notice 'No seller registered yet — skipping demo product seed.';
    return;
  end if;

  -- Fixed ids keep this seed idempotent: re-running updates nothing new.
  insert into public.products
    (id, seller_id, product_name, product_description, product_price,
     product_sizes, product_colors, product_images, rating)
  values
    ('11111111-1111-4111-8111-111111111111', demo_seller,
     'Kidz Rainbow T-Shirt', 'Soft cotton tee with a rainbow print.', 29.90,
     '{"XS","S","M"}', '{"Red","Blue"}', '{}', 4.5),
    ('22222222-2222-4222-8222-222222222222', demo_seller,
     'Kidz Denim Overalls', 'Adjustable straps, two front pockets.', 59.00,
     '{"S","M","L"}', '{"Blue"}', '{}', 4.0),
    ('33333333-3333-4333-8333-333333333333', demo_seller,
     'Kidz Sun Hat', 'Wide brim, breathable weave.', 19.50,
     '{"S","M"}', '{"Yellow","White"}', '{}', 3.5)
  on conflict (id) do nothing;

  raise notice 'Demo products seeded for seller %.', demo_seller;
end
$$;

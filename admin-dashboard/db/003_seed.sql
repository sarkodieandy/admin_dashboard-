-- Demo seed data (safe to re-run, uses upserts where possible).

insert into public.branches (id, name, address, is_open)
values
  ('11111111-1111-1111-1111-111111111111', 'Bekwai Main Branch', 'Bekwai • Central Ghana', true)
on conflict (id) do update set name = excluded.name;

insert into public.categories (branch_id, name, sort_order, active)
values
  ('11111111-1111-1111-1111-111111111111', 'Jollof & Rice', 10, true),
  ('11111111-1111-1111-1111-111111111111', 'Grills', 20, true),
  ('11111111-1111-1111-1111-111111111111', 'Drinks', 30, true),
  ('11111111-1111-1111-1111-111111111111', 'Sides', 40, true)
on conflict do nothing;

-- Sample menu items
insert into public.menu_items (branch_id, category_id, name, description, price, image_url, is_available, prep_time_min, featured)
select
  c.branch_id,
  c.id,
  v.name,
  v.description,
  v.price,
  v.image_url,
  true,
  v.prep_time_min,
  v.featured
from public.categories c
join (
  values
    ('Jollof & Rice', 'Chicken Jollof', 'Smoky jollof rice with grilled chicken.', 45.00, 'https://images.unsplash.com/photo-1604908554100-279b9fba6c14?auto=format&fit=crop&w=900&q=80', 18, true),
    ('Jollof & Rice', 'Fried Rice', 'Stir-fried rice with mixed vegetables.', 40.00, 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=900&q=80', 16, false),
    ('Grills', 'Half Chicken', 'Char-grilled half chicken, spicy or mild.', 55.00, 'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?auto=format&fit=crop&w=900&q=80', 22, true),
    ('Drinks', 'Sobolo', 'Chilled hibiscus drink (500ml).', 10.00, 'https://images.unsplash.com/photo-1544145945-f90425340c7e?auto=format&fit=crop&w=900&q=80', 0, false),
    ('Sides', 'Kelewele', 'Spiced fried plantain cubes.', 15.00, 'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=900&q=80', 8, false)
) as v(category_name, name, description, price, image_url, prep_time_min, featured)
on v.category_name = c.name
where c.branch_id = '11111111-1111-1111-1111-111111111111'
on conflict do nothing;

-- Delivery settings
insert into public.delivery_settings (branch_id, base_fee, free_radius_km, per_km_fee_after_free_radius, minimum_order_amount, max_delivery_distance_km)
values ('11111111-1111-1111-1111-111111111111', 10, 2, 3, 40, 12)
on conflict (branch_id) do update set updated_at = now();

-- Demo orders + conversations/messages use fake customer ids. Staff can still see them by branch.
insert into public.orders (branch_id, customer_id, status, type, subtotal, delivery_fee, discount, total, payment_method, payment_status, address_text, notes)
values
  ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'new', 'delivery', 45, 10, 0, 55, 'momo', 'paid', 'Bekwai Central • Near the market', 'No onions please'),
  ('11111111-1111-1111-1111-111111111111', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'preparing', 'pickup', 55, 0, 0, 55, 'cash', 'unpaid', null, null)
on conflict do nothing;

-- Notifications demo
insert into public.notifications (branch_id, type, title, body, entity, entity_id)
select
  '11111111-1111-1111-1111-111111111111',
  'order_new',
  'New order received',
  'A customer placed a new delivery order.',
  'orders',
  o.id
from public.orders o
where o.branch_id = '11111111-1111-1111-1111-111111111111'
order by o.created_at desc
limit 1
on conflict do nothing;


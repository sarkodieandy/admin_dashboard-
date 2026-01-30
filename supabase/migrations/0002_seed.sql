-- Seed data (realistic, tweak as needed)

insert into public.categories (id, name, is_active, sort_order)
values
  ('11111111-1111-1111-1111-111111111111', 'Jollof & Rice', true, 10),
  ('22222222-2222-2222-2222-222222222222', 'Local Favourites', true, 20),
  ('33333333-3333-3333-3333-333333333333', 'Grills & Chicken', true, 30),
  ('44444444-4444-4444-4444-444444444444', 'Sides', true, 40),
  ('55555555-5555-5555-5555-555555555555', 'Drinks', true, 50)
on conflict (id) do nothing;

insert into public.menu_items (id, category_id, name, description, base_price, image_url, spice_level, is_active, is_sold_out)
values
  (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '11111111-1111-1111-1111-111111111111',
    'Chicken Jollof (Smoky)',
    'Smoky jollof rice served with grilled chicken, fresh salad, and our house shito.',
    55.00,
    'menu/chicken_jollof/main.jpg',
    2,
    true,
    false
  ),
  (
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    '11111111-1111-1111-1111-111111111111',
    'Fried Rice + Chicken',
    'Fluffy fried rice with mixed veg, served with golden chicken and pepper.',
    52.00,
    'menu/fried_rice_chicken/main.jpg',
    1,
    true,
    false
  ),
  (
    'cccccccc-cccc-cccc-cccc-cccccccccccc',
    '22222222-2222-2222-2222-222222222222',
    'Waakye Special',
    'Waakye with gari, spaghetti, egg, and your choice of protein. A Bekwai classic.',
    45.00,
    'menu/waakye_special/main.jpg',
    2,
    true,
    false
  ),
  (
    'dddddddd-dddd-dddd-dddd-dddddddddddd',
    '22222222-2222-2222-2222-222222222222',
    'Banku + Tilapia',
    'Two balls of banku with grilled tilapia, pepper, and fresh onions.',
    70.00,
    'menu/banku_tilapia/main.jpg',
    3,
    true,
    false
  ),
  (
    'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
    '33333333-3333-3333-3333-333333333333',
    'Grilled Chicken (Half)',
    'Juicy half chicken, charcoal grilled with our spicy orange glaze.',
    60.00,
    'menu/grilled_chicken_half/main.jpg',
    2,
    true,
    false
  ),
  (
    'ffffffff-ffff-ffff-ffff-ffffffffffff',
    '44444444-4444-4444-4444-444444444444',
    'Kelewele',
    'Sweet + spicy fried plantain cubes.',
    18.00,
    'menu/kelewele/main.jpg',
    2,
    true,
    false
  ),
  (
    '99999999-9999-9999-9999-999999999999',
    '55555555-5555-5555-5555-555555555555',
    'Sobolo (Hibiscus)',
    'Chilled homemade sobolo. Not too sweet.',
    12.00,
    'menu/sobolo/main.jpg',
    0,
    true,
    false
  )
on conflict (id) do nothing;

insert into public.menu_item_images (item_id, image_url, sort_order)
values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'menu/chicken_jollof/1.jpg', 10),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'menu/chicken_jollof/2.jpg', 20),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'menu/fried_rice_chicken/1.jpg', 10),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'menu/waakye_special/1.jpg', 10),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'menu/banku_tilapia/1.jpg', 10),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'menu/grilled_chicken_half/1.jpg', 10),
  ('ffffffff-ffff-ffff-ffff-ffffffffffff', 'menu/kelewele/1.jpg', 10),
  ('99999999-9999-9999-9999-999999999999', 'menu/sobolo/1.jpg', 10)
on conflict do nothing;

insert into public.item_variants (item_id, name, price_delta)
values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Regular', 0),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Large', 12),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Regular', 0),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Large', 10),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Regular', 0),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Large', 8)
on conflict do nothing;

insert into public.item_addons (item_id, name, price)
values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Extra chicken', 15),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Extra shito', 3),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Extra chicken', 15),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Egg', 3),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Wele', 6),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'Extra pepper', 2),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'Extra sauce', 3)
on conflict do nothing;

insert into public.promos (code, type, value, min_subtotal, expires_at, is_active)
values
  ('FLK10', 'percent', 10, 70, now() + interval '30 days', true),
  ('BEKWAI5', 'fixed', 5, 50, now() + interval '14 days', true)
on conflict (code) do nothing;


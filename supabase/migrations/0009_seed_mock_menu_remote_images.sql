-- Seed menu with REAL network images (no admin panel needed yet).
--
-- This seed uses absolute image URLs so the customer app immediately shows
-- food photos even before you upload images into Supabase Storage.
--
-- Production note:
-- For best control + performance, upload your own images to the `menu-images`
-- bucket and store object paths (e.g. `menu/chicken_jollof/main.jpg`) instead.

-- =========
-- Categories
-- =========

insert into public.categories (id, name, is_active, sort_order)
values
  ('11111111-1111-1111-1111-111111111111', 'Jollof & Rice', true, 10),
  ('22222222-2222-2222-2222-222222222222', 'Local Favourites', true, 20),
  ('66666666-6666-6666-6666-666666666666', 'Swallow & Soups', true, 25),
  ('33333333-3333-3333-3333-333333333333', 'Grills & Chicken', true, 30),
  ('77777777-7777-7777-7777-777777777777', 'Wraps & Shawarma', true, 35),
  ('44444444-4444-4444-4444-444444444444', 'Sides', true, 40),
  ('55555555-5555-5555-5555-555555555555', 'Drinks', true, 50),
  ('88888888-8888-8888-8888-888888888888', 'Desserts', true, 60)
on conflict (id) do update
set name = excluded.name,
    is_active = excluded.is_active,
    sort_order = excluded.sort_order;

-- =========
-- Menu items
-- =========

insert into public.menu_items (id, category_id, name, description, base_price, image_url, spice_level, is_active, is_sold_out)
values
	  (
	    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
	    '11111111-1111-1111-1111-111111111111',
	    'Chicken Jollof (Smoky)',
	    'Smoky jollof rice served with grilled chicken, fresh salad, and our house shito.',
	    55.00,
	    'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=1200&q=80',
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
	    'https://images.unsplash.com/photo-1478145046317-39f10e56b5e9?auto=format&fit=crop&w=1200&q=80',
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
	    'https://images.unsplash.com/photo-1490645935967-10de6ba17061?auto=format&fit=crop&w=1200&q=80',
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
	    'https://images.unsplash.com/photo-1467003909585-2f8a72700288?auto=format&fit=crop&w=1200&q=80',
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
	    'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?auto=format&fit=crop&w=1200&q=80',
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
	    'https://images.unsplash.com/photo-1502741338009-cac2772e18bc?auto=format&fit=crop&w=1200&q=80',
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
	    'https://images.unsplash.com/photo-1510627498534-cf7e9002facc?auto=format&fit=crop&w=1200&q=80',
	    0,
	    true,
	    false
	  ),

	  (
	    'a1a1a1a1-aaaa-4aaa-8aaa-aaaaaaaaaaa1',
	    '11111111-1111-1111-1111-111111111111',
	    'Beef Jollof + Shito',
	    'Party-style jollof with tender beef, shito, and a squeeze of lime.',
	    58.00,
	    'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=1200&q=80',
	    2,
	    true,
	    false
	  ),
	  (
	    'b1b1b1b1-bbbb-4bbb-8bbb-bbbbbbbbbbb1',
	    '11111111-1111-1111-1111-111111111111',
	    'Vegetable Fried Rice Bowl',
	    'Veg-packed fried rice with a warm garlic aroma — light but satisfying.',
	    40.00,
	    'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=1200&q=80',
	    1,
	    true,
	    false
	  ),
	  (
	    'c1c1c1c1-cccc-4ccc-8ccc-ccccccccccc1',
	    '11111111-1111-1111-1111-111111111111',
	    'Plain Rice + Chicken Stew',
	    'Steamed rice with rich tomato chicken stew. Comfort food done right.',
	    48.00,
	    'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=1200&q=80',
	    1,
	    true,
	    false
	  ),
	  (
	    'd1d1d1d1-dddd-4ddd-8ddd-ddddddddddd1',
	    '22222222-2222-2222-2222-222222222222',
	    'Gob3 (Gari & Beans) + Plantain',
	    'Gari & beans with ripe fried plantain and a little pepper — simple, iconic.',
	    35.00,
	    'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=1200&q=80',
	    2,
	    true,
	    false
	  ),
	  (
	    'e1e1e1e1-eeee-4eee-8eee-eeeeeeeeeee1',
	    '22222222-2222-2222-2222-222222222222',
	    'Ampesi + Kontomire Stew',
	    'Boiled yam and plantain with kontomire stew. Add fish or egg if you like.',
	    42.00,
	    'https://images.unsplash.com/photo-1529042410759-befb1204b468?auto=format&fit=crop&w=1200&q=80',
	    1,
	    true,
	    false
	  ),
	  (
	    'f1f1f1f1-ffff-4fff-8fff-fffffffffff1',
	    '66666666-6666-6666-6666-666666666666',
	    'Fufu + Light Soup (Goat)',
	    'Soft fufu with fragrant light soup and goat. Best enjoyed hot.',
	    65.00,
	    'https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=1200&q=80',
	    2,
	    true,
	    false
	  ),
	  (
	    '01010101-1010-4101-8101-010101010101',
	    '66666666-6666-6666-6666-666666666666',
	    'Banku + Okro Stew',
	    'Smooth okro stew with banku — silky, comforting, and filling.',
	    55.00,
	    'https://images.unsplash.com/photo-1547592166-23ac45744acd?auto=format&fit=crop&w=1200&q=80',
	    2,
	    true,
	    false
	  ),
	  (
	    '02020202-2020-4202-8202-020202020202',
	    '66666666-6666-6666-6666-666666666666',
	    'Kokonte + Groundnut Soup',
	    'Earthy kokonte with groundnut soup. The kind of meal that hugs you back.',
	    50.00,
	    'https://images.unsplash.com/photo-1543353071-873f17a7a088?auto=format&fit=crop&w=1200&q=80',
	    2,
	    true,
	    false
	  ),
	  (
	    '03030303-3030-4303-8303-030303030303',
	    '33333333-3333-3333-3333-333333333333',
	    'Chicken Wings (8 pcs)',
	    'Sticky wings with a spicy-sweet glaze. Napkins recommended.',
	    45.00,
	    'https://images.unsplash.com/photo-1478145046317-39f10e56b5e9?auto=format&fit=crop&w=1200&q=80',
	    2,
	    true,
	    false
	  ),
	  (
	    '04040404-4040-4404-8404-040404040404',
	    '33333333-3333-3333-3333-333333333333',
	    'Beef Suya (Spicy)',
	    'Char-grilled beef skewers with suya spice and onions.',
	    38.00,
	    'https://images.unsplash.com/photo-1478145046317-39f10e56b5e9?auto=format&fit=crop&w=1200&q=80',
	    3,
	    true,
	    false
	  ),
	  (
	    '05050505-5050-4505-8505-050505050505',
	    '33333333-3333-3333-3333-333333333333',
	    'Grilled Tilapia (Whole)',
	    'Whole tilapia grilled with pepper and herbs. Perfect for sharing.',
	    75.00,
	    'https://images.unsplash.com/photo-1467003909585-2f8a72700288?auto=format&fit=crop&w=1200&q=80',
	    3,
	    true,
	    false
	  ),
	  (
	    '06060606-6060-4606-8606-060606060606',
	    '77777777-7777-7777-7777-777777777777',
	    'Chicken Shawarma',
	    'Warm wrap with chicken, sauce, and crunch. Mild by default — spice optional.',
	    35.00,
	    'https://images.unsplash.com/photo-1521305916504-4a1121188589?auto=format&fit=crop&w=1200&q=80',
	    1,
	    true,
	    false
	  ),
	  (
	    '07070707-7070-4707-8707-070707070707',
	    '77777777-7777-7777-7777-777777777777',
	    'Beef Shawarma',
	    'Tender beef, creamy sauce, and fresh veg in a soft wrap.',
	    37.00,
	    'https://images.unsplash.com/photo-1521305916504-4a1121188589?auto=format&fit=crop&w=1200&q=80',
	    1,
	    true,
	    false
	  ),
	  (
	    '08080808-8080-4808-8808-080808080808',
	    '88888888-8888-8888-8888-888888888888',
	    'Fruit Salad Cup',
	    'Fresh seasonal fruit — a clean finish after something spicy.',
	    18.00,
	    'https://images.unsplash.com/photo-1502741338009-cac2772e18bc?auto=format&fit=crop&w=1200&q=80',
	    0,
	    true,
	    false
	  ),
	  (
	    '09090909-9090-4909-8909-090909090909',
	    '55555555-5555-5555-5555-555555555555',
	    'Alvaro (Malt)',
	    'Chilled malt drink.',
	    12.00,
	    'https://images.unsplash.com/photo-1510627498534-cf7e9002facc?auto=format&fit=crop&w=1200&q=80',
	    0,
	    true,
	    false
	  ),
	  (
	    '0b0b0b0b-b0b0-4b0b-8b0b-0b0b0b0b0b0b',
	    '55555555-5555-5555-5555-555555555555',
	    'Coke (330ml)',
	    'Ice-cold classic.',
	    10.00,
	    'https://images.unsplash.com/photo-1470337458703-46ad1756a187?auto=format&fit=crop&w=1200&q=80',
	    0,
	    true,
	    false
	  ),
	  (
	    '0c0c0c0c-c0c0-4c0c-8c0c-0c0c0c0c0c0c',
	    '55555555-5555-5555-5555-555555555555',
	    'Pineapple Ginger',
	    'Fresh pineapple with a ginger kick. Bright, zingy, and refreshing.',
	    14.00,
	    'https://images.unsplash.com/photo-1502741338009-cac2772e18bc?auto=format&fit=crop&w=1200&q=80',
	    0,
	    true,
	    false
	  )
on conflict (id) do update
set category_id = excluded.category_id,
    name = excluded.name,
    description = excluded.description,
    base_price = excluded.base_price,
    image_url = excluded.image_url,
    spice_level = excluded.spice_level,
    is_active = excluded.is_active,
    is_sold_out = excluded.is_sold_out;

-- Keep seeds deterministic (avoid duplicate variants/add-ons/images if re-run)
delete from public.menu_item_images
where item_id in (
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  'cccccccc-cccc-cccc-cccc-cccccccccccc',
  'dddddddd-dddd-dddd-dddd-dddddddddddd',
  'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
  'ffffffff-ffff-ffff-ffff-ffffffffffff',
  '99999999-9999-9999-9999-999999999999',
  'a1a1a1a1-aaaa-4aaa-8aaa-aaaaaaaaaaa1',
  'b1b1b1b1-bbbb-4bbb-8bbb-bbbbbbbbbbb1',
  'c1c1c1c1-cccc-4ccc-8ccc-ccccccccccc1',
  'd1d1d1d1-dddd-4ddd-8ddd-ddddddddddd1',
  'e1e1e1e1-eeee-4eee-8eee-eeeeeeeeeee1',
  'f1f1f1f1-ffff-4fff-8fff-fffffffffff1',
  '01010101-1010-4101-8101-010101010101',
  '02020202-2020-4202-8202-020202020202',
  '03030303-3030-4303-8303-030303030303',
  '04040404-4040-4404-8404-040404040404',
  '05050505-5050-4505-8505-050505050505',
  '06060606-6060-4606-8606-060606060606',
  '07070707-7070-4707-8707-070707070707',
  '08080808-8080-4808-8808-080808080808',
  '09090909-9090-4909-8909-090909090909',
  '0b0b0b0b-b0b0-4b0b-8b0b-0b0b0b0b0b0b',
  '0c0c0c0c-c0c0-4c0c-8c0c-0c0c0c0c0c0c'
);

delete from public.item_variants
where item_id in (
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  'cccccccc-cccc-cccc-cccc-cccccccccccc',
  'dddddddd-dddd-dddd-dddd-dddddddddddd',
  'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
  'ffffffff-ffff-ffff-ffff-ffffffffffff',
  'a1a1a1a1-aaaa-4aaa-8aaa-aaaaaaaaaaa1',
  'b1b1b1b1-bbbb-4bbb-8bbb-bbbbbbbbbbb1',
  'c1c1c1c1-cccc-4ccc-8ccc-ccccccccccc1',
  'd1d1d1d1-dddd-4ddd-8ddd-ddddddddddd1',
  'e1e1e1e1-eeee-4eee-8eee-eeeeeeeeeee1',
  'f1f1f1f1-ffff-4fff-8fff-fffffffffff1',
  '01010101-1010-4101-8101-010101010101',
  '02020202-2020-4202-8202-020202020202',
  '03030303-3030-4303-8303-030303030303',
  '04040404-4040-4404-8404-040404040404',
  '05050505-5050-4505-8505-050505050505',
  '06060606-6060-4606-8606-060606060606',
  '07070707-7070-4707-8707-070707070707'
);

delete from public.item_addons
where item_id in (
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  'cccccccc-cccc-cccc-cccc-cccccccccccc',
  'dddddddd-dddd-dddd-dddd-dddddddddddd',
  'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
  'ffffffff-ffff-ffff-ffff-ffffffffffff',
  'a1a1a1a1-aaaa-4aaa-8aaa-aaaaaaaaaaa1',
  'c1c1c1c1-cccc-4ccc-8ccc-ccccccccccc1',
  'd1d1d1d1-dddd-4ddd-8ddd-ddddddddddd1',
  'e1e1e1e1-eeee-4eee-8eee-eeeeeeeeeee1',
  'f1f1f1f1-ffff-4fff-8fff-fffffffffff1',
  '01010101-1010-4101-8101-010101010101',
  '03030303-3030-4303-8303-030303030303',
  '04040404-4040-4404-8404-040404040404',
  '06060606-6060-4606-8606-060606060606',
  '07070707-7070-4707-8707-070707070707',
  '08080808-8080-4808-8808-080808080808'
);

-- =========
-- Extra images per item
-- =========

	insert into public.menu_item_images (item_id, image_url, sort_order)
	values
	  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=1200&q=80', 10),
	  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'https://images.unsplash.com/photo-1504754524776-8f4f37790ca0?auto=format&fit=crop&w=1200&q=80', 20),
	  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'https://images.unsplash.com/photo-1478145046317-39f10e56b5e9?auto=format&fit=crop&w=1200&q=80', 10),
	  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=1200&q=80', 20),
	  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?auto=format&fit=crop&w=1200&q=80', 10),
	  ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?auto=format&fit=crop&w=1200&q=80', 10),
	  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?auto=format&fit=crop&w=1200&q=80', 10),
	  ('ffffffff-ffff-ffff-ffff-ffffffffffff', 'https://images.unsplash.com/photo-1502741338009-cac2772e18bc?auto=format&fit=crop&w=1200&q=80', 10),
	  ('99999999-9999-9999-9999-999999999999', 'https://images.unsplash.com/photo-1510627498534-cf7e9002facc?auto=format&fit=crop&w=1200&q=80', 10),

	  ('a1a1a1a1-aaaa-4aaa-8aaa-aaaaaaaaaaa1', 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=1200&q=80', 10),
	  ('b1b1b1b1-bbbb-4bbb-8bbb-bbbbbbbbbbb1', 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=1200&q=80', 10),
	  ('c1c1c1c1-cccc-4ccc-8ccc-ccccccccccc1', 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=1200&q=80', 10),
	  ('d1d1d1d1-dddd-4ddd-8ddd-ddddddddddd1', 'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=1200&q=80', 10),
	  ('e1e1e1e1-eeee-4eee-8eee-eeeeeeeeeee1', 'https://images.unsplash.com/photo-1529042410759-befb1204b468?auto=format&fit=crop&w=1200&q=80', 10),
	  ('f1f1f1f1-ffff-4fff-8fff-fffffffffff1', 'https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=1200&q=80', 10),
	  ('01010101-1010-4101-8101-010101010101', 'https://images.unsplash.com/photo-1547592166-23ac45744acd?auto=format&fit=crop&w=1200&q=80', 10),
	  ('02020202-2020-4202-8202-020202020202', 'https://images.unsplash.com/photo-1543353071-873f17a7a088?auto=format&fit=crop&w=1200&q=80', 10),
	  ('03030303-3030-4303-8303-030303030303', 'https://images.unsplash.com/photo-1478145046317-39f10e56b5e9?auto=format&fit=crop&w=1200&q=80', 10),
	  ('04040404-4040-4404-8404-040404040404', 'https://images.unsplash.com/photo-1478145046317-39f10e56b5e9?auto=format&fit=crop&w=1200&q=80', 10),
	  ('05050505-5050-4505-8505-050505050505', 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?auto=format&fit=crop&w=1200&q=80', 10),
	  ('06060606-6060-4606-8606-060606060606', 'https://images.unsplash.com/photo-1521305916504-4a1121188589?auto=format&fit=crop&w=1200&q=80', 10),
	  ('07070707-7070-4707-8707-070707070707', 'https://images.unsplash.com/photo-1521305916504-4a1121188589?auto=format&fit=crop&w=1200&q=80', 10),
	  ('08080808-8080-4808-8808-080808080808', 'https://images.unsplash.com/photo-1502741338009-cac2772e18bc?auto=format&fit=crop&w=1200&q=80', 10),
	  ('09090909-9090-4909-8909-090909090909', 'https://images.unsplash.com/photo-1510627498534-cf7e9002facc?auto=format&fit=crop&w=1200&q=80', 10),
	  ('0b0b0b0b-b0b0-4b0b-8b0b-0b0b0b0b0b0b', 'https://images.unsplash.com/photo-1470337458703-46ad1756a187?auto=format&fit=crop&w=1200&q=80', 10),
	  ('0c0c0c0c-c0c0-4c0c-8c0c-0c0c0c0c0c0c', 'https://images.unsplash.com/photo-1502741338009-cac2772e18bc?auto=format&fit=crop&w=1200&q=80', 10)
	on conflict do nothing;

-- =========
-- Variants (size/portion)
-- =========

insert into public.item_variants (item_id, name, price_delta)
values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Regular', 0),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Large', 12),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Regular', 0),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Large', 10),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Regular', 0),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Large', 8),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'Regular', 0),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'Large', 15),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'Half', 0),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'Whole', 55),
  ('a1a1a1a1-aaaa-4aaa-8aaa-aaaaaaaaaaa1', 'Regular', 0),
  ('a1a1a1a1-aaaa-4aaa-8aaa-aaaaaaaaaaa1', 'Large', 12),
  ('b1b1b1b1-bbbb-4bbb-8bbb-bbbbbbbbbbb1', 'Regular', 0),
  ('b1b1b1b1-bbbb-4bbb-8bbb-bbbbbbbbbbb1', 'Large', 10),
  ('c1c1c1c1-cccc-4ccc-8ccc-ccccccccccc1', 'Regular', 0),
  ('c1c1c1c1-cccc-4ccc-8ccc-ccccccccccc1', 'Large', 10),
  ('d1d1d1d1-dddd-4ddd-8ddd-ddddddddddd1', 'Regular', 0),
  ('d1d1d1d1-dddd-4ddd-8ddd-ddddddddddd1', 'With egg', 3),
  ('e1e1e1e1-eeee-4eee-8eee-eeeeeeeeeee1', 'Regular', 0),
  ('e1e1e1e1-eeee-4eee-8eee-eeeeeeeeeee1', 'Extra stew', 6),
  ('f1f1f1f1-ffff-4fff-8fff-fffffffffff1', 'Single meat', 0),
  ('f1f1f1f1-ffff-4fff-8fff-fffffffffff1', 'Double meat', 12),
  ('01010101-1010-4101-8101-010101010101', 'Regular', 0),
  ('01010101-1010-4101-8101-010101010101', 'Large', 12),
  ('02020202-2020-4202-8202-020202020202', 'Single meat', 0),
  ('02020202-2020-4202-8202-020202020202', 'Double meat', 12),
  ('03030303-3030-4303-8303-030303030303', '6 pcs', 0),
  ('03030303-3030-4303-8303-030303030303', '10 pcs', 20),
  ('04040404-4040-4404-8404-040404040404', 'Regular', 0),
  ('04040404-4040-4404-8404-040404040404', 'Large', 10),
  ('06060606-6060-4606-8606-060606060606', 'Regular', 0),
  ('06060606-6060-4606-8606-060606060606', 'Large', 8),
  ('07070707-7070-4707-8707-070707070707', 'Regular', 0),
  ('07070707-7070-4707-8707-070707070707', 'Large', 8)
on conflict do nothing;

-- =========
-- Add-ons / extras
-- =========

insert into public.item_addons (item_id, name, price)
values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Extra chicken', 15),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Extra shito', 3),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Extra chicken', 15),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Extra pepper', 2),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Egg', 3),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Wele', 6),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Extra gari', 2),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'Extra pepper', 2),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'Extra sauce', 3),
  ('ffffffff-ffff-ffff-ffff-ffffffffffff', 'Groundnuts', 2),
  ('ffffffff-ffff-ffff-ffff-ffffffffffff', 'Extra pepper', 2),
  ('a1a1a1a1-aaaa-4aaa-8aaa-aaaaaaaaaaa1', 'Extra beef', 12),
  ('a1a1a1a1-aaaa-4aaa-8aaa-aaaaaaaaaaa1', 'Extra shito', 3),
  ('c1c1c1c1-cccc-4ccc-8ccc-ccccccccccc1', 'Extra stew', 6),
  ('c1c1c1c1-cccc-4ccc-8ccc-ccccccccccc1', 'Boiled egg', 3),
  ('d1d1d1d1-dddd-4ddd-8ddd-ddddddddddd1', 'Extra plantain', 7),
  ('e1e1e1e1-eeee-4eee-8eee-eeeeeeeeeee1', 'Egg', 3),
  ('f1f1f1f1-ffff-4fff-8fff-fffffffffff1', 'Extra goat', 12),
  ('01010101-1010-4101-8101-010101010101', 'Extra pepper', 2),
  ('03030303-3030-4303-8303-030303030303', 'Extra dip', 3),
  ('04040404-4040-4404-8404-040404040404', 'Extra onions', 2),
  ('06060606-6060-4606-8606-060606060606', 'Extra cheese', 5),
  ('06060606-6060-4606-8606-060606060606', 'Extra pepper', 2),
  ('07070707-7070-4707-8707-070707070707', 'Extra cheese', 5),
  ('08080808-8080-4808-8808-080808080808', 'Yoghurt drizzle', 4)
on conflict do nothing;

-- =========
-- Promos (optional)
-- =========

insert into public.promos (code, type, value, min_subtotal, expires_at, is_active)
values
  ('FLK10', 'percent', 10, 70, now() + interval '30 days', true),
  ('BEKWAI5', 'fixed', 5, 50, now() + interval '14 days', true)
on conflict (code) do nothing;

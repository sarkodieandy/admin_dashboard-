-- Fix broken remote image URLs from the mock seed.
--
-- Older versions of `0009_seed_mock_menu_remote_images.sql` used
-- `https://source.unsplash.com/...` which can return 503 and break images in-app.
-- This migration updates the seeded items to stable `images.unsplash.com` URLs.

update public.menu_items
set image_url = case id
  when 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' then 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=1200&q=80'
  when 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb' then 'https://images.unsplash.com/photo-1478145046317-39f10e56b5e9?auto=format&fit=crop&w=1200&q=80'
  when 'cccccccc-cccc-cccc-cccc-cccccccccccc' then 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?auto=format&fit=crop&w=1200&q=80'
  when 'dddddddd-dddd-dddd-dddd-dddddddddddd' then 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?auto=format&fit=crop&w=1200&q=80'
  when 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee' then 'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?auto=format&fit=crop&w=1200&q=80'
  when 'ffffffff-ffff-ffff-ffff-ffffffffffff' then 'https://images.unsplash.com/photo-1502741338009-cac2772e18bc?auto=format&fit=crop&w=1200&q=80'
  when '99999999-9999-9999-9999-999999999999' then 'https://images.unsplash.com/photo-1510627498534-cf7e9002facc?auto=format&fit=crop&w=1200&q=80'
  when 'a1a1a1a1-aaaa-4aaa-8aaa-aaaaaaaaaaa1' then 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=1200&q=80'
  when 'b1b1b1b1-bbbb-4bbb-8bbb-bbbbbbbbbbb1' then 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=1200&q=80'
  when 'c1c1c1c1-cccc-4ccc-8ccc-ccccccccccc1' then 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=1200&q=80'
  when 'd1d1d1d1-dddd-4ddd-8ddd-ddddddddddd1' then 'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=1200&q=80'
  when 'e1e1e1e1-eeee-4eee-8eee-eeeeeeeeeee1' then 'https://images.unsplash.com/photo-1529042410759-befb1204b468?auto=format&fit=crop&w=1200&q=80'
  when 'f1f1f1f1-ffff-4fff-8fff-fffffffffff1' then 'https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=1200&q=80'
  when '01010101-1010-4101-8101-010101010101' then 'https://images.unsplash.com/photo-1547592166-23ac45744acd?auto=format&fit=crop&w=1200&q=80'
  when '02020202-2020-4202-8202-020202020202' then 'https://images.unsplash.com/photo-1543353071-873f17a7a088?auto=format&fit=crop&w=1200&q=80'
  when '03030303-3030-4303-8303-030303030303' then 'https://images.unsplash.com/photo-1478145046317-39f10e56b5e9?auto=format&fit=crop&w=1200&q=80'
  when '04040404-4040-4404-8404-040404040404' then 'https://images.unsplash.com/photo-1478145046317-39f10e56b5e9?auto=format&fit=crop&w=1200&q=80'
  when '05050505-5050-4505-8505-050505050505' then 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?auto=format&fit=crop&w=1200&q=80'
  when '06060606-6060-4606-8606-060606060606' then 'https://images.unsplash.com/photo-1521305916504-4a1121188589?auto=format&fit=crop&w=1200&q=80'
  when '07070707-7070-4707-8707-070707070707' then 'https://images.unsplash.com/photo-1521305916504-4a1121188589?auto=format&fit=crop&w=1200&q=80'
  when '08080808-8080-4808-8808-080808080808' then 'https://images.unsplash.com/photo-1502741338009-cac2772e18bc?auto=format&fit=crop&w=1200&q=80'
  when '09090909-9090-4909-8909-090909090909' then 'https://images.unsplash.com/photo-1510627498534-cf7e9002facc?auto=format&fit=crop&w=1200&q=80'
  when '0b0b0b0b-b0b0-4b0b-8b0b-0b0b0b0b0b0b' then 'https://images.unsplash.com/photo-1470337458703-46ad1756a187?auto=format&fit=crop&w=1200&q=80'
  when '0c0c0c0c-c0c0-4c0c-8c0c-0c0c0c0c0c0c' then 'https://images.unsplash.com/photo-1502741338009-cac2772e18bc?auto=format&fit=crop&w=1200&q=80'
  else image_url
end
where id in (
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
)
and image_url like 'https://source.unsplash.com/%';

-- Keep item detail carousels working too (only touch the broken seeded URLs).
update public.menu_item_images mi
set image_url = m.image_url
from public.menu_items m
where mi.item_id = m.id
  and mi.item_id in (
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
  )
  and mi.image_url like 'https://source.unsplash.com/%'
  and m.image_url not like 'https://source.unsplash.com/%';


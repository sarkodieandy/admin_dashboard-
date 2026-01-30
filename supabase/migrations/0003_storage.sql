-- Supabase Storage setup (menu images)

-- Bucket
insert into storage.buckets (id, name, public)
values ('menu-images', 'menu-images', true)
on conflict (id) do update
set name = excluded.name,
    public = excluded.public;

-- Policies
alter table storage.objects enable row level security;

drop policy if exists "menu_images_public_read" on storage.objects;
create policy "menu_images_public_read"
on storage.objects
for select
using (bucket_id = 'menu-images');

drop policy if exists "menu_images_staff_insert" on storage.objects;
create policy "menu_images_staff_insert"
on storage.objects
for insert
with check (bucket_id = 'menu-images' and public.is_staff());

drop policy if exists "menu_images_staff_update" on storage.objects;
create policy "menu_images_staff_update"
on storage.objects
for update
using (bucket_id = 'menu-images' and public.is_staff())
with check (bucket_id = 'menu-images' and public.is_staff());

drop policy if exists "menu_images_staff_delete" on storage.objects;
create policy "menu_images_staff_delete"
on storage.objects
for delete
using (bucket_id = 'menu-images' and public.is_staff());


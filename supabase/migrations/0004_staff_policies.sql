-- Staff policies (for future restaurant/admin apps)
-- Customers still only see active menu content + their own data.

-- categories
drop policy if exists "categories_manage_staff" on public.categories;
drop policy if exists "categories_staff_all" on public.categories;
create policy "categories_staff_all"
on public.categories
for all
using (public.is_staff())
with check (public.is_staff());

-- menu_items
drop policy if exists "menu_items_manage_staff" on public.menu_items;
drop policy if exists "menu_items_staff_all" on public.menu_items;
create policy "menu_items_staff_all"
on public.menu_items
for all
using (public.is_staff())
with check (public.is_staff());

-- menu_item_images
drop policy if exists "menu_item_images_staff_all" on public.menu_item_images;
create policy "menu_item_images_staff_all"
on public.menu_item_images
for all
using (public.is_staff())
with check (public.is_staff());

-- item_variants
drop policy if exists "item_variants_staff_all" on public.item_variants;
create policy "item_variants_staff_all"
on public.item_variants
for all
using (public.is_staff())
with check (public.is_staff());

-- item_addons
drop policy if exists "item_addons_staff_all" on public.item_addons;
create policy "item_addons_staff_all"
on public.item_addons
for all
using (public.is_staff())
with check (public.is_staff());

-- promos
drop policy if exists "promos_staff_all" on public.promos;
create policy "promos_staff_all"
on public.promos
for all
using (public.is_staff())
with check (public.is_staff());

-- orders (staff can read/update; update policy already exists)
drop policy if exists "orders_select_staff" on public.orders;
create policy "orders_select_staff"
on public.orders
for select
using (public.is_staff());

-- order_items
drop policy if exists "order_items_select_staff" on public.order_items;
create policy "order_items_select_staff"
on public.order_items
for select
using (public.is_staff());

-- order_status_events
drop policy if exists "order_status_events_select_staff" on public.order_status_events;
create policy "order_status_events_select_staff"
on public.order_status_events
for select
using (public.is_staff());

-- notifications (staff can insert for customers)
drop policy if exists "notifications_insert_staff" on public.notifications;
create policy "notifications_insert_staff"
on public.notifications
for insert
with check (public.is_staff());


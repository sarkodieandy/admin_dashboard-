-- Allow staff/admin to view reviews in the admin dashboard.

-- reviews
drop policy if exists "reviews_select_staff" on public.reviews;
create policy "reviews_select_staff"
on public.reviews
for select
using (public.is_staff());

-- review_items
drop policy if exists "review_items_select_staff" on public.review_items;
create policy "review_items_select_staff"
on public.review_items
for select
using (public.is_staff());


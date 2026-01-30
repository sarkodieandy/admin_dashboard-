-- API role grants (PostgREST / Supabase client)
--
-- RLS controls *which rows* can be accessed, but Postgres privileges control
-- whether the API roles can access the tables at all.
--
-- This migration makes menu browsing work for logged-out users (anon) and
-- ensures authenticated users can create/read their own data (subject to RLS).

grant usage on schema public to anon, authenticated;

-- Public menu browsing (logged-out)
grant select on table
  public.categories,
  public.menu_items,
  public.menu_item_images,
  public.item_variants,
  public.item_addons,
  public.promos
to anon;

-- App usage (logged-in)
grant select, insert, update, delete on table
  public.profiles,
  public.addresses,
  public.categories,
  public.menu_items,
  public.menu_item_images,
  public.item_variants,
  public.item_addons,
  public.promos,
  public.orders,
  public.order_items,
  public.order_status_events,
  public.notifications,
  public.chats,
  public.chat_messages,
  public.reviews,
  public.review_items
to authenticated;

-- Functions referenced by RLS policies.
grant execute on function public.current_role() to anon, authenticated;
grant execute on function public.is_staff() to anon, authenticated;


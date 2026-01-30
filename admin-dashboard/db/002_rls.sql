-- Enable RLS and define key policies.
--
-- IMPORTANT: this file intentionally includes example policies for:
-- - orders
-- - conversations
-- - messages
-- - menu_items
--
-- Apply after 001_schema.sql.

alter table public.branches enable row level security;
alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.menu_items enable row level security;
alter table public.addons enable row level security;
alter table public.item_addons enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.riders enable row level security;
alter table public.deliveries enable row level security;
alter table public.coupons enable row level security;
alter table public.reviews enable row level security;
alter table public.support_tickets enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;
alter table public.message_reads enable row level security;
alter table public.chat_templates enable row level security;
alter table public.delivery_settings enable row level security;
alter table public.notifications enable row level security;
alter table public.audit_logs enable row level security;

-- branches: only admins can list/manage
drop policy if exists branches_select_admin on public.branches;
create policy branches_select_admin
on public.branches for select
using (public.is_admin());

drop policy if exists branches_manage_admin on public.branches;
create policy branches_manage_admin
on public.branches for all
using (public.is_admin())
with check (public.is_admin());

-- profiles: users can read their profile; admins can manage staff in their branch
drop policy if exists profiles_select_self on public.profiles;
create policy profiles_select_self
on public.profiles for select
using (id = auth.uid() or (public.is_admin() and branch_id = public.current_branch_id()));

drop policy if exists profiles_update_self on public.profiles;
create policy profiles_update_self
on public.profiles for update
using (id = auth.uid())
with check (id = auth.uid());

-- =========
-- menu_items (example)
-- =========
drop policy if exists menu_items_select_staff_branch on public.menu_items;
create policy menu_items_select_staff_branch
on public.menu_items for select
using (public.is_staff() and branch_id = public.current_branch_id());

drop policy if exists menu_items_write_staff_branch on public.menu_items;
create policy menu_items_write_staff_branch
on public.menu_items for insert
with check (public.is_staff() and branch_id = public.current_branch_id());

drop policy if exists menu_items_update_staff_branch on public.menu_items;
create policy menu_items_update_staff_branch
on public.menu_items for update
using (public.is_staff() and branch_id = public.current_branch_id())
with check (public.is_staff() and branch_id = public.current_branch_id());

-- Optional customer read (used by customer app): read only active+available items
drop policy if exists menu_items_select_customer_public on public.menu_items;
create policy menu_items_select_customer_public
on public.menu_items for select
using (not public.is_staff() and is_available = true);

-- =========
-- orders (example)
-- =========
drop policy if exists orders_select_staff_branch on public.orders;
create policy orders_select_staff_branch
on public.orders for select
using (public.is_staff() and branch_id = public.current_branch_id());

drop policy if exists orders_update_staff_branch on public.orders;
create policy orders_update_staff_branch
on public.orders for update
using (public.is_staff() and branch_id = public.current_branch_id())
with check (public.is_staff() and branch_id = public.current_branch_id());

drop policy if exists orders_select_customer_own on public.orders;
create policy orders_select_customer_own
on public.orders for select
using (customer_id = auth.uid());

drop policy if exists orders_insert_customer_own on public.orders;
create policy orders_insert_customer_own
on public.orders for insert
with check (customer_id = auth.uid());

-- =========
-- conversations (example)
-- =========
drop policy if exists conversations_select_staff_branch on public.conversations;
create policy conversations_select_staff_branch
on public.conversations for select
using (public.is_staff() and branch_id = public.current_branch_id());

drop policy if exists conversations_update_staff_branch on public.conversations;
create policy conversations_update_staff_branch
on public.conversations for update
using (public.is_staff() and branch_id = public.current_branch_id())
with check (public.is_staff() and branch_id = public.current_branch_id());

drop policy if exists conversations_select_customer_own on public.conversations;
create policy conversations_select_customer_own
on public.conversations for select
using (customer_id = auth.uid());

drop policy if exists conversations_insert_customer_own on public.conversations;
create policy conversations_insert_customer_own
on public.conversations for insert
with check (customer_id = auth.uid());

-- Rider: read conversations for assigned orders (via deliveries)
drop policy if exists conversations_select_rider_assigned on public.conversations;
create policy conversations_select_rider_assigned
on public.conversations for select
using (
  exists (
    select 1
    from public.deliveries d
    join public.orders o on o.id = d.order_id
    where o.id = order_id and d.rider_id = auth.uid()
  )
);

-- =========
-- messages (example)
-- =========
drop policy if exists messages_select_staff_branch on public.messages;
create policy messages_select_staff_branch
on public.messages for select
using (public.is_staff() and branch_id = public.current_branch_id());

drop policy if exists messages_insert_staff_branch on public.messages;
create policy messages_insert_staff_branch
on public.messages for insert
with check (public.is_staff() and branch_id = public.current_branch_id() and sender_id = auth.uid());

drop policy if exists messages_select_customer_own on public.messages;
create policy messages_select_customer_own
on public.messages for select
using (
  exists (
    select 1 from public.conversations c
    where c.id = conversation_id and c.customer_id = auth.uid()
  )
);

drop policy if exists messages_insert_customer_own on public.messages;
create policy messages_insert_customer_own
on public.messages for insert
with check (
  sender_id = auth.uid()
  and exists (
    select 1 from public.conversations c
    where c.id = conversation_id and c.customer_id = auth.uid()
  )
);

drop policy if exists messages_select_rider_assigned on public.messages;
create policy messages_select_rider_assigned
on public.messages for select
using (
  exists (
    select 1
    from public.deliveries d
    join public.orders o on o.id = d.order_id
    where o.id = order_id and d.rider_id = auth.uid()
  )
);

drop policy if exists messages_insert_rider_assigned on public.messages;
create policy messages_insert_rider_assigned
on public.messages for insert
with check (
  sender_id = auth.uid()
  and exists (
    select 1
    from public.deliveries d
    join public.orders o on o.id = d.order_id
    where o.id = order_id and d.rider_id = auth.uid()
  )
);


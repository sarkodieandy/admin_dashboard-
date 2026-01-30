-- Staff notifications for the Admin Dashboard (existing Flutter customer app schema).
--
-- SAFE TO APPLY: creates new objects only (table + functions + triggers + policies).
-- This powers the dashboard notification bell + Notifications page for staff/admin users.

create extension if not exists "pgcrypto";

create table if not exists public.staff_notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references auth.users(id) on delete cascade,
  type text not null check (type in ('new_order', 'customer_message', 'system')),
  title text not null,
  body text,
  entity_type text,
  entity_id uuid,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists staff_notifications_recipient_created_at_idx
on public.staff_notifications(recipient_id, created_at desc);

alter table public.staff_notifications enable row level security;

drop policy if exists "staff_notifications_select_own" on public.staff_notifications;
create policy "staff_notifications_select_own"
on public.staff_notifications
for select
using (public.is_staff() and recipient_id = auth.uid());

drop policy if exists "staff_notifications_update_own" on public.staff_notifications;
create policy "staff_notifications_update_own"
on public.staff_notifications
for update
using (public.is_staff() and recipient_id = auth.uid())
with check (public.is_staff() and recipient_id = auth.uid());

-- Trigger helpers
create or replace function public.notify_staff_new_order()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  staff_id uuid;
  short_id text;
begin
  short_id := left(new.id::text, 8);

  for staff_id in
    select id from public.profiles where role in ('admin'::public.app_role, 'staff'::public.app_role)
  loop
    insert into public.staff_notifications (recipient_id, type, title, body, entity_type, entity_id)
    values (
      staff_id,
      'new_order',
      'New order',
      'Order #' || short_id || ' was placed.',
      'order',
      new.id
    );
  end loop;

  return new;
end;
$$;

drop trigger if exists orders_notify_staff_new_order on public.orders;
create trigger orders_notify_staff_new_order
after insert on public.orders
for each row
execute function public.notify_staff_new_order();

create or replace function public.notify_staff_customer_message()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  sender_role public.app_role;
  staff_id uuid;
  order_id uuid;
  short_id text;
begin
  if new.sender_id is null then
    return new;
  end if;

  select coalesce((select role from public.profiles where id = new.sender_id), 'customer'::public.app_role)
  into sender_role;

  -- Only alert staff for messages coming from customers (not staff/admin).
  if sender_role in ('admin'::public.app_role, 'staff'::public.app_role) then
    return new;
  end if;

  select c.order_id into order_id from public.chats c where c.id = new.chat_id;
  if order_id is null then
    return new;
  end if;

  short_id := left(order_id::text, 8);

  for staff_id in
    select id from public.profiles where role in ('admin'::public.app_role, 'staff'::public.app_role)
  loop
    insert into public.staff_notifications (recipient_id, type, title, body, entity_type, entity_id)
    values (
      staff_id,
      'customer_message',
      'New message',
      'Customer sent a message on order #' || short_id || '.',
      'order',
      order_id
    );
  end loop;

  return new;
end;
$$;

drop trigger if exists chat_messages_notify_staff on public.chat_messages;
create trigger chat_messages_notify_staff
after insert on public.chat_messages
for each row
execute function public.notify_staff_customer_message();

-- Realtime (optional but recommended)
do $$
begin
  execute 'alter publication supabase_realtime add table public.staff_notifications';
exception
  when undefined_object then
    -- publication doesn't exist
    null;
  when duplicate_object then
    -- table already added
    null;
end $$;


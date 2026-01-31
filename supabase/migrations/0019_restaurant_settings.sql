-- Restaurant settings used by the Admin Dashboard (optional)
-- Safe additive migration: adds a singleton settings table with staff-only writes.

create extension if not exists "pgcrypto";

create table if not exists public.restaurant_settings (
  id uuid primary key default gen_random_uuid(),
  rest_name text,
  rest_phone text,
  is_open boolean not null default true,
  is_busy boolean not null default false,
  busy_note text,
  open_time text,
  close_time text,
  auto_cancel_min int not null default 0 check (auto_cancel_min >= 0),
  chat_close_hours int not null default 0 check (chat_close_hours >= 0),
  delivery_enabled boolean not null default true,
  pickup_enabled boolean not null default true,
  scheduled_orders_enabled boolean not null default false,
  cash_on_delivery_enabled boolean not null default false,
  sound_alerts boolean not null default true,
  profanity_filter boolean not null default true,
  updated_at timestamptz not null default now()
);

-- Keep updated_at fresh (reuses helper from 0001_init.sql if present).
do $$
begin
  if exists (select 1 from pg_proc where proname = 'set_updated_at' and pg_function_is_visible(oid)) then
    execute 'drop trigger if exists restaurant_settings_updated_at on public.restaurant_settings';
    execute 'create trigger restaurant_settings_updated_at before update on public.restaurant_settings for each row execute function public.set_updated_at()';
  end if;
end $$;

alter table public.restaurant_settings enable row level security;

-- Everyone can read (customer app may optionally show open/busy state).
drop policy if exists "restaurant_settings_read_all" on public.restaurant_settings;
create policy "restaurant_settings_read_all"
on public.restaurant_settings
for select
using (true);

-- Staff can write.
drop policy if exists "restaurant_settings_staff_insert" on public.restaurant_settings;
create policy "restaurant_settings_staff_insert"
on public.restaurant_settings
for insert
with check (public.is_staff());

drop policy if exists "restaurant_settings_staff_update" on public.restaurant_settings;
create policy "restaurant_settings_staff_update"
on public.restaurant_settings
for update
using (public.is_staff())
with check (public.is_staff());

drop policy if exists "restaurant_settings_staff_delete" on public.restaurant_settings;
create policy "restaurant_settings_staff_delete"
on public.restaurant_settings
for delete
using (public.is_staff());

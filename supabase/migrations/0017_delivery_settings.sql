-- Global delivery settings used by both admin dashboard and customer app.
-- Readable by all users; writable by staff only.

create extension if not exists "pgcrypto";

create table if not exists public.delivery_settings (
  id uuid primary key default gen_random_uuid(),
  base_fee numeric(10, 2) not null default 0 check (base_fee >= 0),
  free_radius_km numeric(10, 2) not null default 0 check (free_radius_km >= 0),
  per_km_fee_after_free_radius numeric(10, 2) not null default 0 check (per_km_fee_after_free_radius >= 0),
  minimum_order_amount numeric(10, 2) not null default 0 check (minimum_order_amount >= 0),
  max_delivery_distance_km numeric(10, 2) not null default 0 check (max_delivery_distance_km >= 0),
  updated_at timestamptz not null default now()
);

-- Keep updated_at fresh (reuses helper from 0001_init.sql if present).
do $$
begin
  if exists (select 1 from pg_proc where proname = 'set_updated_at' and pg_function_is_visible(oid)) then
    execute 'drop trigger if exists delivery_settings_updated_at on public.delivery_settings';
    execute 'create trigger delivery_settings_updated_at before update on public.delivery_settings for each row execute function public.set_updated_at()';
  end if;
end $$;

alter table public.delivery_settings enable row level security;

-- Anyone can read delivery settings (customers need to see delivery fees/minimums).
drop policy if exists "delivery_settings_read_all" on public.delivery_settings;
create policy "delivery_settings_read_all"
on public.delivery_settings
for select
using (true);

-- Staff can write.
drop policy if exists "delivery_settings_staff_insert" on public.delivery_settings;
create policy "delivery_settings_staff_insert"
on public.delivery_settings
for insert
with check (public.is_staff());

drop policy if exists "delivery_settings_staff_update" on public.delivery_settings;
create policy "delivery_settings_staff_update"
on public.delivery_settings
for update
using (public.is_staff())
with check (public.is_staff());

drop policy if exists "delivery_settings_staff_delete" on public.delivery_settings;
create policy "delivery_settings_staff_delete"
on public.delivery_settings
for delete
using (public.is_staff());


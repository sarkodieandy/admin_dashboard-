-- Finger Licking Restaurant – Bekwai (Customer App)
-- Core schema + RLS

create extension if not exists "pgcrypto";
create extension if not exists "citext";

-- =========
-- Enums
-- =========

do $$
begin
  if not exists (select 1 from pg_type where typname = 'app_role') then
    create type public.app_role as enum ('customer', 'staff', 'rider', 'admin');
  end if;
end $$;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'order_status') then
    create type public.order_status as enum (
      'placed',
      'confirmed',
      'preparing',
      'ready',
      'en_route',
      'delivered',
      'cancelled'
    );
  end if;
end $$;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'payment_method') then
    create type public.payment_method as enum ('cash', 'momo');
  end if;
end $$;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'payment_status') then
    create type public.payment_status as enum ('unpaid', 'pending', 'paid', 'failed', 'refunded');
  end if;
end $$;

-- =========
-- Helpers
-- =========

create or replace function public.now_utc()
returns timestamptz
language sql
stable
as $$
  select now();
$$;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- =========
-- Tables
-- =========

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text,
  phone text,
  default_delivery_note text,
  role public.app_role not null default 'customer'::public.app_role,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.current_role()
returns public.app_role
language sql
stable
as $$
  select coalesce((select role from public.profiles where id = auth.uid()), 'customer'::public.app_role);
$$;

create or replace function public.is_staff()
returns boolean
language sql
stable
as $$
  select public.current_role() in ('staff'::public.app_role, 'admin'::public.app_role);
$$;

create table if not exists public.addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  label text not null,
  address text not null,
  landmark text,
  lat double precision,
  lng double precision,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists addresses_user_id_idx on public.addresses(user_id);

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  is_active boolean not null default true,
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.menu_items (
  id uuid primary key default gen_random_uuid(),
  category_id uuid references public.categories(id) on delete set null,
  name text not null,
  description text,
  base_price numeric(10, 2) not null check (base_price >= 0),
  image_url text,
  spice_level int not null default 0 check (spice_level between 0 and 3),
  is_active boolean not null default true,
  is_sold_out boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists menu_items_category_id_idx on public.menu_items(category_id);
create index if not exists menu_items_active_idx on public.menu_items(is_active) where is_active = true;

-- Optional (but used by the app): multiple images per item
create table if not exists public.menu_item_images (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.menu_items(id) on delete cascade,
  image_url text not null,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists menu_item_images_item_id_idx on public.menu_item_images(item_id);

create table if not exists public.item_variants (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.menu_items(id) on delete cascade,
  name text not null,
  price_delta numeric(10, 2) not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists item_variants_item_id_idx on public.item_variants(item_id);

create table if not exists public.item_addons (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.menu_items(id) on delete cascade,
  name text not null,
  price numeric(10, 2) not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists item_addons_item_id_idx on public.item_addons(item_id);

create table if not exists public.promos (
  id uuid primary key default gen_random_uuid(),
  code citext not null unique,
  type text not null check (type in ('percent', 'fixed')),
  value numeric(10, 2) not null check (value >= 0),
  min_subtotal numeric(10, 2) not null default 0 check (min_subtotal >= 0),
  expires_at timestamptz,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete restrict,
  status public.order_status not null default 'placed'::public.order_status,
  subtotal numeric(10, 2) not null check (subtotal >= 0),
  delivery_fee numeric(10, 2) not null check (delivery_fee >= 0),
  discount numeric(10, 2) not null default 0 check (discount >= 0),
  total numeric(10, 2) not null check (total >= 0),
  payment_method public.payment_method not null default 'cash'::public.payment_method,
  payment_status public.payment_status not null default 'unpaid'::public.payment_status,
  address_snapshot jsonb not null,
  scheduled_for timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists orders_user_id_created_at_idx on public.orders(user_id, created_at desc);
create index if not exists orders_status_idx on public.orders(status);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  item_id uuid references public.menu_items(id) on delete set null,
  name_snapshot text not null,
  variant_snapshot text,
  addons_snapshot jsonb not null default '[]'::jsonb,
  qty int not null check (qty > 0),
  price numeric(10, 2) not null check (price >= 0),
  created_at timestamptz not null default now()
);

create index if not exists order_items_order_id_idx on public.order_items(order_id);

create table if not exists public.order_status_events (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  status public.order_status not null,
  created_at timestamptz not null default now()
);

create index if not exists order_status_events_order_id_idx on public.order_status_events(order_id, created_at asc);

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  rating int not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now(),
  unique(order_id, user_id)
);

-- Optional (but used by the app): item-level ratings per order review
create table if not exists public.review_items (
  id uuid primary key default gen_random_uuid(),
  review_id uuid not null references public.reviews(id) on delete cascade,
  item_id uuid references public.menu_items(id) on delete set null,
  rating int not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now()
);

create index if not exists review_items_review_id_idx on public.review_items(review_id);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  body text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists notifications_user_id_created_at_idx on public.notifications(user_id, created_at desc);

create table if not exists public.chats (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(order_id)
);

create index if not exists chats_order_id_idx on public.chats(order_id);

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid not null references public.chats(id) on delete cascade,
  sender_id uuid references auth.users(id) on delete set null,
  message text not null check (char_length(message) <= 2000),
  created_at timestamptz not null default now()
);

create index if not exists chat_messages_chat_id_created_at_idx on public.chat_messages(chat_id, created_at asc);

-- =========
-- Triggers
-- =========

drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

drop trigger if exists addresses_updated_at on public.addresses;
create trigger addresses_updated_at
before update on public.addresses
for each row
execute function public.set_updated_at();

drop trigger if exists categories_updated_at on public.categories;
create trigger categories_updated_at
before update on public.categories
for each row
execute function public.set_updated_at();

drop trigger if exists menu_items_updated_at on public.menu_items;
create trigger menu_items_updated_at
before update on public.menu_items
for each row
execute function public.set_updated_at();

drop trigger if exists orders_updated_at on public.orders;
create trigger orders_updated_at
before update on public.orders
for each row
execute function public.set_updated_at();

-- Create profile row automatically
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, name, phone, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', null),
    coalesce(new.raw_user_meta_data->>'phone', null),
    'customer'::public.app_role
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- Ensure order lifecycle rules + audit trail.
create or replace function public.validate_order_status_transition()
returns trigger
language plpgsql
as $$
declare
  allowed boolean := false;
begin
  if tg_op <> 'UPDATE' then
    return new;
  end if;

  if new.status = old.status then
    return new;
  end if;

  case old.status
    when 'placed' then
      allowed := new.status in ('confirmed', 'cancelled');
    when 'confirmed' then
      allowed := new.status in ('preparing', 'cancelled');
    when 'preparing' then
      allowed := new.status in ('ready', 'cancelled');
    when 'ready' then
      allowed := new.status in ('en_route', 'cancelled');
    when 'en_route' then
      allowed := new.status in ('delivered', 'cancelled');
    when 'delivered' then
      allowed := false;
    when 'cancelled' then
      allowed := false;
    else
      allowed := false;
  end case;

  if not allowed then
    raise exception 'Invalid order status transition: % -> %', old.status, new.status;
  end if;

  insert into public.order_status_events(order_id, status) values (new.id, new.status);
  return new;
end;
$$;

drop trigger if exists orders_status_transition on public.orders;
create trigger orders_status_transition
before update of status on public.orders
for each row
execute function public.validate_order_status_transition();

-- Initial order status event
create or replace function public.log_initial_order_status()
returns trigger
language plpgsql
as $$
begin
  insert into public.order_status_events(order_id, status) values (new.id, new.status);
  insert into public.chats(order_id) values (new.id) on conflict do nothing;
  return new;
end;
$$;

drop trigger if exists orders_initial_status_event on public.orders;
create trigger orders_initial_status_event
after insert on public.orders
for each row
execute function public.log_initial_order_status();

-- =========
-- RLS
-- =========

alter table public.profiles enable row level security;
alter table public.addresses enable row level security;
alter table public.categories enable row level security;
alter table public.menu_items enable row level security;
alter table public.menu_item_images enable row level security;
alter table public.item_variants enable row level security;
alter table public.item_addons enable row level security;
alter table public.promos enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.order_status_events enable row level security;
alter table public.reviews enable row level security;
alter table public.review_items enable row level security;
alter table public.notifications enable row level security;
alter table public.chats enable row level security;
alter table public.chat_messages enable row level security;

-- profiles
drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
on public.profiles
for select
using (id = auth.uid());

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles
for update
using (id = auth.uid())
with check (id = auth.uid());

-- addresses
drop policy if exists "addresses_crud_own" on public.addresses;
create policy "addresses_crud_own"
on public.addresses
for all
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- categories
drop policy if exists "categories_read_active" on public.categories;
create policy "categories_read_active"
on public.categories
for select
using (is_active = true);

drop policy if exists "categories_manage_staff" on public.categories;
create policy "categories_manage_staff"
on public.categories
for insert with check (public.is_staff());

-- menu_items
drop policy if exists "menu_items_read_active" on public.menu_items;
create policy "menu_items_read_active"
on public.menu_items
for select
using (is_active = true);

drop policy if exists "menu_items_manage_staff" on public.menu_items;
create policy "menu_items_manage_staff"
on public.menu_items
for insert with check (public.is_staff());

-- menu_item_images
drop policy if exists "menu_item_images_read" on public.menu_item_images;
create policy "menu_item_images_read"
on public.menu_item_images
for select
using (
  exists (
    select 1 from public.menu_items mi
    where mi.id = item_id and mi.is_active = true
  )
);

-- item_variants
drop policy if exists "item_variants_read" on public.item_variants;
create policy "item_variants_read"
on public.item_variants
for select
using (
  exists (
    select 1 from public.menu_items mi
    where mi.id = item_id and mi.is_active = true
  )
);

-- item_addons
drop policy if exists "item_addons_read" on public.item_addons;
create policy "item_addons_read"
on public.item_addons
for select
using (
  exists (
    select 1 from public.menu_items mi
    where mi.id = item_id and mi.is_active = true
  )
);

-- promos
drop policy if exists "promos_read_active" on public.promos;
create policy "promos_read_active"
on public.promos
for select
using (is_active = true and (expires_at is null or expires_at > now()));

-- orders
drop policy if exists "orders_select_own" on public.orders;
create policy "orders_select_own"
on public.orders
for select
using (user_id = auth.uid());

drop policy if exists "orders_insert_own_placed" on public.orders;
create policy "orders_insert_own_placed"
on public.orders
for insert
with check (
  user_id = auth.uid()
  and status = 'placed'::public.order_status
);

drop policy if exists "orders_update_staff_only" on public.orders;
create policy "orders_update_staff_only"
on public.orders
for update
using (public.is_staff())
with check (public.is_staff());

-- order_items
drop policy if exists "order_items_select_own" on public.order_items;
create policy "order_items_select_own"
on public.order_items
for select
using (
  exists (
    select 1 from public.orders o
    where o.id = order_id and o.user_id = auth.uid()
  )
);

drop policy if exists "order_items_insert_own_while_placed" on public.order_items;
create policy "order_items_insert_own_while_placed"
on public.order_items
for insert
with check (
  exists (
    select 1 from public.orders o
    where o.id = order_id and o.user_id = auth.uid() and o.status = 'placed'::public.order_status
  )
);

-- order_status_events
drop policy if exists "order_status_events_select_own" on public.order_status_events;
create policy "order_status_events_select_own"
on public.order_status_events
for select
using (
  exists (
    select 1 from public.orders o
    where o.id = order_id and o.user_id = auth.uid()
  )
);

drop policy if exists "order_status_events_insert_initial_own" on public.order_status_events;
create policy "order_status_events_insert_initial_own"
on public.order_status_events
for insert
with check (
  status = 'placed'::public.order_status
  and exists (
    select 1 from public.orders o
    where o.id = order_id and o.user_id = auth.uid()
  )
);

drop policy if exists "order_status_events_insert_staff_only" on public.order_status_events;
create policy "order_status_events_insert_staff_only"
on public.order_status_events
for insert
with check (public.is_staff());

-- reviews
drop policy if exists "reviews_select_own" on public.reviews;
create policy "reviews_select_own"
on public.reviews
for select
using (user_id = auth.uid());

drop policy if exists "reviews_insert_for_delivered" on public.reviews;
create policy "reviews_insert_for_delivered"
on public.reviews
for insert
with check (
  user_id = auth.uid()
  and exists (
    select 1 from public.orders o
    where o.id = order_id and o.user_id = auth.uid() and o.status = 'delivered'::public.order_status
  )
);

-- review_items
drop policy if exists "review_items_select_own" on public.review_items;
create policy "review_items_select_own"
on public.review_items
for select
using (
  exists (
    select 1
    from public.reviews r
    where r.id = review_id and r.user_id = auth.uid()
  )
);

drop policy if exists "review_items_insert_own" on public.review_items;
create policy "review_items_insert_own"
on public.review_items
for insert
with check (
  exists (
    select 1
    from public.reviews r
    where r.id = review_id and r.user_id = auth.uid()
  )
);

-- notifications
drop policy if exists "notifications_select_own" on public.notifications;
create policy "notifications_select_own"
on public.notifications
for select
using (user_id = auth.uid());

drop policy if exists "notifications_update_own" on public.notifications;
create policy "notifications_update_own"
on public.notifications
for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- chats
drop policy if exists "chats_select_own" on public.chats;
create policy "chats_select_own"
on public.chats
for select
using (
  exists (
    select 1 from public.orders o
    where o.id = order_id and o.user_id = auth.uid()
  )
  or public.is_staff()
);

drop policy if exists "chats_insert_own" on public.chats;
create policy "chats_insert_own"
on public.chats
for insert
with check (
  public.is_staff()
  or exists (
    select 1 from public.orders o
    where o.id = order_id and o.user_id = auth.uid()
  )
);

-- chat_messages
drop policy if exists "chat_messages_select_participant" on public.chat_messages;
create policy "chat_messages_select_participant"
on public.chat_messages
for select
using (
  exists (
    select 1
    from public.chats c
    join public.orders o on o.id = c.order_id
    where c.id = chat_id and o.user_id = auth.uid()
  )
  or public.is_staff()
);

drop policy if exists "chat_messages_insert_participant" on public.chat_messages;
create policy "chat_messages_insert_participant"
on public.chat_messages
for insert
with check (
  sender_id = auth.uid()
  and (
    exists (
      select 1
      from public.chats c
      join public.orders o on o.id = c.order_id
      where c.id = chat_id and o.user_id = auth.uid()
    )
    or public.is_staff()
  )
);

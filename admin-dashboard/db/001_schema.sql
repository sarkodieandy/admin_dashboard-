-- Finger Licking Restaurant Admin Dashboard schema
-- Apply to a fresh Supabase project (SQL Editor), then enable Realtime on key tables.
--
-- Notes:
-- - Uses anon key + RLS (no service key in client).
-- - Staff access is scoped by profiles.branch_id.
-- - Customer + rider policies are included for the mobile apps.

create extension if not exists pgcrypto;

-- =========
-- Helpers
-- =========
create or replace function public.current_user_role()
returns text
language sql
stable
as $$
  select coalesce((select role from public.profiles where id = auth.uid()), 'staff');
$$;

create or replace function public.current_branch_id()
returns uuid
language sql
stable
as $$
  select (select branch_id from public.profiles where id = auth.uid());
$$;

create or replace function public.is_staff()
returns boolean
language sql
stable
as $$
  select public.current_user_role() in ('owner','admin','staff');
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
as $$
  select public.current_user_role() in ('owner','admin');
$$;

-- =========
-- Orgs / Auth
-- =========
create table if not exists public.branches (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  address text,
  lat double precision,
  lng double precision,
  is_open boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text,
  phone text,
  role text not null check (role in ('owner','admin','staff','customer','rider')),
  branch_id uuid references public.branches(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists profiles_branch_id_idx on public.profiles(branch_id);

-- =========
-- Menu
-- =========
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(id) on delete cascade,
  name text not null,
  sort_order int not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create index if not exists categories_branch_id_sort_order_idx on public.categories(branch_id, sort_order asc);

create table if not exists public.menu_items (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(id) on delete cascade,
  category_id uuid references public.categories(id) on delete set null,
  name text not null,
  description text,
  price numeric(10,2) not null check (price >= 0),
  image_url text,
  is_available boolean not null default true,
  prep_time_min int,
  featured boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists menu_items_branch_id_created_at_idx on public.menu_items(branch_id, created_at desc);
create index if not exists menu_items_branch_id_category_id_idx on public.menu_items(branch_id, category_id);

create table if not exists public.addons (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(id) on delete cascade,
  name text not null,
  price numeric(10,2) not null check (price >= 0),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.item_addons (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.menu_items(id) on delete cascade,
  addon_id uuid not null references public.addons(id) on delete cascade,
  unique(item_id, addon_id)
);

-- =========
-- Orders
-- =========
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(id) on delete cascade,
  customer_id uuid not null references auth.users(id) on delete cascade,
  status text not null check (status in ('new','confirmed','preparing','ready','out_for_delivery','completed','cancelled')),
  type text not null check (type in ('delivery','pickup')),
  subtotal numeric(10,2) not null default 0,
  delivery_fee numeric(10,2) not null default 0,
  discount numeric(10,2) not null default 0,
  total numeric(10,2) not null default 0,
  payment_method text not null check (payment_method in ('cash','momo','paystack')),
  payment_status text not null check (payment_status in ('unpaid','pending','paid','failed','refunded')),
  address_text text,
  address_lat double precision,
  address_lng double precision,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists orders_branch_id_created_at_idx on public.orders(branch_id, created_at desc);
create index if not exists orders_branch_id_status_idx on public.orders(branch_id, status);
create index if not exists orders_created_at_status_idx on public.orders(created_at desc, status);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists orders_set_updated_at on public.orders;
create trigger orders_set_updated_at
before update on public.orders
for each row execute function public.set_updated_at();

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  item_id uuid references public.menu_items(id) on delete set null,
  name_snapshot text not null,
  price_snapshot numeric(10,2) not null,
  qty int not null check (qty > 0),
  addons_snapshot_json jsonb
);

create index if not exists order_items_order_id_idx on public.order_items(order_id);

-- =========
-- Delivery / Riders (optional MVP)
-- =========
create table if not exists public.riders (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text,
  status text not null default 'offline' check (status in ('offline','online','busy')),
  last_lat double precision,
  last_lng double precision,
  created_at timestamptz not null default now()
);

create table if not exists public.deliveries (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references public.orders(id) on delete cascade,
  rider_id uuid references public.riders(id) on delete set null,
  status text not null default 'assigned' check (status in ('assigned','picked','enroute','delivered','cancelled')),
  assigned_at timestamptz,
  picked_at timestamptz,
  delivered_at timestamptz
);

create index if not exists deliveries_rider_id_idx on public.deliveries(rider_id);

-- =========
-- Promotions / Reviews / Support
-- =========
create table if not exists public.coupons (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(id) on delete cascade,
  code text not null,
  type text not null check (type in ('percent','fixed')),
  value numeric(10,2) not null check (value >= 0),
  min_order numeric(10,2) not null default 0,
  starts_at timestamptz,
  ends_at timestamptz,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique(branch_id, code)
);

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  rating_food int check (rating_food between 1 and 5),
  rating_delivery int check (rating_delivery between 1 and 5),
  comment text,
  created_at timestamptz not null default now()
);

create index if not exists reviews_order_id_idx on public.reviews(order_id);

create table if not exists public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  order_id uuid references public.orders(id) on delete set null,
  customer_id uuid references auth.users(id) on delete set null,
  type text,
  message text not null,
  status text not null default 'open' check (status in ('open','in_progress','resolved')),
  created_at timestamptz not null default now()
);

create index if not exists support_tickets_status_created_at_idx on public.support_tickets(status, created_at desc);

-- =========
-- Order-based chat only
-- =========
create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  branch_id uuid not null references public.branches(id) on delete cascade,
  type text not null check (type in ('customer_restaurant','customer_rider','restaurant_rider')),
  customer_id uuid not null references auth.users(id) on delete cascade,
  rider_id uuid references public.riders(id) on delete set null,
  created_at timestamptz not null default now(),
  closed_at timestamptz,
  unique(order_id, type)
);

create index if not exists conversations_branch_id_created_at_idx on public.conversations(branch_id, created_at desc);
create index if not exists conversations_order_id_idx on public.conversations(order_id);
create index if not exists conversations_closed_at_idx on public.conversations(closed_at);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  order_id uuid not null references public.orders(id) on delete cascade,
  branch_id uuid not null references public.branches(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  sender_role text not null check (sender_role in ('customer','staff','rider')),
  message_type text not null check (message_type in ('text','image','system')),
  text text,
  attachment_url text,
  created_at timestamptz not null default now(),
  read_at timestamptz
);

create index if not exists messages_conversation_id_created_at_idx on public.messages(conversation_id, created_at asc);
create index if not exists messages_branch_id_created_at_idx on public.messages(branch_id, created_at desc);

create table if not exists public.message_reads (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.messages(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  read_at timestamptz not null default now(),
  unique(message_id, user_id)
);

create table if not exists public.chat_templates (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(id) on delete cascade,
  title text not null,
  body text not null,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

-- =========
-- Delivery settings
-- =========
create table if not exists public.delivery_settings (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid not null unique references public.branches(id) on delete cascade,
  base_fee numeric(10,2) not null default 0,
  free_radius_km numeric(10,2) not null default 0,
  per_km_fee_after_free_radius numeric(10,2) not null default 0,
  minimum_order_amount numeric(10,2) not null default 0,
  max_delivery_distance_km numeric(10,2) not null default 0,
  updated_at timestamptz not null default now()
);

drop trigger if exists delivery_settings_set_updated_at on public.delivery_settings;
create trigger delivery_settings_set_updated_at
before update on public.delivery_settings
for each row execute function public.set_updated_at();

-- =========
-- Notifications + Audit
-- =========
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(id) on delete cascade,
  type text not null check (type in ('order_new','message_unread','payment_failed')),
  title text not null,
  body text,
  entity text,
  entity_id uuid,
  created_at timestamptz not null default now(),
  read_at timestamptz
);

create index if not exists notifications_branch_id_created_at_idx on public.notifications(branch_id, created_at desc);

create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references auth.users(id) on delete set null,
  actor_role text,
  action text not null,
  entity text not null,
  entity_id uuid,
  before jsonb,
  after jsonb,
  created_at timestamptz not null default now()
);


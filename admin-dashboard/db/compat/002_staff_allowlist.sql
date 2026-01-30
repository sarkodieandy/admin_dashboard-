-- Admin Dashboard additions for the existing Flutter customer app schema.
--
-- SAFE TO APPLY: creates a new table + updates the existing signup trigger.
-- Use this if you want "admin email + password" logins that are separated
-- from customer signups by email allowlisting.

create table if not exists public.staff_allowlist (
  email text primary key,
  role public.app_role not null,
  created_at timestamptz not null default now(),
  constraint staff_allowlist_role_chk check (role in ('staff'::public.app_role, 'admin'::public.app_role))
);

alter table public.staff_allowlist enable row level security;

drop policy if exists "staff_allowlist_select_staff" on public.staff_allowlist;
create policy "staff_allowlist_select_staff"
on public.staff_allowlist
for select
using (public.is_staff());

drop policy if exists "staff_allowlist_manage_admin" on public.staff_allowlist;
create policy "staff_allowlist_manage_admin"
on public.staff_allowlist
for all
using (public.current_role() = 'admin'::public.app_role)
with check (public.current_role() = 'admin'::public.app_role);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  resolved_role public.app_role;
begin
  select sa.role
  into resolved_role
  from public.staff_allowlist sa
  where lower(sa.email) = lower(new.email)
  limit 1;

  insert into public.profiles (id, name, phone, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', null),
    coalesce(new.raw_user_meta_data->>'phone', null),
    coalesce(resolved_role, 'customer'::public.app_role)
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

-- Optional backfill: upgrade any existing users that are allowlisted.
update public.profiles p
set role = sa.role
from public.staff_allowlist sa
join auth.users u on u.id = p.id
where lower(sa.email) = lower(u.email)
  and p.role = 'customer'::public.app_role;


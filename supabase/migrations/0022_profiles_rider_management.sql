-- Allow staff/admin to update rider profiles from the admin dashboard.

create extension if not exists "pgcrypto";

alter table public.profiles enable row level security;

drop policy if exists "profiles_update_staff" on public.profiles;
create policy "profiles_update_staff"
on public.profiles
for update
using (
  public.is_staff()
  and role = 'rider'::public.app_role
)
with check (
  public.is_staff()
  and role = 'rider'::public.app_role
);

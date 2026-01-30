-- Harden profiles security + reduce "missing profile" edge cases.
--
-- Key fixes:
-- 1) Allow authenticated users to insert their own profile row (customer only),
--    so the client can self-heal if the auth trigger didn't run for any reason.
-- 2) Prevent customers from escalating privileges by updating profiles.role.
-- 3) Allow staff/admin to read profiles (needed for future ops dashboards).

-- profiles: customer insert (self only)
drop policy if exists "profiles_insert_own_customer" on public.profiles;
create policy "profiles_insert_own_customer"
on public.profiles
for insert
with check (
  id = auth.uid()
  and role = 'customer'::public.app_role
);

-- profiles: staff can read all profiles (future dashboard needs customer names)
drop policy if exists "profiles_select_staff" on public.profiles;
create policy "profiles_select_staff"
on public.profiles
for select
using (public.is_staff());

-- Block non-admin role changes (prevents privilege escalation)
create or replace function public.prevent_profile_role_escalation()
returns trigger
language plpgsql
as $$
begin
  if new.role is distinct from old.role then
    -- Server-side contexts (SQL editor / service role) may manage roles.
    if auth.uid() is null or auth.role() = 'service_role' then
      return new;
    end if;

    -- Only admins may change roles from the client.
    if public.current_role() = 'admin'::public.app_role then
      return new;
    end if;

    raise exception 'Not allowed to change profile role';
  end if;

  return new;
end;
$$;

drop trigger if exists profiles_prevent_role_escalation on public.profiles;
create trigger profiles_prevent_role_escalation
before update of role on public.profiles
for each row
execute function public.prevent_profile_role_escalation();


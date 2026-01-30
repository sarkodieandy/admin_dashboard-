-- Signup/Profile reliability
--
-- 1) Ensure the auth->profiles trigger exists (in case it wasn't created).
-- 2) Backfill missing profiles for existing auth users.

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

-- Backfill: profiles row for any existing auth user missing one.
insert into public.profiles (id, name, phone, role)
select
  u.id,
  coalesce(u.raw_user_meta_data->>'name', null),
  coalesce(u.raw_user_meta_data->>'phone', null),
  'customer'::public.app_role
from auth.users u
where not exists (
  select 1 from public.profiles p where p.id = u.id
)
on conflict (id) do nothing;


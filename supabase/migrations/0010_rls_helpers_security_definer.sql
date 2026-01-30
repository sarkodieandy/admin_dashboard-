-- Fix RLS helper functions to avoid policy recursion.
--
-- Problem: `profiles_select_staff` (and other policies) call `public.is_staff()`,
-- which calls `public.current_role()`, which reads from `public.profiles`.
-- When evaluated as part of RLS on `public.profiles`, that can trigger
-- `infinite recursion detected in policy for relation "profiles"`.
--
-- Solution: make the role helper functions SECURITY DEFINER so they can read
-- `public.profiles` without invoking RLS.

create or replace function public.current_role()
returns public.app_role
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select role from public.profiles where id = auth.uid()),
    'customer'::public.app_role
  );
$$;

create or replace function public.is_staff()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.current_role() in ('staff'::public.app_role, 'admin'::public.app_role);
$$;


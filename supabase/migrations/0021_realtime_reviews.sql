-- Realtime publication: include reviews so the admin dashboard updates live.

do $$
declare
  pub_oid oid;
begin
  select oid into pub_oid from pg_publication where pubname = 'supabase_realtime';
  if pub_oid is null then
    return;
  end if;

  -- public.reviews
  begin
    execute 'alter publication supabase_realtime add table public.reviews';
  exception
    when duplicate_object then null;
    when undefined_object then null;
  end;

  -- public.review_items (optional; supports item-level ratings)
  begin
    execute 'alter publication supabase_realtime add table public.review_items';
  exception
    when duplicate_object then null;
    when undefined_object then null;
  end;
end $$;


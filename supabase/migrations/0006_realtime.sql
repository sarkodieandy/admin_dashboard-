-- Realtime publication (order tracking + chat + inbox)
-- Note: Supabase UI can also enable Realtime; this migration makes it deterministic.

do $$
declare
  pub_oid oid;
begin
  select oid into pub_oid from pg_publication where pubname = 'supabase_realtime';
  if pub_oid is null then
    return;
  end if;

  -- public.orders
  if not exists (
    select 1
    from pg_publication_rel pr
    join pg_class c on c.oid = pr.prrelid
    join pg_namespace n on n.oid = c.relnamespace
    where pr.prpubid = pub_oid and n.nspname = 'public' and c.relname = 'orders'
  ) then
    execute 'alter publication supabase_realtime add table public.orders';
  end if;

  -- public.order_status_events
  if not exists (
    select 1
    from pg_publication_rel pr
    join pg_class c on c.oid = pr.prrelid
    join pg_namespace n on n.oid = c.relnamespace
    where pr.prpubid = pub_oid and n.nspname = 'public' and c.relname = 'order_status_events'
  ) then
    execute 'alter publication supabase_realtime add table public.order_status_events';
  end if;

  -- public.chat_messages
  if not exists (
    select 1
    from pg_publication_rel pr
    join pg_class c on c.oid = pr.prrelid
    join pg_namespace n on n.oid = c.relnamespace
    where pr.prpubid = pub_oid and n.nspname = 'public' and c.relname = 'chat_messages'
  ) then
    execute 'alter publication supabase_realtime add table public.chat_messages';
  end if;

  -- public.notifications
  if not exists (
    select 1
    from pg_publication_rel pr
    join pg_class c on c.oid = pr.prrelid
    join pg_namespace n on n.oid = c.relnamespace
    where pr.prpubid = pub_oid and n.nspname = 'public' and c.relname = 'notifications'
  ) then
    execute 'alter publication supabase_realtime add table public.notifications';
  end if;
end $$;


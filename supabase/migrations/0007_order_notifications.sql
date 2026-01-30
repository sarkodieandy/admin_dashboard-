-- In-app notifications for order status updates

create or replace function public.notify_order_status_event()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  customer_id uuid;
  title text := 'Order update';
  body text;
begin
  select user_id into customer_id from public.orders where id = new.order_id;
  if customer_id is null then
    return new;
  end if;

  body := case new.status
    when 'placed'::public.order_status then 'We’ve received your order. We’ll confirm soon.'
    when 'confirmed'::public.order_status then 'Order confirmed — kitchen is starting.'
    when 'preparing'::public.order_status then 'Your food is being prepared 🍲'
    when 'ready'::public.order_status then 'Packed and ready. Dispatch is next.'
    when 'en_route'::public.order_status then 'Rider is on the way 🛵'
    when 'delivered'::public.order_status then 'Delivered — enjoy your meal!'
    when 'cancelled'::public.order_status then 'Your order was cancelled.'
    else 'Order updated.'
  end;

  insert into public.notifications(user_id, title, body) values (customer_id, title, body);
  return new;
end;
$$;

drop trigger if exists order_status_notify on public.order_status_events;
create trigger order_status_notify
after insert on public.order_status_events
for each row
execute function public.notify_order_status_event();


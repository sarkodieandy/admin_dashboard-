-- Paystack payment support.
--
-- Adds `paystack` as a payment method and stores the Paystack reference on orders.

do $$
begin
  if not exists (
    select 1
    from pg_enum
    where enumtypid = 'public.payment_method'::regtype
      and enumlabel = 'paystack'
  ) then
    alter type public.payment_method add value 'paystack';
  end if;
end $$;

alter table public.orders
add column if not exists payment_reference text;

create unique index if not exists orders_payment_reference_uniq
on public.orders (payment_reference)
where payment_reference is not null;


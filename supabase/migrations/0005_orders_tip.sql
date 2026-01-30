-- Optional tip support (customer app)

alter table public.orders
add column if not exists tip numeric(10, 2) not null default 0 check (tip >= 0);


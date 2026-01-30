-- Seed delivery_settings singleton row with sensible defaults.
-- Safe to run multiple times.

insert into public.delivery_settings (
  base_fee,
  free_radius_km,
  per_km_fee_after_free_radius,
  minimum_order_amount,
  max_delivery_distance_km
)
select
  10.00,
  0.00,
  0.00,
  40.00,
  0.00
where not exists (select 1 from public.delivery_settings);


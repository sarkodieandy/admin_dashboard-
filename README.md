# Finger Licking — Customer App (Bekwai, Ghana)

Production-ready customer mobile app for **Finger Licking Restaurant – Bekwai**.

## Stack

- Flutter (stable)
- Provider state management
- Supabase: Auth + Postgres + Storage + Realtime + Edge Functions

## What’s implemented

- Auth: email/password + anonymous (guest) browsing
- Profile: name, phone, default delivery note
- Menu: categories, promos, popular, search, item detail (variants + add-ons + sold-out)
- Cart: persistent (SharedPreferences), promo codes, minimum order, delivery fee
- Checkout: address book, schedule order, tip, cash + mock MoMo
- Orders: create order in Supabase, order history, realtime tracking timeline
- Chat: customer ↔ restaurant (text only) per order (realtime)
- Inbox: in-app notifications (realtime) + backend trigger on order status events

## Setup

### 1) Supabase (schema + RLS)

1. Create/open your Supabase project.
2. In Supabase SQL Editor, run core migrations:
   - `supabase/migrations/0001_init.sql`
   - `supabase/migrations/0003_storage.sql`
   - `supabase/migrations/0004_staff_policies.sql`
   - `supabase/migrations/0005_orders_tip.sql`
   - `supabase/migrations/0006_realtime.sql`
   - `supabase/migrations/0007_order_notifications.sql`
   - `supabase/migrations/0008_profiles_hardening.sql`
   - `supabase/migrations/0010_rls_helpers_security_definer.sql`
   - `supabase/migrations/0011_api_grants.sql`
   - `supabase/migrations/0012_profiles_backfill_and_trigger.sql`

If you hit `infinite recursion detected in policy for relation "profiles"`, make sure you ran `supabase/migrations/0010_rls_helpers_security_definer.sql` (it fixes role helper functions used by RLS).

If menu/home queries fail with `permission denied for relation ...` when browsing while logged out, run `supabase/migrations/0011_api_grants.sql` (it grants the required API role privileges; RLS still applies).

3. Seed menu data (pick one):
   - `supabase/migrations/0002_seed.sql` (uses Supabase Storage object paths)
   - `supabase/migrations/0009_seed_mock_menu_remote_images.sql` (uses real remote image URLs for quick setup)
   - If you previously used an older `0009` and images don’t load, run `supabase/migrations/0013_fix_remote_menu_images.sql`

Auth settings:
- Enable Email/Password sign-in
- Enable Anonymous sign-ins (for guest mode)

### 2) Storage (menu images)

Bucket: `menu-images` (created by `0003_storage.sql`)

If you used `supabase/migrations/0009_seed_mock_menu_remote_images.sql`, you can skip this step for now (it uses remote image URLs).

Upload images to match seeded paths (examples):
- `menu/chicken_jollof/main.jpg`
- `menu/chicken_jollof/1.jpg`
- `menu/fried_rice_chicken/main.jpg`

### 3) Edge Functions (stubs)

Functions live in `supabase/functions/`:
- `create-order` (server-side order creation stub; app falls back to direct insert if not deployed)
- `notify` (notification stub)

Deploy with Supabase CLI:

```bash
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=YOUR_SERVICE_ROLE_KEY
supabase functions deploy create-order
supabase functions deploy notify
```

### 4) Run the Flutter app

```bash
flutter pub get
flutter run
```

Supabase URL + anon key are currently set in `lib/core/env/app_env.dart`.  
You can override them at runtime:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

## Notes

- Realtime tracking relies on tables being in the `supabase_realtime` publication (handled by `0006_realtime.sql`).
- Order status transitions are enforced in DB (`orders_status_transition` trigger) and logged in `order_status_events`.
- Status updates should be done by staff/Edge Functions only (customer RLS prevents updating `orders.status`).

# Finger Licking Restaurant — Admin Dashboard

Production-ready **Restaurant Admin Dashboard** (Next.js App Router + TypeScript + Tailwind + Supabase) for managing a food delivery operation.

## What’s Included (Scaffold + Working Core)

**Pages**
- Dashboard overview: KPI cards + charts + recent orders + unread chats
- Orders: status pipeline tabs + filters + order drawer + CSV export + realtime updates
- Chats (order-based): inbox list + thread + order context panel + realtime updates + attachment upload (Storage)
- Menu: categories + ordering controls + items table + item editor + image upload (Storage)
- Delivery settings: fee rules form stored in Supabase
- Placeholders for Customers / Riders / Promotions / Reviews / Staff / Analytics / Notifications

**UX system**
- Premium neutral UI, soft borders, rounded 16px, subtle shadows
- Sidebar (collapsible) + responsive drawer on small screens
- Top header: global search (UI), notifications, user menu
- Loading skeletons + empty states + toasts

**Realtime**
- Orders updates: `orders` table changes invalidate the current pipeline query + dashboard widgets
- Messages inserts: active conversation stream updates the thread + inbox list

## Information Architecture (Sidebar)
1) Dashboard  
2) Orders  
3) Chats (Order Chats)  
4) Menu  
5) Customers (scaffold)  
6) Riders (scaffold)  
7) Delivery Settings  
8) Promotions (scaffold)  
9) Reviews & Support (scaffold)  
10) Staff & Roles (scaffold)  
11) Analytics (scaffold)  
12) Notifications (scaffold)

## Database (Supabase / Postgres)

SQL lives in `db/`:
- `db/compat/001_admin_additions.sql` — safe additions for your **existing** customer app schema (recommended)
- `db/compat/002_staff_allowlist.sql` — optional allowlist so only admin/staff emails become staff in `profiles`
- `db/001_schema.sql` / `db/002_rls.sql` / `db/003_seed.sql` — full standalone schema for a **new** Supabase project (do not apply to your existing app DB)

### Storage buckets
Create these buckets in Supabase Storage:
- `menu-images` (public recommended for quick UI)
- `chat-attachments` (public or use signed URLs)

### Realtime
Enable Realtime for:
- `orders`
- `chat_messages`
- (optional) `support_tickets`, `notifications`

## How to Run Locally

### 1) Install deps
```bash
cd admin-dashboard
npm install
```

### 2) Create `.env.local`
Copy `admin-dashboard/.env.example` to `admin-dashboard/.env.local` and fill:
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`

### 3) Create/Configure a Supabase project
If you already have the Flutter customer app schema in this repo (`supabase/migrations/*`), **do not** run the standalone admin schema — it will conflict because tables like `profiles`, `orders`, `menu_items`, etc already exist.

Instead, in Supabase SQL Editor run:
1) `admin-dashboard/db/compat/001_admin_additions.sql`
2) (optional) `admin-dashboard/db/compat/002_staff_allowlist.sql` (recommended if you want strict admin-only logins)

Then:
- Create Storage buckets: `menu-images`, `chat-attachments`
- Turn on Realtime for `orders` + `chat_messages`

### 4) Create a staff user (owner/admin/staff)
In Supabase Auth:
- Create a user via Email/Password

If you ran `db/compat/002_staff_allowlist.sql`:
- Insert the staff email into `public.staff_allowlist` **before** signing up:
```sql
insert into public.staff_allowlist (email, role)
values ('admin@fingerlicking.com', 'admin');
```

Then create/sign-up that user with **the same email** (any password you choose). The `public.profiles.role` will be set automatically.

If you did **not** use the allowlist, you can still bootstrap a staff user manually by updating the profile role in the SQL editor (server-side context):
```sql
insert into public.profiles (id, name, role)
values ('<auth.users.id>', 'Admin User', 'admin')
on conflict (id) do update set role = excluded.role;
```

### 5) Run the app
```bash
npm run dev
```
Open `http://localhost:3000`.

## Key Implementation Notes

- Auth uses Supabase Auth in the browser; all routes except `/` and `/login` are guarded by `admin-dashboard/middleware.ts`.
- All reads/writes use the Supabase anon key with RLS enforcement (no service key on client).
- Realtime subscriptions invalidate TanStack Query caches for “live” UI.

## Where to Extend Next

- Add a `conversation_summaries` view or RPC for efficient “unread counts” at scale (avoid large message scans).
- Add staff tools in Order Drawer: discounts, refunds, timeline audit logs.
- Add Rider assignment workflow (deliveries table + rider chat type).
- Add full “Customers” view and support ticket workflows.

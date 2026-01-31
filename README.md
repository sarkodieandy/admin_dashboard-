# Finger Licking Admin (Vanilla HTML/CSS/JS)

Static, multi-page admin dashboard for the existing Supabase backend (same DB as the Flutter app). No frameworks.

## Setup
1) Set Supabase env in `env.js` (anon key only).
2) Serve statically (any HTTP server):
   ```bash
   cd admin-dashboard
   python3 -m http.server 4173
   # open http://localhost:4173/pages/login.html
   ```
3) Deploy on GitHub Pages: set Pages source to `main` / root; entry URL `https://<user>.github.io/<repo>/admin-dashboard/pages/login.html` (root `index.html` already redirects there).

## Structure
```
admin-dashboard/
  env.js                    # Supabase URL + anon key
  css/
    tokens.css              # design tokens
    base.css                # reset + layout basics
    components.css          # buttons, cards, table, sidebar, toast, skeleton
    pages.css               # page-specific helpers
  js/
    supabaseClient.js       # init Supabase
    auth.js                 # requireAuth guard
    api.js                  # fetch/update Supabase data
    realtime.js             # subscriptions (orders/messages/notifications)
    ui.js                   # sidebar/topbar render, toast
    utils.js                # format helpers
    router.js               # nav active state
  pages/
    login.html
    dashboard.html
    orders.html
    chats.html
    menu.html
    customers.html
    riders.html
    delivery-settings.html
    staff-roles.html
    analytics.html
    settings.html
  index.html                # redirects to login
```

## Features (wired to Supabase)
- Auth (email/password via Supabase). Requires `profiles.role` ∈ {admin, staff, owner}.
- Dashboard: KPIs, recent orders, orders-by-hour chart.
- Orders: full operational console with tabs (Inbox/Kitchen/Dispatch/Reports), filters, CSV export, realtime new-order toast, status actions + timeline drawer, chat per order.
- Chats: conversations from `chats`/`chat_messages`, realtime updates, compose.
- Menu: categories + items list (live from Supabase).
- Delivery settings: load/save delivery_settings row.
- Staff allowlist: add/list staff emails.
- Analytics: revenue last 7 days (Chart.js).
- Notifications: staff_notifications list + badge (dashboard).
- Realtime: orders/messages/staff_notifications subscriptions.

## Notes
- No service role key is used; relies on RLS and anon key.
- Status strings match the existing app: placed, confirmed, preparing, ready, en_route, delivered, cancelled.
- Storage upload and advanced CRUD modals are not implemented in this minimal build; add via Supabase Storage + form handlers as needed.

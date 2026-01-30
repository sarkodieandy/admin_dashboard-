# Finger Licking Admin (static)

HTML + Tailwind + vanilla JS dashboard wired to Supabase.

## Configure Supabase

Edit `env.js` and set:
```js
window.SUPABASE_URL = "https://<project>.supabase.co";
window.SUPABASE_ANON_KEY = "<anon-key>";
```

## Run locally
```bash
cd admin-dashbaord
python3 -m http.server 4173
# open http://localhost:4173
```

## Pages implemented (SPA)
- Dashboard (KPIs + recent orders)
- Orders list (filter)
- Chats (order conversations)
- Menu (items list)
- Delivery settings (base fee, min order, etc.)
- Staff allowlist

Auth: Supabase email/password; requires `profiles.role` in (`admin`,`staff`,`owner`).

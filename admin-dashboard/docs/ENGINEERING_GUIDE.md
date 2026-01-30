# Engineering Guide

## Folder structure
- `src/app` — Next.js routes (App Router)
- `src/components` — UI + shell components
- `src/lib` — Supabase clients, queries, utilities
- `src/types` — Supabase `Database` types (manual scaffold)
- `db` — SQL schema + RLS + seed

## Env
Required:
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`

## Required “Sample Code” Pointers

1) Supabase client setup (browser + server)
- `src/lib/supabase/client.ts`
- `src/lib/supabase/server.ts`

2) Auth + route guard
- `middleware.ts` (protects `/app/*`, redirects to `/login`)

3) Fetch orders with pagination + filters
- `src/lib/queries/orders.ts` (`useOrders` – status + basic search)

4) Realtime subscription for orders
- `src/lib/queries/orders.ts` (`useRealtimeOrders`)

5) Fetch conversations with unread counts
- `src/lib/queries/chats.ts` (`useChats` – builds preview + lightweight unread indicator from last message)

6) Realtime subscription for messages in active conversation
- `src/lib/queries/chats.ts` (`useRealtimeChatMessages`)

7) Send message + upload attachment to Supabase Storage
- `src/lib/queries/chats.ts` (`useSendChatMessage`)
  - current customer app schema supports text messages only (`chat_messages.message`)

8) Mark conversation/messages read
- Not implemented in the existing customer app schema.
  - Recommended: add a read-tracking table (e.g. `chat_message_reads`) and update inbox unread counts.

9) Update order status with optimistic UI
- `src/lib/queries/orders.ts` (`useUpdateOrderStatus` – `onMutate` updates cache)

10) RLS-safe queries with branch scoping
- The existing customer app schema uses `public.is_staff()` to grant staff access.
- Admin additions are in `db/compat/001_admin_additions.sql`.

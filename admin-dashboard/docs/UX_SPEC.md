# UI/UX Spec — Finger Licking Admin

This spec documents the intended production UX behavior for the dashboard scaffold.

## Global Layout

**Sidebar**
- Sticky on desktop, collapsible (icon-only).
- Drawer on mobile/tablet.
- Active route highlighted.

**Top header**
- Global search (debounced; intended to search orders/chats/customers).
- Notifications bell (unread dot + dropdown list).
- User menu (role label + sign out).

**Feedback**
- Toasts for actions (saved, failed).
- Confirm dialogs for destructive actions (cancel/refund, delete item).
- Skeletons for loading.
- Empty states with short, action-oriented copy.

## Pages

### 1) Dashboard (Overview)

**KPI cards**
- Today orders
- Revenue
- Avg prep time (placeholder until tracked)
- Cancellations
- Active chats

**Widgets**
- Recent orders (last 10)
- Unread chats (top 5)

**Charts**
- Orders by hour (today)
- Revenue by day (last 7 days)

**States**
- Loading: skeletons in all widgets.
- Error: inline error blocks (future).
- Empty: “No orders yet today”.

### 2) Orders (Operations)

**Tabs**
- New / Preparing / Ready / Out for Delivery / Completed / Cancelled

**Filters**
- Search text input (order id/address/phone as available)
- Next: date range, payment status, pickup/delivery

**Table**
- Order, Type, Payment, Total, Created
- Row opens a right-side drawer.

**Drawer**
- Order summary + totals
- Items list + addons snapshot
- Quick actions:
  - Confirm → Preparing
  - Mark Ready
  - Out for Delivery
  - Delivered
- Next: cancel/refund flow (role-gated), add fee/discount, print receipt.

**Realtime behavior**
- New orders appear instantly in “New” tab.
- Status changes update list + drawer.

### 3) Chats (Order-based Inbox)

Layout: 3 columns (Inbox / Thread / Context)

**Inbox list**
- Sort: unread first, then most recent
- Each item shows:
  - Order id short code
  - Last message preview
  - Unread badge (lightweight indicator)

**Thread**
- Message bubbles (Customer vs Staff).
- Composer:
  - text
  - quick reply templates dropdown (future)
  - attachments are not enabled yet (current customer schema is text-only)

**Context panel**
- Order summary card
- “Open order” shortcut
- Call buttons (future)

**Realtime behavior**
- New message inserts update the thread and inbox instantly.

### 4) Menu

**Categories**
- List ordered by `sort_order`
- Up/down actions (MVP). Next: drag-and-drop.

**Items**
- Table includes image thumbnail, name, category name, price, availability status.
- Item editor:
  - name, description, price
  - category selector
  - availability toggle
  - featured toggle
  - image URL + upload to Storage

### 5) Delivery Settings

Form fields:
- base_fee
- free_radius_km
- per_km_fee_after_free_radius
- minimum_order_amount
- max_delivery_distance_km

Persisted in `delivery_settings` by `branch_id`.

## Accessibility
- Focus rings on interactive controls.
- Keyboard navigation across sidebar links, tabs, tables, drawers, and dialogs.
- Contrast-safe neutrals, semantic states for badges.

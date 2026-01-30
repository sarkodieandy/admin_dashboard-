import { getClient } from "./auth.js";

const supabase = getClient();

const ORDER_FIELDS =
  "id,status,total,subtotal,delivery_fee,discount,payment_method,payment_status,address_snapshot,created_at,user_id";

export async function fetchOrdersAdvanced({
  status,
  search,
  paymentStatus,
  dateFrom,
  dateTo,
  minTotal,
  limit = 50,
  offset = 0,
}) {
  let q = supabase.from("orders").select(ORDER_FIELDS, { count: "exact" }).order("created_at", { ascending: false });
  if (status) q = q.eq("status", status);
  if (paymentStatus) q = q.eq("payment_status", paymentStatus);
  if (dateFrom) q = q.gte("created_at", dateFrom);
  if (dateTo) q = q.lte("created_at", dateTo);
  if (minTotal) q = q.gte("total", minTotal);
  if (search) {
    q = q.or(`id.ilike.%${search}%,address_snapshot::text.ilike.%${search}%`);
  }
  return q.range(offset, offset + limit - 1);
}

export async function fetchRecentOrders(limit = 12) {
  return supabase.from("orders").select("id,status,total,created_at").order("created_at", { ascending: false }).limit(limit);
}

export async function fetchOrderDetails(orderId) {
  const order = await supabase.from("orders").select(ORDER_FIELDS).eq("id", orderId).maybeSingle();
  const items = await supabase
    .from("order_items")
    .select("id,name_snapshot,qty,price,addons_snapshot")
    .eq("order_id", orderId)
    .order("created_at", { ascending: true });
  const timeline = await supabase
    .from("order_status_events")
    .select("status,created_at")
    .eq("order_id", orderId)
    .order("created_at", { ascending: true });
  const chat = await supabase.from("chats").select("id").eq("order_id", orderId).maybeSingle();
  return { order, items, timeline, chat };
}

export async function updateOrderStatus(orderId, status) {
  return supabase.from("orders").update({ status }).eq("id", orderId);
}

export async function fetchMenu() {
  const cats = await supabase.from("categories").select("id,name,is_active,sort_order").order("sort_order", { ascending: true });
  const items = await supabase
    .from("menu_items")
    .select("id,name,base_price,description,is_active,is_sold_out,category_id,spice_level")
    .order("created_at", { ascending: false })
    .limit(200);
  return { cats, items };
}

export async function fetchChats(limit = 50) {
  return supabase.from("chats").select("id,order_id,created_at").order("created_at", { ascending: false }).limit(limit);
}

export async function fetchChatMessages(chatId) {
  return supabase
    .from("chat_messages")
    .select("id,message,sender_id,created_at")
    .eq("chat_id", chatId)
    .order("created_at", { ascending: true })
    .limit(200);
}

export async function sendChatMessage({ chatId, message, userId }) {
  return supabase.from("chat_messages").insert({
    chat_id: chatId,
    message,
    sender_id: userId,
  });
}

export async function loadDeliverySettings() {
  return supabase.from("delivery_settings").select("*").limit(1).maybeSingle();
}

export async function saveDeliverySettings(payload) {
  const existing = await supabase.from("delivery_settings").select("id").limit(1).maybeSingle();
  if (existing.data?.id) {
    return supabase.from("delivery_settings").update(payload).eq("id", existing.data.id);
  }
  return supabase.from("delivery_settings").insert(payload);
}

export async function fetchStaffAllowlist() {
  return supabase.from("staff_allowlist").select("*").order("created_at", { ascending: false });
}

export async function upsertStaffAllowlist(email, role) {
  return supabase.from("staff_allowlist").upsert({ email, role }, { onConflict: "email" });
}

export async function fetchNotifications() {
  return supabase
    .from("staff_notifications")
    .select("id,title,body,is_read,created_at,type,entity_id")
    .order("created_at", { ascending: false })
    .limit(30);
}

export async function fetchRiders() {
  return supabase.from("profiles").select("id,name,phone,role").eq("role", "rider");
}

export async function fetchOrdersForStatus(status) {
  return supabase.from("orders").select(ORDER_FIELDS).eq("status", status).order("created_at", { ascending: false }).limit(100);
}

export async function exportOrdersCsv({ dateFrom, dateTo }) {
  let q = supabase.from("orders").select(ORDER_FIELDS);
  if (dateFrom) q = q.gte("created_at", dateFrom);
  if (dateTo) q = q.lte("created_at", dateTo);
  return q;
}

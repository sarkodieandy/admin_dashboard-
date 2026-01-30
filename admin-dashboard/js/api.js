import { getClient } from "./auth.js";

const supabase = getClient();

export async function fetchOrders({ status, limit = 100, offset = 0 }) {
  let q = supabase
    .from("orders")
    .select("id,status,total,created_at,address_text,payment_status,type", { count: "exact" })
    .order("created_at", { ascending: false })
    .range(offset, offset + limit - 1);
  if (status) q = q.eq("status", status);
  return q;
}

export async function fetchRecentOrders(limit = 12) {
  return supabase
    .from("orders")
    .select("id,status,total,created_at")
    .order("created_at", { ascending: false })
    .limit(limit);
}

export async function fetchMenu() {
  const cats = await supabase.from("categories").select("id,name").order("sort_order", { ascending: true });
  const items = await supabase
    .from("menu_items")
    .select("id,name,price,description,is_available,category_id,featured,prep_time_min")
    .order("created_at", { ascending: false })
    .limit(200);
  return { cats, items };
}

export async function fetchConversations() {
  return supabase.from("conversations").select("id,order_id,type,created_at").order("created_at", { ascending: false }).limit(50);
}

export async function fetchMessages(conversationId) {
  return supabase
    .from("messages")
    .select("id,text,sender_role,created_at")
    .eq("conversation_id", conversationId)
    .order("created_at", { ascending: true })
    .limit(200);
}

export async function sendMessage({ conversationId, text, userId }) {
  return supabase.from("messages").insert({
    conversation_id: conversationId,
    text,
    sender_role: "staff",
    sender_id: userId,
    message_type: "text",
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
    .select("id,title,body,is_read,created_at")
    .order("created_at", { ascending: false })
    .limit(30);
}

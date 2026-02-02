import { getClient } from "./auth.js";

const supabase = getClient();

const ORDER_FIELDS =
  "id,status,total,subtotal,delivery_fee,discount,payment_method,payment_status,address_snapshot,created_at,user_id,branch_id";
const DELIVERY_WITH_RIDER =
  "id,order_id,rider_id,status,assigned_at,picked_at,delivered_at,updated_at,rider:riders(id,name,phone,vehicle_type,is_active)";

function isMissingColumnError(error, columnName) {
  const msg = String(error?.message || "");
  if (!msg) return false;
  if (columnName && !msg.includes(columnName)) return false;
  return error?.code === "PGRST204" || /could not find .* column/i.test(msg);
}

export async function fetchOrdersAdvanced({
  status,
  search,
  paymentStatus,
  dateFrom,
  dateTo,
  minTotal,
  branchId,
  limit = 50,
  offset = 0,
}) {
  let q = supabase.from("orders").select(ORDER_FIELDS, { count: "exact" }).order("created_at", { ascending: false });
  if (status) q = q.eq("status", status);
  if (paymentStatus) q = q.eq("payment_status", paymentStatus);
  if (dateFrom) q = q.gte("created_at", dateFrom);
  if (dateTo) q = q.lte("created_at", dateTo);
  if (minTotal) q = q.gte("total", minTotal);
  if (branchId) q = q.eq("branch_id", branchId);
  if (search) {
    q = q.or(`id.ilike.%${search}%,address_snapshot::text.ilike.%${search}%`);
  }
  return q.range(offset, offset + limit - 1);
}

export async function fetchRecentOrders({ limit = 12, branchId } = {}) {
  let q = supabase.from("orders").select("id,status,total,created_at,branch_id").order("created_at", { ascending: false }).limit(limit);
  if (branchId && branchId !== "all") q = q.eq("branch_id", branchId);
  return q;
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

export async function fetchMenu({ branchId } = {}) {
  let catsQ = supabase.from("categories").select("id,name,is_active,sort_order,branch_id").order("sort_order", { ascending: true });
  let itemsQ = supabase
    .from("menu_items")
    .select("id,name,base_price,description,is_active,is_sold_out,category_id,spice_level,image_url,branch_id")
    .order("created_at", { ascending: false })
    .limit(200);
  if (branchId && branchId !== "all") {
    catsQ = catsQ.eq("branch_id", branchId);
    itemsQ = itemsQ.eq("branch_id", branchId);
  }
  const cats = await catsQ;
  const items = await itemsQ;
  return { cats, items };
}

export async function updateMenuItem(id, payload) {
  return supabase.from("menu_items").update(payload).eq("id", id);
}

export async function insertMenuItem(payload) {
  return supabase.from("menu_items").insert(payload);
}

export async function insertCategory({ name, sort_order = 0, branch_id }) {
  return supabase.from("categories").insert({ name, sort_order, is_active: true, branch_id });
}

export async function updateCategory(id, payload) {
  return supabase.from("categories").update(payload).eq("id", id);
}

export async function fetchAddons({ branchId } = {}) {
  let q = supabase
    .from("item_addons")
    .select("id,item_id,name,price,created_at,branch_id")
    .order("created_at", { ascending: false })
    .limit(200);
  if (branchId && branchId !== "all") q = q.eq("branch_id", branchId);
  return q;
}

export async function insertAddon({ item_id, name, price, branch_id }) {
  return supabase.from("item_addons").insert({ item_id, name, price, branch_id });
}

export async function deleteAddon(id) {
  return supabase.from("item_addons").delete().eq("id", id);
}

export async function fetchCustomers(limit = 200) {
  return supabase.from("profiles").select("id,name,phone,created_at").order("created_at", { ascending: false }).limit(limit);
}

export async function fetchOrdersByUsers(userIds = [], { branchId } = {}) {
  if (!userIds.length) return { data: [], error: null };
  let q = supabase
    .from("orders")
    .select("id,user_id,total,status,payment_method,created_at,branch_id")
    .in("user_id", userIds)
    .order("created_at", { ascending: false })
    .limit(500);
  if (branchId && branchId !== "all") q = q.eq("branch_id", branchId);
  return q;
}

export async function fetchAddressesForUser(userId) {
  return supabase.from("addresses").select("label,address,landmark,created_at").eq("user_id", userId).order("created_at", { ascending: false });
}

export async function fetchOrdersRange({ dateFrom, dateTo, type, payment_method, branchId } = {}) {
  let q = supabase
    .from("orders")
    .select("id,user_id,total,delivery_fee,discount,status,payment_method,type,created_at,branch_id", { count: "exact" })
    .order("created_at", { ascending: true });
  if (dateFrom) q = q.gte("created_at", dateFrom);
  if (dateTo) q = q.lte("created_at", dateTo);
  if (type) q = q.eq("type", type);
  if (payment_method) q = q.eq("payment_method", payment_method);
  if (branchId && branchId !== "all") q = q.eq("branch_id", branchId);
  return q.limit(2000); // client-side aggregation
}

export async function fetchChats({ limit = 50, branchId } = {}) {
  let q = supabase.from("chats").select("id,order_id,created_at,branch_id").order("created_at", { ascending: false }).limit(limit);
  if (branchId && branchId !== "all") q = q.eq("branch_id", branchId);
  return q;
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
  const res = await supabase.from("chat_messages").insert({
    chat_id: chatId,
    message,
    sender_id: userId,
  });
  if (!res.error) return res;

  const msg = String(res.error.message || "").toLowerCase();
  const isRls = res.error.code === "42501" || msg.includes("row-level security");
  if (!isRls) return res;

  // Retry with branch_id for older deployments where a trigger isn't installed yet.
  const chat = await supabase.from("chats").select("branch_id").eq("id", chatId).maybeSingle();
  if (chat.error || !chat.data) return res;
  return supabase.from("chat_messages").insert({
    chat_id: chatId,
    message,
    sender_id: userId,
    branch_id: chat.data.branch_id,
  });
}

export async function loadDeliverySettings() {
  return supabase.from("delivery_settings").select("*").limit(1).maybeSingle();
}

export async function loadDeliverySettingsForBranch(branchId) {
  if (branchId && branchId !== "all") {
    const res = await supabase.from("delivery_settings").select("*").eq("branch_id", branchId).limit(1).maybeSingle();
    if (!res.error) return res;
    if (!isMissingColumnError(res.error, "branch_id")) return res;
  }
  return loadDeliverySettings();
}

export async function saveDeliverySettingsForBranch(payload, branchId) {
  if (branchId && branchId !== "all") {
    const existing = await supabase.from("delivery_settings").select("id").eq("branch_id", branchId).limit(1).maybeSingle();
    if (existing.error && !isMissingColumnError(existing.error, "branch_id")) return existing;
    if (existing.data?.id) {
      const res = await supabase.from("delivery_settings").update(payload).eq("id", existing.data.id);
      if (!res.error) return res;
      if (!isMissingColumnError(res.error, "branch_id")) return res;
    } else if (!existing.error) {
      const res = await supabase.from("delivery_settings").insert({ ...payload, branch_id: branchId });
      if (!res.error) return res;
      if (!isMissingColumnError(res.error, "branch_id")) return res;
    }
  }

  const existing = await supabase.from("delivery_settings").select("id").limit(1).maybeSingle();
  if (existing.data?.id) return supabase.from("delivery_settings").update(payload).eq("id", existing.data.id);
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

export async function markNotificationRead(id) {
  return supabase.from("staff_notifications").update({ is_read: true }).eq("id", id);
}

export async function markAllNotificationsRead() {
  return supabase.from("staff_notifications").update({ is_read: true }).eq("is_read", false);
}

export async function fetchRiders({ activeOnly = false, search = "", branchId } = {}) {
  let q = supabase
    .from("riders")
    // Use `*` to stay backward compatible if columns differ (e.g. default_delivery_note not yet migrated).
    .select("*")
    .order("created_at", { ascending: false });
  if (activeOnly) q = q.eq("is_active", true);
  if (branchId && branchId !== "all") q = q.eq("branch_id", branchId);
  if (search) {
    const term = `%${search}%`;
    q = q.or(`name.ilike.${term},phone.ilike.${term},vehicle_type.ilike.${term}`);
  }
  return q;
}

export async function updateRider(id, payload) {
  const res = await supabase.from("riders").update(payload).eq("id", id).select("*").maybeSingle();
  if (res.error && isMissingColumnError(res.error, "default_delivery_note") && "default_delivery_note" in payload) {
    const safePayload = { ...payload };
    delete safePayload.default_delivery_note;
    const retry = await supabase.from("riders").update(safePayload).eq("id", id).select("*").maybeSingle();
    return { ...retry, schemaFallback: retry.error ? false : true };
  }
  return { ...res, schemaFallback: false };
}

export async function insertRider(payload) {
  const res = await supabase.from("riders").insert(payload).select("*").maybeSingle();
  if (res.error && isMissingColumnError(res.error, "default_delivery_note") && "default_delivery_note" in payload) {
    const safePayload = { ...payload };
    delete safePayload.default_delivery_note;
    const retry = await supabase.from("riders").insert(safePayload).select("*").maybeSingle();
    return { ...retry, schemaFallback: retry.error ? false : true };
  }
  return { ...res, schemaFallback: false };
}

export async function fetchDeliveryForOrder(orderId) {
  return supabase.from("deliveries").select(DELIVERY_WITH_RIDER).eq("order_id", orderId).maybeSingle();
}

export async function fetchDeliveriesForOrders(orderIds = []) {
  if (!orderIds.length) return { data: [], error: null };
  return supabase.from("deliveries").select(DELIVERY_WITH_RIDER).in("order_id", orderIds);
}

export async function upsertDelivery(payload) {
  return supabase
    .from("deliveries")
    .upsert(payload, { onConflict: "order_id" })
    .select(DELIVERY_WITH_RIDER)
    .maybeSingle();
}

export async function updateDeliveryStatus(deliveryId, status) {
  const updates = {
    status,
    updated_at: new Date().toISOString(),
  };
  if (status === "picked_up") {
    updates.picked_at = new Date().toISOString();
  }
  if (status === "delivered") {
    updates.delivered_at = new Date().toISOString();
  }
  return supabase
    .from("deliveries")
    .update(updates)
    .eq("id", deliveryId)
    .select(DELIVERY_WITH_RIDER)
    .maybeSingle();
}

export async function fetchBranches({ activeOnly = false } = {}) {
  let q = supabase.from("branches").select("*").order("created_at", { ascending: false });
  if (activeOnly) q = q.eq("is_active", true);
  return q;
}

export async function upsertBranch(payload) {
  return supabase.from("branches").upsert(payload, { onConflict: "id" }).select("*").maybeSingle();
}

export async function fetchPromos({ limit = 200, branchId } = {}) {
  let q = supabase.from("promos").select("*").order("created_at", { ascending: false }).limit(limit);
  if (branchId && branchId !== "all") q = q.eq("branch_id", branchId);
  return q;
}

export async function insertPromo(payload) {
  return supabase.from("promos").insert(payload);
}

export async function updatePromo(id, payload) {
  return supabase.from("promos").update(payload).eq("id", id);
}

export async function fetchReviews({ limit = 200, branchId } = {}) {
  let q = supabase
    .from("reviews")
    .select("id,order_id,user_id,rating,comment,created_at,branch_id", { count: "exact" })
    .order("created_at", { ascending: false })
    .limit(limit);
  if (branchId && branchId !== "all") q = q.eq("branch_id", branchId);
  return q;
}

export async function fetchStaffInvites({ branchId, limit = 200 } = {}) {
  let q = supabase.from("staff_invites").select("*").order("created_at", { ascending: false }).limit(limit);
  if (branchId && branchId !== "all") q = q.eq("branch_id", branchId);
  return q;
}

export async function upsertStaffInvite({ email, role, branch_id, is_active = true }) {
  return supabase
    .from("staff_invites")
    .upsert({ email, role, branch_id, is_active }, { onConflict: "email" })
    .select("*")
    .maybeSingle();
}

export async function deactivateStaffInvite(email) {
  return supabase.from("staff_invites").update({ is_active: false }).eq("email", email);
}

export async function fetchStaffProfiles({ branchId, limit = 200, includeCustomers = false } = {}) {
  let q = supabase
    .from("profiles")
    .select("id,name,phone,role,branch_id,is_active,created_at")
    .order("created_at", { ascending: false })
    .limit(limit);
  if (!includeCustomers) q = q.not("role", "eq", "customer");
  if (branchId && branchId !== "all") q = q.eq("branch_id", branchId);
  return q;
}

export async function updateProfile(id, payload) {
  const res = await supabase.from("profiles").update(payload).eq("id", id).select("*").maybeSingle();
  if (res.error && isMissingColumnError(res.error, "is_active") && "is_active" in payload) {
    const safe = { ...payload };
    delete safe.is_active;
    const retry = await supabase.from("profiles").update(safe).eq("id", id).select("*").maybeSingle();
    return { ...retry, schemaFallback: retry.error ? false : true };
  }
  return { ...res, schemaFallback: false };
}

export async function fetchAuditLogs({ branchId, limit = 200, offset = 0 } = {}) {
  let q = supabase
    .from("audit_logs")
    .select("id,branch_id,actor_id,actor_role,action,entity,entity_id,before,after,created_at", { count: "exact" })
    .order("created_at", { ascending: false });
  if (branchId && branchId !== "all") q = q.eq("branch_id", branchId);
  return q.range(offset, offset + limit - 1);
}

export async function fetchOrdersForStatus(status, branchId) {
  let q = supabase.from("orders").select(ORDER_FIELDS).eq("status", status).order("created_at", { ascending: false }).limit(100);
  if (branchId && branchId !== "all") {
    q = q.eq("branch_id", branchId);
  }
  return q;
}

export async function exportOrdersCsv({ dateFrom, dateTo, branchId }) {
  let q = supabase.from("orders").select(ORDER_FIELDS);
  if (dateFrom) q = q.gte("created_at", dateFrom);
  if (dateTo) q = q.lte("created_at", dateTo);
  if (branchId && branchId !== "all") q = q.eq("branch_id", branchId);
  return q;
}

export async function loadRestaurantSettings() {
  // Optional table (safe fallback if migration not applied yet).
  const res = await supabase.from("restaurant_settings").select("*").limit(1).maybeSingle();
  if (res.error?.code === "42P01") return { data: null, error: null, missing: true };
  return res;
}

export async function loadRestaurantSettingsForBranch(branchId) {
  if (branchId && branchId !== "all") {
    const res = await supabase.from("restaurant_settings").select("*").eq("branch_id", branchId).limit(1).maybeSingle();
    if (res.error?.code === "42P01") return { data: null, error: null, missing: true };
    if (!res.error) return res;
    if (!isMissingColumnError(res.error, "branch_id")) return res;
  }
  return loadRestaurantSettings();
}

export async function saveRestaurantSettings(payload) {
  // Upsert singleton row (safe fallback if migration not applied yet).
  const existing = await supabase.from("restaurant_settings").select("id").limit(1).maybeSingle();
  if (existing.error?.code === "42P01") return { data: null, error: null, missing: true };
  if (existing.data?.id) return supabase.from("restaurant_settings").update(payload).eq("id", existing.data.id);
  return supabase.from("restaurant_settings").insert(payload);
}

export async function saveRestaurantSettingsForBranch(payload, branchId) {
  if (branchId && branchId !== "all") {
    const existing = await supabase.from("restaurant_settings").select("id").eq("branch_id", branchId).limit(1).maybeSingle();
    if (existing.error?.code === "42P01") return { data: null, error: null, missing: true };
    if (existing.error && !isMissingColumnError(existing.error, "branch_id")) return existing;
    if (existing.data?.id) {
      const res = await supabase.from("restaurant_settings").update(payload).eq("id", existing.data.id);
      if (!res.error) return res;
      if (!isMissingColumnError(res.error, "branch_id")) return res;
    } else if (!existing.error) {
      const res = await supabase.from("restaurant_settings").insert({ ...payload, branch_id: branchId });
      if (!res.error) return res;
      if (!isMissingColumnError(res.error, "branch_id")) return res;
    }
  }
  return saveRestaurantSettings(payload);
}

import { getClient, getCurrentScope, isPlatformRolePublic } from "./auth.js";

const supabase = getClient();

const ORDER_FIELDS =
  "id,status,total,subtotal,delivery_fee,discount,payment_method,payment_status,address_snapshot,created_at,user_id,branch_id";
const DELIVERY_WITH_RIDER =
  "id,order_id,rider_id,status,assigned_at,picked_at,delivered_at,updated_at,rider:riders(id,name,phone,vehicle_type,is_active)";
const LEGACY_RESTAURANT_SLUG = "legacy-default";

function excludeLegacyRestaurantRows(rows = []) {
  return (rows || []).filter(
    (row) => String(row?.slug || "").trim().toLowerCase() !== LEGACY_RESTAURANT_SLUG
  );
}

function scopeFilter(query, { useBranch = true } = {}) {
  const scope = getCurrentScope();
  if (!scope || isPlatformRolePublic(scope.role)) return query;
  let q = query;
  if (scope.restaurant_id) q = q.eq("restaurant_id", scope.restaurant_id);
  if (useBranch && scope.branch_id) q = q.eq("branch_id", scope.branch_id);
  return q;
}

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
  q = scopeFilter(q, { useBranch: !branchId });
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
  q = scopeFilter(q, { useBranch: !branchId });
  if (branchId && branchId !== "all") q = q.eq("branch_id", branchId);
  return q;
}

export async function fetchOrderDetails(orderId) {
  const order = await scopeFilter(supabase.from("orders").select(ORDER_FIELDS), { useBranch: true }).eq("id", orderId).maybeSingle();
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
  catsQ = scopeFilter(catsQ, { useBranch: !branchId });
  itemsQ = scopeFilter(itemsQ, { useBranch: !branchId });
  if (branchId && branchId !== "all") {
    catsQ = catsQ.eq("branch_id", branchId);
    itemsQ = itemsQ.eq("branch_id", branchId);
  }
  const cats = await catsQ;
  const items = await itemsQ;
  return { cats, items };
}

async function invokeMenuAdmin(entity, action, { id = null, payload = null } = {}) {
  const fnRes = await supabase.functions.invoke("admin-manage-menu", {
    body: {
      entity,
      action,
      id: id || null,
      payload: payload || {},
    },
  });
  if (!fnRes.error) {
    return {
      data: fnRes.data || null,
      error: null,
      viaEdge: true,
    };
  }

  let message = fnRes.error.message || "Menu admin action failed";
  try {
    const fnError = await fnRes.error.context?.json?.();
    if (fnError?.error) {
      message = fnError.error;
    }
  } catch (_) {
    // Keep top-level function message.
  }

  console.error("[E][menu] dashboard_menu_admin_edge_failed", {
    entity,
    action,
    id,
    payload,
    error: fnRes.error,
    message,
  });

  const msgLower = String(message || "").toLowerCase();
  const unavailable =
    msgLower.includes("failed to send a request to the edge function") ||
    msgLower.includes("failed to fetch") ||
    msgLower.includes("function not found") ||
    msgLower.includes("does not exist") ||
    msgLower.includes("functionsfetcherror");

  return {
    data: null,
    error: {
      ...fnRes.error,
      message: unavailable
        ? "Menu admin function is not deployed. Deploy the `admin-manage-menu` edge function."
        : message,
    },
    viaEdge: true,
    unavailable,
  };
}

export async function updateMenuItem(id, payload) {
  const edge = await invokeMenuAdmin("item", "upsert", { id, payload });
  return edge.error
    ? { data: null, error: edge.error }
    : { data: edge.data?.item ?? edge.data, error: null };
}

export async function insertMenuItem(payload) {
  const edge = await invokeMenuAdmin("item", "upsert", { payload });
  return edge.error
    ? { data: null, error: edge.error }
    : { data: edge.data?.item ?? edge.data, error: null };
}

export async function deleteMenuItem(id) {
  const edge = await invokeMenuAdmin("item", "delete", { id });
  return edge.error
    ? { data: null, error: edge.error }
    : { data: edge.data, error: null };
}

export async function insertCategory({ name, sort_order = 0, branch_id }) {
  const edge = await invokeMenuAdmin("category", "upsert", {
    payload: { name, sort_order, is_active: true, branch_id },
  });
  return edge.error
    ? { data: null, error: edge.error }
    : { data: edge.data?.category ?? edge.data, error: null };
}

export async function updateCategory(id, payload) {
  const edge = await invokeMenuAdmin("category", "upsert", { id, payload });
  return edge.error
    ? { data: null, error: edge.error }
    : { data: edge.data?.category ?? edge.data, error: null };
}

export async function fetchAddons({ branchId } = {}) {
  let q = supabase
    .from("item_addons")
    .select("id,item_id,name,price,created_at,branch_id")
    .order("created_at", { ascending: false })
    .limit(200);
  q = scopeFilter(q, { useBranch: !branchId });
  if (branchId && branchId !== "all") q = q.eq("branch_id", branchId);
  return q;
}

export async function insertAddon({ item_id, name, price, branch_id }) {
  const edge = await invokeMenuAdmin("addon", "upsert", {
    payload: { item_id, name, price, branch_id },
  });
  return edge.error
    ? { data: null, error: edge.error }
    : { data: edge.data?.addon ?? edge.data, error: null };
}

export async function deleteAddon(id) {
  const edge = await invokeMenuAdmin("addon", "delete", { id });
  return edge.error
    ? { data: null, error: edge.error }
    : { data: edge.data, error: null };
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
  q = scopeFilter(q, { useBranch: !branchId });
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
  q = scopeFilter(q, { useBranch: !branchId });
  if (dateFrom) q = q.gte("created_at", dateFrom);
  if (dateTo) q = q.lte("created_at", dateTo);
  if (type) q = q.eq("type", type);
  if (payment_method) q = q.eq("payment_method", payment_method);
  if (branchId && branchId !== "all") q = q.eq("branch_id", branchId);
  return q.limit(2000); // client-side aggregation
}

export async function fetchUsers({ role, search = "", limit = 200, offset = 0 } = {}) {
  const select =
    "id,name,phone,role,restaurant_id,branch_id,is_active,rider_status,created_at," +
    "restaurant:restaurants(name),branch:branches(name)";
  let q = supabase.from("profiles").select(select).order("created_at", { ascending: false });
  if (role && role !== "all") q = q.eq("role", role);
  if (search) {
    const term = `%${search}%`;
    q = q.or(`name.ilike.${term},phone.ilike.${term},role.ilike.${term}`);
  }
  return q.range(offset, offset + limit - 1);
}

export async function updateUserActive(userId, is_active) {
  return supabase.from("profiles").update({ is_active }).eq("id", userId);
}

export async function fetchChats({ limit = 50, branchId } = {}) {
  let q = supabase.from("chats").select("id,order_id,created_at,branch_id").order("created_at", { ascending: false }).limit(limit);
  q = scopeFilter(q, { useBranch: !branchId });
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
  const scope = getCurrentScope();
  const payload = {
    chat_id: chatId,
    message,
    sender_id: userId,
  };
  if (scope.branch_id && !isPlatformRolePublic(scope.role)) {
    payload.branch_id = scope.branch_id;
  }
  const res = await supabase.from("chat_messages").insert(payload);
  if (!res.error) return res;

  const msg = String(res.error.message || "").toLowerCase();
  const isRls = res.error.code === "42501" || msg.includes("row-level security");
  if (!isRls) return res;

  // Retry with branch_id for older deployments where a trigger isn't installed yet.
  const chat = await scopeFilter(supabase.from("chats").select("branch_id"), { useBranch: true }).eq("id", chatId).maybeSingle();
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
  q = scopeFilter(q, { useBranch: !branchId });
  if (activeOnly) q = q.eq("is_active", true);
  if (branchId && branchId !== "all") q = q.eq("branch_id", branchId);
  if (search) {
    const term = `%${search}%`;
    q = q.or(`name.ilike.${term},phone.ilike.${term},vehicle_type.ilike.${term}`);
  }
  return q;
}

export async function updateRider(id, payload) {
  const res = await scopeFilter(supabase.from("riders").update(payload), { useBranch: true }).eq("id", id).select("*").maybeSingle();
  if (res.error && isMissingColumnError(res.error, "default_delivery_note") && "default_delivery_note" in payload) {
    const safePayload = { ...payload };
    delete safePayload.default_delivery_note;
    const retry = await supabase.from("riders").update(safePayload).eq("id", id).select("*").maybeSingle();
    return { ...retry, schemaFallback: retry.error ? false : true };
  }
  return { ...res, schemaFallback: false };
}

export async function createRiderAccount(payload) {
  const body = {
    ...payload,
    role: "rider",
  };
  const res = await supabase.functions.invoke("admin-create-staff", {
    body,
  });
  if (!res.error) {
    return { data: res.data, error: null };
  }

  let message = res.error.message || "Failed to create rider account";
  try {
    const fnError = await res.error.context?.json?.();
    if (fnError?.error) {
      message = fnError.error;
    }
  } catch (_) {
    // Keep the function error message when the response body is unavailable.
  }

  console.error("[E][rider] create_rider_account_failed", {
    payload: {
      ...payload,
      password: payload?.password ? "***" : "",
    },
    error: res.error,
    message,
  });

  return {
    data: null,
    error: {
      ...res.error,
      message,
    },
  };
}

export async function insertRider(payload) {
  const scope = getCurrentScope();
  const scopedPayload = { ...payload };
  if (!isPlatformRolePublic(scope.role) && scope.branch_id && !scopedPayload.branch_id) {
    scopedPayload.branch_id = scope.branch_id;
  }
  const res = await supabase.from("riders").insert(scopedPayload).select("*").maybeSingle();
  if (res.error && isMissingColumnError(res.error, "default_delivery_note") && "default_delivery_note" in payload) {
    const safePayload = { ...payload };
    delete safePayload.default_delivery_note;
    const retry = await supabase.from("riders").insert(safePayload).select("*").maybeSingle();
    return { ...retry, schemaFallback: retry.error ? false : true };
  }
  return { ...res, schemaFallback: false };
}

export async function fetchDeliveryForOrder(orderId) {
  return scopeFilter(supabase.from("deliveries").select(DELIVERY_WITH_RIDER), { useBranch: true })
    .eq("order_id", orderId)
    .maybeSingle();
}

export async function fetchDeliveriesForOrders(orderIds = []) {
  if (!orderIds.length) return { data: [], error: null };
  return scopeFilter(supabase.from("deliveries").select(DELIVERY_WITH_RIDER), { useBranch: true }).in("order_id", orderIds);
}

export async function fetchDeliveries({
  status,
  branchId,
  restaurantId,
  limit = 100,
  offset = 0,
} = {}) {
  const select =
    "id,order_id,status,assigned_at,picked_at,delivered_at,updated_at," +
    "rider:riders(id,name,phone,vehicle_type)," +
    "order:orders(id,total,restaurant_id,branch_id,address_snapshot,created_at)," +
    "restaurant:restaurants(id,name)," +
    "branch:branches(id,name)";
  let q = supabase.from("deliveries").select(select).order("updated_at", { ascending: false });
  q = scopeFilter(q, { useBranch: !branchId });
  if (status) q = q.eq("status", status);
  if (branchId && branchId !== "all") q = q.eq("branch_id", branchId);
  if (restaurantId) q = q.eq("restaurant_id", restaurantId);
  return q.range(offset, offset + limit - 1);
}

export async function upsertDelivery(payload) {
  const scope = getCurrentScope();
  const scoped = { ...payload };
  if (!isPlatformRolePublic(scope.role) && scope.branch_id && !scoped.branch_id) scoped.branch_id = scope.branch_id;

  const fnRes = await supabase.functions.invoke("admin-upsert-delivery", {
    body: {
      order_id: scoped.order_id,
      rider_id: scoped.rider_id,
      status: scoped.status || null,
      assigned_at: scoped.assigned_at || null,
      picked_at: scoped.picked_at || null,
      delivered_at: scoped.delivered_at || null,
    },
  });
  if (!fnRes.error) {
    return {
      data: fnRes.data?.delivery ?? fnRes.data ?? null,
      error: null,
      viaEdge: true,
    };
  }

  let fnMessage = fnRes.error.message || "Failed to assign rider";
  try {
    const fnError = await fnRes.error.context?.json?.();
    if (fnError?.error) {
      fnMessage = fnError.error;
    }
  } catch (_) {
    // Keep top-level function message.
  }

  console.error("[E][delivery] dashboard_upsert_delivery_edge_failed", {
    payload: scoped,
    error: fnRes.error,
    message: fnMessage,
  });

  const fnMsgLower = String(fnMessage || "").toLowerCase();
  const fnUnavailable =
    fnMsgLower.includes("failed to send a request to the edge function") ||
    fnMsgLower.includes("failed to fetch") ||
    fnMsgLower.includes("function not found") ||
    fnMsgLower.includes("does not exist");

  if (!fnUnavailable) {
    return {
      data: null,
      error: {
        ...fnRes.error,
        message: fnMessage,
      },
      viaEdge: true,
    };
  }

  const rpc = await supabase.rpc("upsert_delivery_admin", {
    order_id: scoped.order_id,
    rider_id: scoped.rider_id,
    status: scoped.status || null,
    assigned_at: scoped.assigned_at || null,
    picked_at: scoped.picked_at || null,
    delivered_at: scoped.delivered_at || null,
  });
  if (!rpc.error) {
    return { data: rpc.data, error: null, viaRpc: true };
  }
  const rpcMsg = String(rpc.error?.message || "").toLowerCase();
  const rpcMissing = rpc.error?.code === "PGRST202" || rpcMsg.includes("upsert_delivery_admin");
  const rpcVolatile = rpcMsg.includes("non volatile") || rpcMsg.includes("non-volatile");
  if (!rpcMissing && !rpcVolatile) return rpc;

  return supabase
    .from("deliveries")
    .upsert(scoped, { onConflict: "order_id" })
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
  return scopeFilter(supabase.from("deliveries"), { useBranch: true })
    .update(updates)
    .eq("id", deliveryId)
    .select(DELIVERY_WITH_RIDER)
    .maybeSingle();
}

export async function fetchBranches({ activeOnly = false, restaurantId, includeRestaurant = false } = {}) {
  const fnRes = await supabase.functions.invoke("admin-list-branches", {
    body: {
      activeOnly,
      restaurant_id: restaurantId || null,
      include_restaurant: includeRestaurant,
    },
  });
  if (!fnRes.error) {
    return {
      data: fnRes.data?.branches ?? fnRes.data ?? [],
      error: null,
      schemaFallback: false,
      viaEdge: true,
    };
  }

  let fnMessage = fnRes.error.message || "Failed to load branches";
  try {
    const fnError = await fnRes.error.context?.json?.();
    if (fnError?.error) {
      fnMessage = fnError.error;
    }
  } catch (_) {
    // Use the top-level function error when no JSON body is available.
  }

  console.error("[E][branch] dashboard_fetch_branches_edge_failed", {
    restaurantId,
    includeRestaurant,
    activeOnly,
    error: fnRes.error,
    message: fnMessage,
  });

  const fnMsgLower = String(fnMessage || "").toLowerCase();
  const fnUnavailable =
    fnMsgLower.includes("failed to send a request to the edge function") ||
    fnMsgLower.includes("failed to fetch") ||
    fnMsgLower.includes("function not found") ||
    fnMsgLower.includes("does not exist");

  if (!fnUnavailable) {
    return {
      data: null,
      error: {
        ...fnRes.error,
        message: fnMessage,
      },
      schemaFallback: false,
      viaEdge: true,
    };
  }

  const select = includeRestaurant ? "*, restaurant:restaurants(id,name)" : "*";
  let q = supabase.from("branches").select(select).order("created_at", { ascending: false });
  if (!restaurantId) q = scopeFilter(q, { useBranch: false });
  if (activeOnly) q = q.eq("is_active", true);
  if (restaurantId) q = q.eq("restaurant_id", restaurantId);

  const res = await q;

  if (res.error && includeRestaurant) {
    // Fallback when the marketplace tables/relations are not deployed yet.
    const missingRestaurants = res.error.code === "42P01" || String(res.error.message || "").toLowerCase().includes("restaurants");
    const missingRestaurantId = isMissingColumnError(res.error, "restaurant_id");
    if (missingRestaurants || missingRestaurantId) {
      let retry = supabase.from("branches").select("*").order("created_at", { ascending: false });
      if (activeOnly) retry = retry.eq("is_active", true);
      if (restaurantId) retry = retry.eq("restaurant_id", restaurantId);
      const fallback = await retry;
      if (fallback.error && restaurantId && isMissingColumnError(fallback.error, "restaurant_id")) {
        // restaurant_id missing: return unfiltered branches as a last resort.
        let retry2 = supabase.from("branches").select("*").order("created_at", { ascending: false });
        if (activeOnly) retry2 = retry2.eq("is_active", true);
        const fallback2 = await retry2;
        return { ...fallback2, schemaFallback: fallback2.error ? false : true };
      }
      return { ...fallback, schemaFallback: fallback.error ? false : true };
    }
  }
  if (res.error && restaurantId && isMissingColumnError(res.error, "restaurant_id")) {
    // Backward compatibility for older deployments (no restaurant_id).
    let retry = supabase.from("branches").select("*").order("created_at", { ascending: false });
    if (activeOnly) retry = retry.eq("is_active", true);
    const fallback = await retry;
    return { ...fallback, schemaFallback: fallback.error ? false : true };
  }

  if (res.error) {
    console.error("[E][branch] dashboard_fetch_branches_failed", {
      restaurantId,
      includeRestaurant,
      activeOnly,
      error: res.error,
    });
  }

  return { ...res, schemaFallback: false };
}

export async function upsertBranch(payload) {
  const fnRes = await supabase.functions.invoke("admin-upsert-branch", {
    body: {
      branch_id: payload.id || null,
      name: payload.name,
      address: payload.address || null,
      lat: payload.lat ?? null,
      lng: payload.lng ?? null,
      is_active: payload.is_active ?? true,
      is_open: payload.is_open ?? true,
      restaurant_id: payload.restaurant_id || null,
    },
  });
  if (!fnRes.error) {
    return {
      data: fnRes.data?.branch ?? fnRes.data,
      error: null,
      schemaFallback: false,
      viaEdge: true,
    };
  }

  let fnMessage = fnRes.error.message || "Failed to save branch";
  try {
    const fnError = await fnRes.error.context?.json?.();
    if (fnError?.error) {
      fnMessage = fnError.error;
    }
  } catch (_) {
    // Use the top-level function error when no JSON body is available.
  }

  console.error("[E][branch] dashboard_upsert_branch_edge_failed", {
    payload,
    error: fnRes.error,
    message: fnMessage,
  });

  const fnMsgLower = String(fnMessage || "").toLowerCase();
  const fnUnavailable =
    fnMsgLower.includes("failed to send a request to the edge function") ||
    fnMsgLower.includes("edge function returned a non-2xx status code") ||
    fnMsgLower.includes("functionsfetcherror") ||
    fnMsgLower.includes("failed to fetch");

  const rpc = await supabase.rpc("upsert_branch_admin", {
    branch_id: payload.id || null,
    branch_name: payload.name,
    branch_address: payload.address || null,
    branch_lat: payload.lat ?? null,
    branch_lng: payload.lng ?? null,
    branch_is_active: payload.is_active ?? true,
    branch_is_open: payload.is_open ?? true,
    restaurant_id: payload.restaurant_id || null,
  });
  if (!rpc.error) {
    return { data: rpc.data, error: null, schemaFallback: false, viaRpc: true };
  }

  if (!fnUnavailable) {
    return {
      data: null,
      error: {
        ...fnRes.error,
        message: fnMessage,
      },
      schemaFallback: false,
      viaEdge: true,
    };
  }

  console.error("[E][branch] dashboard_upsert_branch_failed", {
    payload,
    error: rpc.error,
  });

  const rpcMsg = String(rpc.error?.message || "").toLowerCase();
  const rpcMissing = rpc.error?.code === "PGRST202" || rpcMsg.includes("upsert_branch_admin");
  const rpcVolatile = rpcMsg.includes("non volatile") || rpcMsg.includes("non-volatile");
  if (rpcMissing || rpcVolatile) {
    const message = rpcVolatile
      ? "Branch admin RPC is outdated. Run migrations 0072_fix_rpc_volatility.sql and 0079_harden_branch_admin_rpc_nonrecursive.sql in Supabase."
      : "Branch admin RPC is missing. Run migrations 0072_fix_rpc_volatility.sql and 0079_harden_branch_admin_rpc_nonrecursive.sql in Supabase.";
    return {
      data: null,
      error: {
        ...rpc.error,
        code: rpc.error?.code || (rpcVolatile ? "BRANCH_ADMIN_RPC_VOLATILE" : "BRANCH_ADMIN_RPC_MISSING"),
        message,
      },
      schemaFallback: false,
      viaRpc: true,
    };
  }

  return { ...rpc, schemaFallback: false, viaRpc: true };
}

export async function fetchPromos({ limit = 200, branchId } = {}) {
  let q = supabase.from("promos").select("*").order("created_at", { ascending: false }).limit(limit);
  q = scopeFilter(q, { useBranch: !branchId });
  if (branchId && branchId !== "all") q = q.eq("branch_id", branchId);
  return q;
}

export async function insertPromo(payload) {
  const scope = getCurrentScope();
  const scoped = { ...payload };
  if (!isPlatformRolePublic(scope.role) && scope.branch_id && !scoped.branch_id) scoped.branch_id = scope.branch_id;
  if (!isPlatformRolePublic(scope.role) && scope.restaurant_id && !scoped.restaurant_id) scoped.restaurant_id = scope.restaurant_id;
  return supabase.from("promos").insert(scoped);
}

export async function updatePromo(id, payload) {
  const scope = getCurrentScope();
  const scoped = { ...payload };
  if (!isPlatformRolePublic(scope.role) && scope.branch_id) scoped.branch_id = scope.branch_id;
  if (!isPlatformRolePublic(scope.role) && scope.restaurant_id) scoped.restaurant_id = scope.restaurant_id;
  return scopeFilter(supabase.from("promos").update(scoped), { useBranch: true }).eq("id", id);
}

export async function fetchReviews({ limit = 200, branchId } = {}) {
  let q = supabase
    .from("reviews")
    .select("id,order_id,user_id,rating,comment,created_at,branch_id", { count: "exact" })
    .order("created_at", { ascending: false })
    .limit(limit);
  q = scopeFilter(q, { useBranch: !branchId });
  if (branchId && branchId !== "all") q = q.eq("branch_id", branchId);
  return q;
}

export async function fetchStaffInvites({ branchId, limit = 200 } = {}) {
  let q = supabase.from("staff_invites").select("*").order("created_at", { ascending: false }).limit(limit);
  q = scopeFilter(q, { useBranch: !branchId });
  if (branchId && branchId !== "all") q = q.eq("branch_id", branchId);
  return q;
}

export async function upsertStaffInvite({ email, role, branch_id, is_active = true }) {
  const scope = getCurrentScope();
  const scoped = { email, role, branch_id, is_active };
  if (!isPlatformRolePublic(scope.role) && scope.branch_id && !scoped.branch_id) scoped.branch_id = scope.branch_id;
  if (!isPlatformRolePublic(scope.role) && scope.restaurant_id && !scoped.restaurant_id) scoped.restaurant_id = scope.restaurant_id;
  return supabase.from("staff_invites").upsert(scoped, { onConflict: "email" }).select("*").maybeSingle();
}

export async function deactivateStaffInvite(email) {
  return scopeFilter(supabase.from("staff_invites").update({ is_active: false }), { useBranch: true }).eq("email", email);
}

export async function fetchStaffProfiles({ branchId, limit = 200, includeCustomers = false } = {}) {
  let q = supabase
    .from("profiles")
    .select("id,name,phone,role,branch_id,is_active,created_at")
    .order("created_at", { ascending: false })
    .limit(limit);
  q = scopeFilter(q, { useBranch: !branchId });
  if (!includeCustomers) q = q.not("role", "eq", "customer");
  if (branchId && branchId !== "all") q = q.eq("branch_id", branchId);
  return q;
}

export async function fetchStaffBranchAccess({ userIds = [] } = {}) {
  if (!userIds.length) return { data: [], error: null };
  return scopeFilter(supabase.from("staff_branch_access").select("user_id,branch_id,created_at"), { useBranch: false }).in(
    "user_id",
    userIds
  );
}

export async function setStaffBranchAccess({ userId, branchIds = [] }) {
  if (!userId) return { data: null, error: { message: "Missing userId" } };
  const desired = new Set((branchIds || []).filter(Boolean));

  const existing = await scopeFilter(supabase.from("staff_branch_access").select("branch_id"), { useBranch: false }).eq("user_id", userId);
  if (existing.error) return existing;

  const current = new Set((existing.data || []).map((r) => r.branch_id));
  const toInsert = [...desired].filter((b) => !current.has(b));
  const toDelete = [...current].filter((b) => !desired.has(b));

  if (toInsert.length) {
    const ins = await scopeFilter(supabase.from("staff_branch_access"), { useBranch: false }).insert(
      toInsert.map((branch_id) => ({ user_id: userId, branch_id }))
    );
    if (ins.error) return ins;
  }
  if (toDelete.length) {
    const del = await scopeFilter(supabase.from("staff_branch_access").delete(), { useBranch: false })
      .eq("user_id", userId)
      .in("branch_id", toDelete);
    if (del.error) return del;
  }
  return { data: { ok: true }, error: null };
}

export async function updateProfile(id, payload) {
  const res = await scopeFilter(supabase.from("profiles").update(payload), { useBranch: true }).eq("id", id).select("*").maybeSingle();
  if (res.error && isMissingColumnError(res.error, "is_active") && "is_active" in payload) {
    const safe = { ...payload };
    delete safe.is_active;
    const retry = await scopeFilter(supabase.from("profiles").update(safe), { useBranch: true }).eq("id", id).select("*").maybeSingle();
    return { ...retry, schemaFallback: retry.error ? false : true };
  }
  return { ...res, schemaFallback: false };
}

export async function fetchAuditLogs({ branchId, limit = 200, offset = 0 } = {}) {
  let q = supabase
    .from("audit_logs")
    .select("id,branch_id,actor_id,actor_role,action,entity,entity_id,before,after,created_at", { count: "exact" })
    .order("created_at", { ascending: false });
  q = scopeFilter(q, { useBranch: !branchId });
  if (branchId && branchId !== "all") q = q.eq("branch_id", branchId);
  return q.range(offset, offset + limit - 1);
}

export async function fetchOrdersForStatus(status, branchId) {
  let q = supabase.from("orders").select(ORDER_FIELDS).eq("status", status).order("created_at", { ascending: false }).limit(100);
  q = scopeFilter(q, { useBranch: !branchId });
  if (branchId && branchId !== "all") {
    q = q.eq("branch_id", branchId);
  }
  return q;
}

export async function exportOrdersCsv({ dateFrom, dateTo, branchId }) {
  let q = supabase.from("orders").select(ORDER_FIELDS);
  q = scopeFilter(q, { useBranch: !branchId });
  if (dateFrom) q = q.gte("created_at", dateFrom);
  if (dateTo) q = q.lte("created_at", dateTo);
  if (branchId && branchId !== "all") q = q.eq("branch_id", branchId);
  return q;
}

export async function loadRestaurantSettings() {
  // Optional table (safe fallback if migration not applied yet).
  const res = await scopeFilter(supabase.from("restaurant_settings").select("*"), { useBranch: false }).limit(1).maybeSingle();
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
  const existing = await scopeFilter(supabase.from("restaurant_settings").select("id"), { useBranch: false }).limit(1).maybeSingle();
  if (existing.error?.code === "42P01") return { data: null, error: null, missing: true };
  if (existing.data?.id) return scopeFilter(supabase.from("restaurant_settings").update(payload), { useBranch: false }).eq("id", existing.data.id);
  return scopeFilter(supabase.from("restaurant_settings").insert(payload), { useBranch: false });
}

export async function saveRestaurantSettingsForBranch(payload, branchId) {
  if (branchId && branchId !== "all") {
    const existing = await scopeFilter(
      supabase.from("restaurant_settings").select("id"),
      { useBranch: false }
    )
      .eq("branch_id", branchId)
      .limit(1)
      .maybeSingle();
    if (existing.error?.code === "42P01") return { data: null, error: null, missing: true };
    if (existing.error && !isMissingColumnError(existing.error, "branch_id")) return existing;
    if (existing.data?.id) {
      const res = await scopeFilter(
        supabase.from("restaurant_settings").update(payload),
        { useBranch: false }
      ).eq("id", existing.data.id);
      if (!res.error) return res;
      if (!isMissingColumnError(res.error, "branch_id")) return res;
    } else if (!existing.error) {
      const res = await scopeFilter(
        supabase.from("restaurant_settings").insert({ ...payload, branch_id: branchId }),
        { useBranch: false }
      );
      if (!res.error) return res;
      if (!isMissingColumnError(res.error, "branch_id")) return res;
    }
  }
  return saveRestaurantSettings(payload);
}

// =========
// Marketplace (platform admin)
// =========

export async function fetchRestaurants({ status, search, limit = 200, offset = 0 } = {}) {
  const scope = getCurrentScope();
  let res;
  if (isPlatformRolePublic(scope.role)) {
    const rpc = await supabase.rpc("get_restaurants_admin", {
      status_filter: status ?? null,
      search_term: search ?? null,
      limit_count: limit,
      offset_count: offset,
    });
    if (!rpc.error) {
      res = { data: rpc.data || [], error: null, count: null };
    } else {
      const msg = String(rpc.error?.message || "");
      const missing = rpc.error?.code === "PGRST202" || msg.toLowerCase().includes("get_restaurants_admin");
      if (!missing) return rpc;
    }
  }

  if (!res) {
    let q = supabase
      .from("restaurants")
      .select("id,name,slug,logo_url,phone,email,is_active,status,created_at,owner_id", { count: "exact" })
      .order("created_at", { ascending: false });
    if (status && status !== "all") q = q.eq("status", status);
    if (search) {
      const term = `%${search}%`;
      q = q.or(`name.ilike.${term},slug.ilike.${term},email.ilike.${term},phone.ilike.${term}`);
    }
    res = await q.range(offset, offset + limit - 1);
    if (res.error && isMissingColumnError(res.error, "owner_id")) {
      let qFallback = supabase
        .from("restaurants")
        .select("id,name,slug,logo_url,phone,email,is_active,status,created_at", { count: "exact" })
        .order("created_at", { ascending: false });
      if (status && status !== "all") qFallback = qFallback.eq("status", status);
      if (search) {
        const term = `%${search}%`;
        qFallback = qFallback.or(`name.ilike.${term},slug.ilike.${term},email.ilike.${term},phone.ilike.${term}`);
      }
      res = await qFallback.range(offset, offset + limit - 1);
    }
    if (res.error) return res;
  }

  const filteredRestaurants = excludeLegacyRestaurantRows(res.data || []);
  const hiddenCount = Math.max(0, (res.data || []).length - filteredRestaurants.length);
  const filteredCount =
    typeof res.count === "number" ? Math.max(0, res.count - hiddenCount) : res.count;
  const ids = filteredRestaurants.map((r) => r.id).filter(Boolean);
  if (!ids.length) {
    return {
      ...res,
      count: filteredCount,
      data: filteredRestaurants.map((r) => ({ ...r, billing: null })),
    };
  }

  const billing = await supabase
    .from("restaurant_billing")
    .select("restaurant_id,commission_rate,payout_schedule,is_active")
    .in("restaurant_id", ids);

  const billingById = new Map((billing.data || []).map((b) => [b.restaurant_id, b]));
  return {
    ...res,
    count: filteredCount,
    data: filteredRestaurants.map((r) => ({ ...r, owner_id: r.owner_id || null, billing: billingById.get(r.id) || null })),
    billingError: billing.error || null,
  };
}

export async function fetchProfilesByIds(userIds = []) {
  if (!userIds.length) return { data: [], error: null };
  return supabase
    .from("profiles")
    .select("id,name,phone,role,created_at")
    .in("id", userIds);
}

export async function searchOwnerCandidates(search = "", limit = 25) {
  let q = supabase
    .from("profiles")
    .select("id,name,phone,role,created_at")
    .in("role", ["customer", "restaurant_owner"])
    .order("created_at", { ascending: false })
    .limit(limit);
  if (search) {
    const term = `%${search}%`;
    q = q.or(`name.ilike.${term},phone.ilike.${term},id.eq.${search}`);
  }
  return q;
}

export async function linkOwnerToRestaurant({ restaurantId, userId }) {
  const profileRes = await supabase
    .from("profiles")
    .update({ role: "restaurant_owner", restaurant_id: restaurantId, is_active: true })
    .eq("id", userId);
  if (profileRes.error) return profileRes;
  return updateRestaurant(restaurantId, { owner_id: userId });
}

export async function updateRestaurant(restaurantId, payload) {
  return supabase.from("restaurants").update(payload).eq("id", restaurantId).select("id").maybeSingle();
}

export async function upsertRestaurantBilling(restaurantId, payload) {
  return supabase
    .from("restaurant_billing")
    .upsert({ restaurant_id: restaurantId, ...payload }, { onConflict: "restaurant_id" })
    .select("restaurant_id,commission_rate,payout_schedule,is_active")
    .maybeSingle();
}

export async function createRestaurantAccount(payload) {
  const res = await supabase.functions.invoke("admin-create-restaurant-account", {
    body: payload,
  });
  if (!res.error) {
    return { data: res.data, error: null };
  }

  let message = res.error.message || "Failed to create restaurant account";
  try {
    const fnError = await res.error.context?.json?.();
    if (fnError?.error) {
      message = fnError.error;
    }
  } catch (_) {
    // Keep the function error message.
  }

  console.error("[E][restaurant] create_restaurant_account_failed", {
    payload: {
      ...payload,
      password: payload?.password ? "***" : "",
    },
    error: res.error,
    message,
  });

  return {
    data: null,
    error: {
      ...res.error,
      message,
    },
  };
}

export async function deleteRestaurantAdmin(restaurantId) {
  const res = await supabase.rpc("delete_restaurant_admin", {
    target_restaurant: restaurantId,
  });

  if (!res.error) {
    return { data: res.data, error: null };
  }

  let message = res.error.message || "Failed to delete restaurant";
  const lower = String(message || "").toLowerCase();
  const missing =
    res.error.code === "PGRST202" ||
    lower.includes("delete_restaurant_admin");

  if (missing) {
    message =
      "Restaurant delete RPC is not deployed. Run migration 0083_delete_restaurant_admin.sql.";
  }

  console.error("[E][restaurant] delete_restaurant_admin_failed", {
    restaurantId,
    error: res.error,
    message,
  });

  return {
    data: null,
    error: {
      ...res.error,
      message,
    },
  };
}

export async function fetchOrderFinancials({ dateFrom, dateTo, restaurantId, limit = 5000 } = {}) {
  let q = supabase
    .from("order_financials")
    .select("order_id,restaurant_id,gross_total,platform_fee,restaurant_payout,created_at")
    .order("created_at", { ascending: false })
    .limit(limit);
  q = scopeFilter(q, { useBranch: false });
  if (dateFrom) q = q.gte("created_at", dateFrom);
  if (dateTo) q = q.lte("created_at", dateTo);
  if (restaurantId) q = q.eq("restaurant_id", restaurantId);
  return q;
}

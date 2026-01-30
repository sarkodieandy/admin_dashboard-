// Minimal SPA admin dashboard using vanilla JS + Tailwind classes.

const navItems = [
  { id: "dashboard", label: "Dashboard", icon: "📊" },
  { id: "orders", label: "Orders", icon: "🧾" },
  { id: "chats", label: "Chats", icon: "💬" },
  { id: "menu", label: "Menu", icon: "🍔" },
  { id: "customers", label: "Customers", icon: "👥" },
  { id: "riders", label: "Riders", icon: "🛵" },
  { id: "delivery", label: "Delivery Settings", icon: "🚚" },
  { id: "promos", label: "Promotions", icon: "🏷️" },
  { id: "reviews", label: "Reviews & Support", icon: "⭐" },
  { id: "staff", label: "Staff & Roles", icon: "🧑‍🍳" },
  { id: "analytics", label: "Analytics", icon: "📈" },
  { id: "settings", label: "Settings", icon: "⚙️" },
];

const state = {
  supabase: null,
  profile: null,
  active: "dashboard",
  orders: [],
  conversations: [],
  notifications: [],
};

const toastEl = document.getElementById("toast");
const debugEl = document.getElementById("debugPanel");

function dbg(msg, data) {
  console.log("[admin]", msg, data || "");
  if (!debugEl) return;
  debugEl.classList.remove("hidden");
  const line = document.createElement("div");
  line.textContent = `[admin] ${msg} ${data ? JSON.stringify(data) : ""}`;
  debugEl.appendChild(line);
  if (debugEl.childNodes.length > 120) debugEl.removeChild(debugEl.firstChild);
  debugEl.scrollTop = debugEl.scrollHeight;
}

function showToast(text) {
  if (!toastEl) return;
  toastEl.textContent = text;
  toastEl.classList.remove("hidden", "opacity-0");
  toastEl.classList.add("opacity-100");
  setTimeout(() => {
    toastEl.classList.add("opacity-0");
  }, 2400);
}

function initSupabase() {
  const url = window.SUPABASE_URL;
  const key = window.SUPABASE_ANON_KEY;
  if (!url || !key) throw new Error("Missing Supabase env");
  state.supabase = window.supabase.createClient(url, key);
  dbg("supabase:init");
}

function renderNav() {
  const nav = document.getElementById("nav");
  if (!nav) return;
  nav.innerHTML = "";
  navItems.forEach((item) => {
    const a = document.createElement("button");
    a.className =
      "w-full flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-brand-50 hover:text-brand-700 text-left transition";
    a.dataset.id = item.id;
    a.innerHTML = `<span>${item.icon}</span><span>${item.label}</span>`;
    a.addEventListener("click", () => setRoute(item.id));
    nav.appendChild(a);
  });
}

function setRoute(id) {
  state.active = id;
  window.location.hash = id;
  renderContent();
  const title = document.getElementById("pageTitle");
  const sub = document.getElementById("pageSub");
  title && (title.textContent = navItems.find((n) => n.id === id)?.label || "Dashboard");
  sub && (sub.textContent = id === "dashboard" ? "Overview" : "");
  document.querySelectorAll("#nav button").forEach((btn) => {
    btn.classList.toggle("bg-brand-50", btn.dataset.id === id);
    btn.classList.toggle("text-brand-700", btn.dataset.id === id);
  });
}

async function requireStaff() {
  const { data, error } = await state.supabase.auth.getUser();
  if (error || !data.user) {
    dbg("auth:no-user");
    showLogin(true);
    return null;
  }
  const { data: profile, error: perr } = await state.supabase
    .from("profiles")
    .select("*")
    .eq("id", data.user.id)
    .maybeSingle();
  if (perr || !profile || !["admin", "staff", "owner"].includes(profile.role)) {
    dbg("auth:not-staff", { role: profile?.role });
    showLogin(true);
    return null;
  }
  state.profile = profile;
  document.getElementById("meName").textContent = profile.name || data.user.email || "Staff";
  document.getElementById("meRole").textContent = profile.role;
  showLogin(false);
  return profile;
}

function showLogin(show) {
  const overlay = document.getElementById("loginOverlay");
  if (!overlay) return;
  overlay.classList.toggle("hidden", !show);
}

function bindLogin() {
  const form = document.getElementById("loginForm");
  form?.addEventListener("submit", async (e) => {
    e.preventDefault();
    const fd = new FormData(form);
    const email = fd.get("email");
    const password = fd.get("password");
    dbg("login:submit", { email });
    const btn = document.getElementById("loginBtn");
    btn.disabled = true;
    const { error } = await state.supabase.auth.signInWithPassword({ email, password });
    btn.disabled = false;
    if (error) {
      showToast(error.message);
      dbg("login:error", error);
      return;
    }
    await requireStaff();
    setRoute("dashboard");
    renderContent();
    showToast("Signed in");
  });
}

function renderContent() {
  const root = document.getElementById("content");
  if (!root) return;
  root.innerHTML = "";
  const section = document.createElement("div");
  section.className = "space-y-4";
  switch (state.active) {
    case "dashboard":
      section.appendChild(viewDashboard());
      break;
    case "orders":
      section.appendChild(viewOrders());
      break;
    case "chats":
      section.appendChild(viewChats());
      break;
    case "menu":
      section.appendChild(viewMenu());
      break;
    case "delivery":
      section.appendChild(viewDelivery());
      break;
    case "staff":
      section.appendChild(viewStaff());
      break;
    default:
      section.appendChild(placeholder(state.active));
  }
  root.appendChild(section);
}

function viewDashboard() {
  const wrap = document.createElement("div");
  wrap.innerHTML = `
    <div class="grid grid-cols-1 md:grid-cols-4 gap-3">
      ${["Today Orders", "Revenue", "Avg Prep", "Active Chats"]
        .map(
          (t, i) => `
        <div class="card p-4">
          <div class="text-sm text-slate-500">${t}</div>
          <div class="text-2xl font-extrabold mt-2" id="kpi-${i}">—</div>
        </div>
      `
        )
        .join("")}
    </div>
    <div class="card p-4 mt-3">
      <div class="flex items-center justify-between">
        <div>
          <div class="text-lg font-bold">Recent Orders</div>
          <div class="text-sm text-slate-500">Live updates</div>
        </div>
        <button class="px-3 py-2 rounded-lg bg-slate-900 text-white" onclick="window.location.hash='orders'">View all</button>
      </div>
      <div id="recentOrders" class="mt-3 space-y-2"></div>
    </div>
    <div class="card p-4 mt-3">
      <div class="text-lg font-bold mb-2">Notifications</div>
      <div id="notifList" class="space-y-2 text-sm"></div>
    </div>
  `;
  fetchRecentOrders();
  fetchAnalytics();
  renderNotificationsList("notifList");
  return wrap;
}

async function fetchRecentOrders() {
  const list = document.getElementById("recentOrders");
  if (!list || !state.supabase) return;
  list.innerHTML = `<div class="text-sm text-slate-500">Loading...</div>`;
  const { data, error } = await state.supabase
    .from("orders")
    .select("id,status,total,created_at")
    .order("created_at", { ascending: false })
    .limit(8);
  if (error) {
    list.innerHTML = `<div class="text-red-500 text-sm">${error.message}</div>`;
    return;
  }
  list.innerHTML = data
    .map(
      (o) => `
      <div class="flex items-center justify-between border border-surface-200 dark:border-white/10 rounded-lg px-3 py-2">
        <div class="text-sm font-semibold">#${o.id.slice(0, 8)}</div>
        <div class="text-xs uppercase tracking-wide">${o.status}</div>
        <div class="text-sm font-bold">GH₵ ${Number(o.total || 0).toFixed(2)}</div>
      </div>`
    )
    .join("");
}

async function fetchAnalytics() {
  if (!state.supabase) return;
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const iso = today.toISOString();

  const { data: todayOrders } = await state.supabase
    .from("orders")
    .select("total,status")
    .gte("created_at", iso);
  const ordersCount = todayOrders?.length || 0;
  const revenue = todayOrders?.reduce((s, o) => s + Number(o.total || 0), 0) || 0;
  const cancels = todayOrders?.filter((o) => o.status === "cancelled").length || 0;

  const { data: openChats } = await state.supabase
    .from("conversations")
    .select("id")
    .is("closed_at", null)
    .limit(100);

  const kpis = [
    ordersCount.toString(),
    `GH₵ ${revenue.toFixed(2)}`,
    "—",
    (openChats?.length || 0).toString(),
  ];
  kpis.forEach((val, i) => {
    const el = document.getElementById(`kpi-${i}`);
    if (el) el.textContent = val;
  });
}

function viewOrders() {
  const wrap = document.createElement("div");
  wrap.innerHTML = `
    <div class="card p-4 space-y-3">
      <div class="flex items-center justify-between">
        <div>
          <div class="text-lg font-bold">Orders</div>
          <div class="text-sm text-slate-500">Filter by status</div>
        </div>
        <select id="ordersFilter" class="h-10 px-3 rounded-lg border border-surface-200">
          <option value="">All</option>
          <option value="new">New</option>
          <option value="preparing">Preparing</option>
          <option value="ready">Ready</option>
          <option value="enroute">Out for delivery</option>
          <option value="delivered">Delivered</option>
          <option value="cancelled">Cancelled</option>
        </select>
      </div>
      <div id="ordersList" class="space-y-2"></div>
    </div>
  `;
  const filter = wrap.querySelector("#ordersFilter");
  filter.addEventListener("change", () => fetchOrders(filter.value));
  fetchOrders("");
  return wrap;
}

async function fetchOrders(status) {
  const list = document.getElementById("ordersList");
  if (!list || !state.supabase) return;
  list.innerHTML = `<div class="text-sm text-slate-500">Loading...</div>`;
  let query = state.supabase.from("orders").select("id,status,total,created_at").order("created_at", { ascending: false }).limit(20);
  if (status) query = query.eq("status", status);
  const { data, error } = await query;
  if (error) {
    list.innerHTML = `<div class="text-red-500 text-sm">${error.message}</div>`;
    return;
  }
  state.orders = data || [];
  list.innerHTML = data
    .map(
      (o) => `
        <div class="flex items-center justify-between border border-surface-200 dark:border-white/10 rounded-lg px-3 py-2">
          <div>
            <div class="font-semibold">#${o.id.slice(0, 8)}</div>
            <div class="text-xs text-slate-500">${new Date(o.created_at).toLocaleString()}</div>
          </div>
          <div class="text-xs uppercase tracking-wide">${o.status}</div>
          <div class="font-bold">GH₵ ${Number(o.total || 0).toFixed(2)}</div>
        </div>`
    )
    .join("");
}

function viewChats() {
  const wrap = document.createElement("div");
  wrap.innerHTML = `
    <div class="grid md:grid-cols-[280px,1fr,300px] gap-3">
      <div class="card p-3 space-y-2">
        <div class="flex items-center justify-between">
          <div class="font-bold">Conversations</div>
          <button id="reloadChats" class="text-xs px-2 py-1 rounded-lg bg-slate-100">Reload</button>
        </div>
        <div id="chatList" class="space-y-2 text-sm"></div>
      </div>
      <div class="card p-3 space-y-3">
        <div class="font-bold">Thread</div>
        <div id="chatThread" class="min-h-[260px] space-y-2 text-sm overflow-auto"></div>
        <form id="chatForm" class="flex gap-2">
          <input id="chatInput" class="flex-1 h-10 px-3 rounded-lg border border-surface-200" placeholder="Type message..." />
          <button class="h-10 px-3 rounded-lg bg-brand-600 text-white">Send</button>
        </form>
      </div>
      <div class="card p-3 space-y-2">
        <div class="font-bold">Order context</div>
        <div id="chatOrderCtx" class="text-sm text-slate-500">Select a conversation</div>
      </div>
    </div>
  `;
  wrap.querySelector("#reloadChats").addEventListener("click", fetchChats);
  wrap.querySelector("#chatForm").addEventListener("submit", sendChatMessage);
  fetchChats();
  return wrap;
}

async function fetchChats() {
  const list = document.getElementById("chatList");
  if (!list || !state.supabase) return;
  list.innerHTML = `<div class="text-sm text-slate-500">Loading...</div>`;
  const { data, error } = await state.supabase
    .from("conversations")
    .select("id,order_id,type,created_at")
    .order("created_at", { ascending: false })
    .limit(20);
  if (error) {
    list.innerHTML = `<div class="text-red-500 text-sm">${error.message}</div>`;
    return;
  }
  state.conversations = data || [];
  list.innerHTML = data
    .map(
      (c) => `
        <button class="w-full text-left border border-surface-200 dark:border-white/10 rounded-lg px-3 py-2 hover:bg-slate-50" data-id="${c.id}">
          <div class="font-semibold">Order #${c.order_id?.slice(0, 8) || "—"}</div>
          <div class="text-xs text-slate-500">${c.type}</div>
        </button>`
    )
    .join("");
  list.querySelectorAll("button").forEach((btn) => btn.addEventListener("click", () => openConversation(btn.dataset.id)));
}

async function openConversation(id) {
  const thread = document.getElementById("chatThread");
  const ctx = document.getElementById("chatOrderCtx");
  thread.innerHTML = `<div class="text-sm text-slate-500">Loading thread...</div>`;
  const { data, error } = await state.supabase
    .from("messages")
    .select("id,text,sender_role,created_at")
    .eq("conversation_id", id)
    .order("created_at", { ascending: true })
    .limit(50);
  if (error) {
    thread.innerHTML = `<div class="text-red-500 text-sm">${error.message}</div>`;
    return;
  }
  thread.innerHTML = data
    .map(
      (m) => `
      <div class="p-2 rounded-lg ${m.sender_role === "staff" ? "bg-brand-50" : "bg-slate-100"}">
        <div class="text-xs text-slate-500">${m.sender_role} • ${new Date(m.created_at).toLocaleTimeString()}</div>
        <div class="font-medium">${m.text || ""}</div>
      </div>`
    )
    .join("");
  ctx.textContent = `Conversation ${id.slice(0, 8)} • ${data.length} messages`;
  thread.dataset.active = id;
}

async function sendChatMessage(e) {
  e.preventDefault();
  const input = document.getElementById("chatInput");
  const thread = document.getElementById("chatThread");
  const convoId = thread?.dataset.active;
  if (!convoId) {
    showToast("Select a conversation first");
    return;
  }
  const text = input.value.trim();
  if (!text) return;
  const { error } = await state.supabase.from("messages").insert({
    conversation_id: convoId,
    text,
    sender_role: "staff",
    message_type: "text",
  });
  if (error) {
    showToast(error.message);
    return;
  }
  input.value = "";
  openConversation(convoId);
}

function viewMenu() {
  const wrap = document.createElement("div");
  wrap.innerHTML = `
    <div class="card p-4 space-y-3">
      <div class="flex items-center justify-between">
        <div>
          <div class="text-lg font-bold">Menu</div>
          <div class="text-sm text-slate-500">Items & categories</div>
        </div>
        <button id="addMenuItem" class="px-3 py-2 rounded-lg bg-brand-600 text-white">Add item</button>
      </div>
      <div id="menuList" class="grid md:grid-cols-2 gap-3"></div>
    </div>
  `;
  wrap.querySelector("#addMenuItem").addEventListener("click", () => showToast("Not implemented in demo"));
  fetchMenu();
  return wrap;
}

async function fetchMenu() {
  const list = document.getElementById("menuList");
  if (!list || !state.supabase) return;
  list.innerHTML = `<div class="text-sm text-slate-500">Loading...</div>`;
  const { data, error } = await state.supabase
    .from("menu_items")
    .select("id,name,price,description,is_available")
    .order("created_at", { ascending: false })
    .limit(20);
  if (error) {
    list.innerHTML = `<div class="text-red-500 text-sm">${error.message}</div>`;
    return;
  }
  list.innerHTML = data
    .map(
      (m) => `
      <div class="border border-surface-200 dark:border-white/10 rounded-xl p-3 space-y-1">
        <div class="flex items-center justify-between">
          <div class="font-semibold">${m.name}</div>
          <span class="text-xs px-2 py-1 rounded-full ${m.is_available ? "bg-green-100 text-green-700" : "bg-slate-200 text-slate-700"}">
            ${m.is_available ? "Available" : "Sold out"}
          </span>
        </div>
        <div class="text-sm text-slate-500">${m.description || ""}</div>
        <div class="font-bold">GH₵ ${Number(m.price || 0).toFixed(2)}</div>
      </div>`
    )
    .join("");
}

function viewDelivery() {
  const wrap = document.createElement("div");
  wrap.innerHTML = `
    <div class="card p-4 space-y-3">
      <div class="text-lg font-bold">Delivery Settings</div>
      <div class="grid md:grid-cols-2 gap-3">
        ${[
          { id: "base_fee", label: "Base fee" },
          { id: "free_radius_km", label: "Free radius (km)" },
          { id: "per_km_fee_after_free_radius", label: "Per km fee after free radius" },
          { id: "minimum_order_amount", label: "Minimum order amount" },
          { id: "max_delivery_distance_km", label: "Max delivery distance (km)" },
        ]
          .map(
            (f) => `
          <label class="space-y-1 block">
            <div class="text-sm font-semibold">${f.label}</div>
            <input data-field="${f.id}" type="number" step="0.01" class="h-11 px-3 rounded-lg border border-surface-200 w-full" />
          </label>`
          )
          .join("")}
      </div>
      <button id="saveDelivery" class="h-11 px-4 rounded-lg bg-brand-600 text-white w-fit">Save</button>
      <div id="deliveryStatus" class="text-sm text-slate-500"></div>
    </div>
  `;
  wrap.querySelector("#saveDelivery").addEventListener("click", saveDelivery);
  loadDelivery();
  return wrap;
}

async function loadDelivery() {
  const statusEl = document.getElementById("deliveryStatus");
  statusEl.textContent = "Loading...";
  const { data, error } = await state.supabase.from("delivery_settings").select("*").limit(1).maybeSingle();
  if (error) {
    statusEl.textContent = error.message;
    return;
  }
  if (data) {
    document.querySelectorAll("[data-field]").forEach((input) => {
      input.value = data[input.dataset.field] ?? "";
    });
    statusEl.textContent = "Loaded.";
  } else {
    statusEl.textContent = "No settings yet.";
  }
}

async function saveDelivery() {
  const payload = {};
  document.querySelectorAll("[data-field]").forEach((input) => {
    payload[input.dataset.field] = Number(input.value || 0);
  });
  const existing = await state.supabase.from("delivery_settings").select("id").limit(1).maybeSingle();
  let error = null;
  if (existing.data?.id) {
    ({ error } = await state.supabase.from("delivery_settings").update(payload).eq("id", existing.data.id));
  } else {
    ({ error } = await state.supabase.from("delivery_settings").insert(payload));
  }
  if (error) {
    showToast(error.message);
    return;
  }
  showToast("Saved");
  loadDelivery();
}

function viewStaff() {
  const wrap = document.createElement("div");
  wrap.innerHTML = `
    <div class="card p-4 space-y-3">
      <div class="flex items-center justify-between">
        <div>
          <div class="text-lg font-bold">Staff & Roles</div>
          <div class="text-sm text-slate-500">Allowlist emails for admin/staff.</div>
        </div>
        <button id="addStaffBtn" class="px-3 py-2 rounded-lg bg-brand-600 text-white">Add</button>
      </div>
      <div class="grid md:grid-cols-[1fr,140px] gap-3">
        <input id="staffEmail" class="h-11 px-3 rounded-lg border border-surface-200" placeholder="staff@example.com" />
        <select id="staffRole" class="h-11 px-3 rounded-lg border border-surface-200">
          <option value="admin">admin</option>
          <option value="staff">staff</option>
        </select>
      </div>
      <div id="staffList" class="space-y-2"></div>
    </div>
  `;
  wrap.querySelector("#addStaffBtn").addEventListener("click", saveStaff);
  loadStaff();
  return wrap;
}

async function saveStaff() {
  const email = document.getElementById("staffEmail").value.trim().toLowerCase();
  const role = document.getElementById("staffRole").value;
  if (!email.includes("@")) return showToast("Enter a valid email");
  const { error } = await state.supabase.from("staff_allowlist").upsert({ email, role }, { onConflict: "email" });
  if (error) return showToast(error.message);
  showToast("Saved");
  loadStaff();
}

async function loadStaff() {
  const list = document.getElementById("staffList");
  list.innerHTML = `<div class="text-sm text-slate-500">Loading...</div>`;
  const { data, error } = await state.supabase.from("staff_allowlist").select("*").order("created_at", { ascending: false });
  if (error) {
    list.innerHTML = `<div class="text-red-500 text-sm">${error.message}</div>`;
    return;
  }
  list.innerHTML = data
    .map(
      (row) => `
      <div class="flex items-center justify-between border border-surface-200 dark:border-white/10 rounded-lg px-3 py-2">
        <div>
          <div class="font-semibold">${row.email}</div>
          <div class="text-xs text-slate-500">${row.role}</div>
        </div>
      </div>`
    )
    .join("");
}

function placeholder(id) {
  const div = document.createElement("div");
  div.className = "card p-4";
  div.innerHTML = `<div class="text-lg font-bold capitalize">${id}</div><div class="text-sm text-slate-500">Not implemented in this static build.</div>`;
  return div;
}

async function setupRealtime() {
  if (!state.supabase) return;
  const channel = state.supabase
    .channel("admin-realtime")
    .on(
      "postgres_changes",
      { event: "*", schema: "public", table: "orders" },
      () => {
        fetchOrders(document.getElementById("ordersFilter")?.value || "");
        fetchRecentOrders();
        fetchAnalytics();
      }
    )
    .on(
      "postgres_changes",
      { event: "INSERT", schema: "public", table: "messages" },
      () => {
        const active = document.getElementById("chatThread")?.dataset.active;
        if (active) openConversation(active);
        fetchChats();
      }
    )
    .on(
      "postgres_changes",
      { event: "INSERT", schema: "public", table: "staff_notifications" },
      fetchNotifications
    )
    .subscribe((status) => dbg("realtime:status", status));
}

async function fetchNotifications() {
  const { data, error } = await state.supabase
    .from("staff_notifications")
    .select("id,title,body,is_read,created_at")
    .order("created_at", { ascending: false })
    .limit(20);
  if (error) {
    dbg("notif:error", error.message);
    return;
  }
  state.notifications = data || [];
  renderNotificationsList("notifList");
  renderNotifBadge();
}

function renderNotificationsList(elId) {
  const el = document.getElementById(elId);
  if (!el) return;
  if (!state.notifications.length) {
    el.innerHTML = `<div class="text-sm text-slate-500">No notifications</div>`;
    return;
  }
  el.innerHTML = state.notifications
    .map(
      (n) => `
        <div class="border border-surface-200 dark:border-white/10 rounded-lg px-3 py-2">
          <div class="flex justify-between text-xs text-slate-500"><span>${new Date(n.created_at).toLocaleString()}</span>${n.is_read ? "" : "<span class='text-brand-700'>●</span>"}</div>
          <div class="font-semibold">${n.title || "Notification"}</div>
          <div class="text-sm text-slate-500">${n.body || ""}</div>
        </div>`
    )
    .join("");
}

function renderNotifBadge() {
  const btn = document.getElementById("notifBtn");
  const unread = state.notifications.filter((n) => !n.is_read).length;
  btn?.setAttribute("data-badge", unread ? unread.toString() : "");
  if (unread) btn.classList.add("relative");
  else btn?.classList.remove("relative");
}

async function bootstrap() {
  dbg("boot:start");
  initSupabase();
  renderNav();
  bindLogin();
  const hash = window.location.hash.replace("#", "");
  setRoute(hash || "dashboard");
  await requireStaff(); // will show login if not authed
  renderContent();
  await fetchNotifications();
  await setupRealtime();
}

document.addEventListener("DOMContentLoaded", bootstrap);

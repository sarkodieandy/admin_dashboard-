import { createSupabase } from "./supabase.js";
import { router, routeTitles } from "./router.js";
import { toast } from "./toast.js";
import { renderDashboard } from "./pages/dashboard.js";
import { renderOrders } from "./pages/orders.js";
import { renderMenu } from "./pages/menu.js";
import { renderCustomers } from "./pages/customers.js";
import { renderChats } from "./pages/chats.js";
import { renderNotifications } from "./pages/notifications.js";
import { renderDeliverySettings } from "./pages/delivery-settings.js";
import { renderStaff } from "./pages/staff.js";
import { renderSettings } from "./pages/settings.js";

const DEBUG = true;
const debugPanel = document.getElementById("debugPanel");
function dbg(msg, data) {
  if (!DEBUG) return;
  // eslint-disable-next-line no-console
  console.log(`[admin] ${msg}`, data ?? "");

  if (!debugPanel) return;
  debugPanel.hidden = false;
  const line = document.createElement("div");
  line.className = "debug-line";
  const payload = data == null ? "" : ` ${safeJson(data)}`;
  line.textContent = `[admin] ${msg}${payload}`;
  debugPanel.appendChild(line);
  // keep last 40 lines
  while (debugPanel.childNodes.length > 40) {
    debugPanel.removeChild(debugPanel.firstChild);
  }
  debugPanel.scrollTop = debugPanel.scrollHeight;
}

function safeJson(v) {
  try {
    return JSON.stringify(v);
  } catch {
    return String(v);
  }
}

let supabase = null;
try {
  supabase = createSupabase();
  dbg("boot:supabase_client_created");
} catch (e) {
  console.error("[config] Supabase config missing/invalid", e);
  const overlay = document.getElementById("loginOverlay");
  if (overlay) overlay.hidden = true;
  const view = document.getElementById("view");
  if (view) {
    view.innerHTML = `
      <div class="card">
        <div class="card-header">
          <div class="card-title">Missing Supabase config</div>
          <div class="card-sub">Add Netlify env vars or edit the meta tags in <code>index.html</code>.</div>
        </div>
        <div class="card-content">
          <div class="p">Required:</div>
          <div class="hint"><code>NEXT_PUBLIC_SUPABASE_URL</code></div>
          <div class="hint"><code>NEXT_PUBLIC_SUPABASE_ANON_KEY</code></div>
        </div>
      </div>
    `;
  }
  toast.error("Config error", e instanceof Error ? e.message : String(e));
}

const view = document.getElementById("view");
const crumbs = document.getElementById("crumbs");
const sidebar = document.getElementById("sidebar");
const menuBtn = document.getElementById("menuBtn");
const signOutBtn = document.getElementById("signOutBtn");
const loginOverlay = document.getElementById("loginOverlay");
const meName = document.getElementById("meName");
const meRole = document.getElementById("meRole");

const allowedRoles = new Set(["admin", "staff"]);

let cachedUser = null;
let cachedProfile = null;

const pages = {
  "/dashboard": renderDashboard,
  "/orders": renderOrders,
  "/menu": renderMenu,
  "/customers": renderCustomers,
  "/chats": renderChats,
  "/notifications": renderNotifications,
  "/delivery-settings": renderDeliverySettings,
  "/staff": renderStaff,
  "/settings": renderSettings,
};

function setSidebarOpen(open) {
  if (!sidebar) return;
  sidebar.classList.toggle("open", !!open);
}

menuBtn?.addEventListener("click", () => setSidebarOpen(true));
document.addEventListener("click", (e) => {
  const target = e.target;
  if (!(target instanceof HTMLElement)) return;
  if (window.matchMedia("(max-width: 980px)").matches) {
    if (sidebar?.classList.contains("open")) {
      const inSidebar = sidebar.contains(target);
      const inBtn = menuBtn?.contains(target);
      if (!inSidebar && !inBtn) setSidebarOpen(false);
    }
  }
});

function setActiveNav(route) {
  document.querySelectorAll(".nav-item").forEach((a) => {
    if (!(a instanceof HTMLAnchorElement)) return;
    a.classList.toggle("active", a.dataset.route === route);
  });
}

async function fetchProfile(userId) {
  const { data, error } = await supabase.from("profiles").select("*").eq("id", userId).maybeSingle();
  if (error) throw error;
  return data ?? null;
}

function showLogin(show) {
  if (!loginOverlay) return;
  loginOverlay.hidden = !show;
}

async function ensureAuthed() {
  if (!supabase) return { ok: false, user: null, profile: null };

  try {
    if (cachedUser && cachedProfile) {
      return { ok: true, user: cachedUser, profile: cachedProfile, reason: "cached" };
    }

    // Prefer local session (more reliable on mobile) over getUser() network call.
    const { data: sessionData, error: sessionError } = await supabase.auth.getSession();
    if (sessionError) throw sessionError;

    const session = sessionData.session;
    const user = session?.user ?? null;
    if (!user) {
      dbg("ensureAuthed:no_session");
      return { ok: false, user: null, profile: null, reason: "no_session" };
    }

    dbg("ensureAuthed:session_ok", { userId: user.id, email: user.email });

    const profile = await fetchProfile(user.id);
    if (!profile?.role || !allowedRoles.has(profile.role)) {
      dbg("ensureAuthed:not_staff", { role: profile?.role ?? null });
      return { ok: false, user, profile, reason: "not_staff" };
    }

    cachedUser = user;
    cachedProfile = profile;
    dbg("ensureAuthed:ok", { role: profile.role });
    return { ok: true, user, profile, reason: "ok" };
  } catch (e) {
    console.error("[auth] ensureAuthed failed", e);
    toast.error("Auth error", e instanceof Error ? e.message : String(e));
    return { ok: false, user: null, profile: null, reason: "auth_error" };
  }
}

async function renderRoute(route) {
  dbg("route:render", { route });
  const authed = await ensureAuthed();
  if (!authed.ok) {
    if (meName) meName.textContent = "Not signed in";
    if (meRole) meRole.textContent = "—";
    showLogin(true);
    if (view) view.innerHTML = "";
    dbg("route:block", { reason: authed.reason });
    return;
  }

  if (meName) meName.textContent = authed.profile?.name || authed.user?.email || "Signed in";
  if (meRole) meRole.textContent = authed.profile?.role || "—";
  showLogin(false);

  const title = routeTitles[route] || "Dashboard";
  crumbs.textContent = title;
  setActiveNav(route);
  setSidebarOpen(false);

  const render = pages[route] || renderDashboard;

  if (view) view.innerHTML = `<div class="card"><div class="card-content"><div class="p">Loading…</div></div></div>`;
  try {
    const node = await render({ supabase, toast });
    if (view) {
      view.innerHTML = "";
      view.appendChild(node);
    }
  } catch (e) {
    console.error("[route] render failed", e);
    toast.error("Load failed", e instanceof Error ? e.message : String(e));
    if (view) view.innerHTML = `<div class="card"><div class="card-content"><div class="p">Failed to load.</div></div></div>`;
  }
}

// Login form
document.getElementById("loginForm")?.addEventListener("submit", async (e) => {
  e.preventDefault();
  const form = e.target;
  if (!(form instanceof HTMLFormElement)) return;
  const fd = new FormData(form);
  const email = String(fd.get("email") || "").trim();
  const password = String(fd.get("password") || "");
  if (!email || !password) return;

  const btn = document.getElementById("loginBtn");
  btn?.setAttribute("disabled", "true");
  try {
    dbg("login:submit", { email });
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) throw error;

    // Use returned session immediately (more reliable on iOS).
    const session = data?.session;
    const user = session?.user;
    if (user) {
      const profile = await fetchProfile(user.id);
      cachedUser = user;
      cachedProfile = profile;
      dbg("login:session_cached", { role: profile?.role ?? null });
    }

    const authed = await ensureAuthed();
    if (!authed.ok) {
      dbg("login:blocked", { reason: authed.reason, role: authed.profile?.role ?? null });
      if (authed.reason === "no_session") {
        toast.error("Login failed", "Session not saved. Use Safari/Chrome (not in-app) and disable Private mode.");
      } else {
        toast.error("Access restricted", "This account is not admin/staff.");
      }
      showLogin(true);
      cachedUser = null;
      cachedProfile = null;
      await supabase.auth.signOut();
      return;
    }

    toast.success("Welcome back", "Signed in successfully.");
    showLogin(false);
    // Hash might already be /dashboard; render explicitly to avoid no-op navigation.
    router.navigate("/dashboard");
    await renderRoute("/dashboard");
  } catch (err) {
    console.error("[login] failed", err);
    toast.error("Sign in failed", err?.message || String(err));
  } finally {
    btn?.removeAttribute("disabled");
  }
});

async function signOut() {
  try {
    await supabase.auth.signOut();
  } catch {
    // ignore
  } finally {
    cachedUser = null;
    cachedProfile = null;
    showLogin(true);
    if (view) view.innerHTML = "";
  }
}

signOutBtn?.addEventListener("click", signOut);

// React to auth changes (e.g. refreshed tokens)
if (supabase) {
  supabase.auth.onAuthStateChange((_evt) => {
    dbg("auth:event", { evt: _evt });
  });
}

if (supabase) {
  // Always start on login overlay.
  showLogin(true);
  if (meName) meName.textContent = "Not signed in";
  if (meRole) meRole.textContent = "—";

  dbg("boot:router_start", { route: router.current?.() ?? null, hash: window.location.hash });
  router.start({
    defaultRoute: "/dashboard",
    onRoute: (route) => renderRoute(route),
  });
}

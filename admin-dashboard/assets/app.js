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

let supabase = null;
try {
  supabase = createSupabase();
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
const deniedOverlay = document.getElementById("deniedOverlay");
const deniedSignOutBtn = document.getElementById("deniedSignOutBtn");
const meName = document.getElementById("meName");
const meRole = document.getElementById("meRole");

const allowedRoles = new Set(["admin", "staff"]);

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
  return data;
}

function showLogin(show) {
  loginOverlay.hidden = !show;
}

function showDenied(show) {
  deniedOverlay.hidden = !show;
}

async function ensureAuthed() {
  if (!supabase) return { ok: false, user: null, profile: null };
  const { data } = await supabase.auth.getUser();
  const user = data.user;
  if (!user) {
    meName.textContent = "Not signed in";
    meRole.textContent = "—";
    showDenied(false);
    showLogin(true);
    return { ok: false, user: null, profile: null };
  }

  const profile = await fetchProfile(user.id);
  meName.textContent = profile?.name || user.email || "Signed in";
  meRole.textContent = profile?.role || "—";

  if (!profile?.role || !allowedRoles.has(profile.role)) {
    showLogin(false);
    showDenied(true);
    return { ok: false, user, profile };
  }

  showLogin(false);
  showDenied(false);
  return { ok: true, user, profile };
}

async function renderRoute(route) {
  const authed = await ensureAuthed();
  if (!authed.ok) {
    // If denied, keep them on current hash but block view render.
    view.innerHTML = "";
    return;
  }

  const title = routeTitles[route] || "Dashboard";
  crumbs.textContent = title;
  setActiveNav(route);
  setSidebarOpen(false);

  const render = pages[route] || renderDashboard;

  view.innerHTML = `<div class="card"><div class="card-content"><div class="p">Loading…</div></div></div>`;
  try {
    const node = await render({ supabase, toast });
    view.innerHTML = "";
    view.appendChild(node);
  } catch (e) {
    console.error("[route] render failed", e);
    toast.error("Load failed", e instanceof Error ? e.message : String(e));
    view.innerHTML = `<div class="card"><div class="card-content"><div class="p">Failed to load.</div></div></div>`;
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
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) throw error;
    toast.success("Welcome back", "Signed in successfully.");
    router.navigate("/dashboard");
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
    showDenied(false);
    showLogin(true);
    router.navigate("/dashboard");
  }
}

signOutBtn?.addEventListener("click", signOut);
deniedSignOutBtn?.addEventListener("click", signOut);

// React to auth changes (e.g. refreshed tokens)
if (supabase) {
  supabase.auth.onAuthStateChange((_evt) => {
    // Re-render current route, letting ensureAuthed drive overlays.
    renderRoute(router.current());
  });
}

if (supabase) {
  router.start({
    defaultRoute: "/dashboard",
    onRoute: (route) => renderRoute(route),
  });
}

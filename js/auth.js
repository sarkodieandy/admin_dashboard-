import { createClient } from "./supabaseClient.js";
import { showToast } from "./ui.js";

const supabase = createClient();
const PROFILE_CACHE_TTL_MS = 90 * 1000;

export function normalizeRole(role) {
  if (!role) return null;
  let r = String(role).trim().toLowerCase();
  r = r.replace(/[\s-]+/g, '_');
  const aliases = {
    owner: 'restaurant_owner',
    restaurant: 'restaurant_owner',
    owner_admin: 'restaurant_owner',
    restaurant_admin: 'restaurant_owner',
    operator: 'staff',
    manager: 'staff',
    chef: 'staff',
    staff_admin: 'staff',
    admin_staff: 'staff',
    branch_manager: 'branch_admin',
    superadmin: 'super_admin',
    platformadmin: 'platform_admin',
  };
  if (aliases[r]) r = aliases[r];
  return r;
}

const SESSION_STORAGE_KEY = "admin_session_profile_v1";

function redirectTo(url) {
  window.location.href = url;
  // Prevent follow-up JS from running after redirects (pages often destructure `await requireAuth()`).
  return new Promise(() => {});
}

function isPlatformRole(role) {
  const r = normalizeRole(role);
  return r === "platform_admin" || r === "super_admin";
}

export function isStaffRole(role) {
  const r = normalizeRole(role);
  return [
    "platform_admin",
    "super_admin",
    "restaurant_owner",
    "branch_admin",
    "admin",
    "staff",
    "manager",
    "operator",
    "chef",
  ].includes(r ?? "");
}

function clearProfileCache() {
  try {
    localStorage.removeItem(SESSION_STORAGE_KEY);
    localStorage.removeItem("admin_role");
    localStorage.removeItem("admin_restaurant_id");
    localStorage.removeItem("admin_branch_id");
  } catch {}
}

function toStoredProfile(profile, userId) {
  const role = normalizeRole(profile?.role);
  return {
    id: profile?.id || userId || null,
    user_id: userId || profile?.id || null,
    role,
    restaurant_id: profile?.restaurant_id || null,
    branch_id: profile?.branch_id || null,
    is_active: profile?.is_active !== false,
    cached_at: Date.now(),
  };
}

function persistProfile(profile, userId) {
  try {
    const safe = toStoredProfile(profile, userId);
    localStorage.setItem(SESSION_STORAGE_KEY, JSON.stringify(safe));
    localStorage.setItem("admin_role", safe.role || "");
    localStorage.setItem("admin_restaurant_id", safe.restaurant_id || "");
    localStorage.setItem("admin_branch_id", safe.branch_id || "");
  } catch {}
}

function readCachedProfile(userId) {
  try {
    const raw = localStorage.getItem(SESSION_STORAGE_KEY);
    const parsed = raw ? JSON.parse(raw) : null;
    if (!parsed) return null;
    const cachedUserId = parsed.user_id || parsed.id || null;
    if (!cachedUserId || cachedUserId !== userId) return null;
    const cachedAt = Number(parsed.cached_at || 0);
    if (!cachedAt || Date.now() - cachedAt > PROFILE_CACHE_TTL_MS) return null;
    return {
      id: cachedUserId,
      role: parsed.role || null,
      restaurant_id: parsed.restaurant_id || null,
      branch_id: parsed.branch_id || null,
      is_active: parsed.is_active !== false,
    };
  } catch {
    return null;
  }
}

export function cacheSessionProfile(profile, userId) {
  persistProfile(profile, userId);
}

function mountLogoutButton({ profile }) {
  const topbar = document.querySelector(".topbar");
  if (!topbar) return;
  if (document.getElementById("logoutBtn")) return;

  const btn = document.createElement("button");
  btn.id = "logoutBtn";
  btn.className = "btn danger";
  btn.type = "button";
  btn.title = "Sign out";
  btn.setAttribute("aria-label", "Sign out");
  btn.textContent = "⎋ Logout";

  btn.addEventListener("click", async () => {
    btn.disabled = true;
    btn.textContent = "Signing out…";
    try {
      await supabase.auth.signOut();
    } catch {}
    clearProfileCache();
    window.location.href = "login.html";
  });

  // Optional context badge (role)
  if (!document.getElementById("sessionRoleBadge") && profile?.role) {
    const role = String(profile.role).replaceAll("_", " ");
    const badge = document.createElement("span");
    badge.id = "sessionRoleBadge";
    badge.className = "badge";
    badge.style.marginLeft = "6px";
    badge.style.background = "rgba(59,130,246,0.08)";
    badge.textContent = role;
    topbar.appendChild(badge);
  }

  topbar.appendChild(btn);
}

export async function fetchProfile(userId) {
  // Prefer RPC to avoid RLS recursion; fallback to direct select if RPC missing.
  const rpc = await supabase.rpc("get_my_profile");
  if (!rpc.error && rpc.data) {
    return { data: rpc.data, error: null };
  }
  const msg = String(rpc.error?.message || "").toLowerCase();
  const missing = rpc.error?.code === "PGRST202" || msg.includes("get_my_profile");
  const funcError =
    rpc.error?.code === "42804" ||
    msg.includes("return query") ||
    msg.includes("non setof") ||
    msg.includes("non-setof") ||
    msg.includes("syntax error");
  if (!missing && !funcError) {
    return { data: rpc.data || null, error: rpc.error || null };
  }
  const fallback = await supabase.from("profiles").select("*").eq("id", userId).maybeSingle();
  if (!fallback.error) return fallback;
  return { data: rpc.data || null, error: rpc.error || fallback.error || null };
}

async function enforceRestaurantAccess(profile, role) {
  if (isPlatformRole(role) || !profile?.restaurant_id) {
    return null;
  }

  try {
    const { data: restaurant, error: rErr } = await supabase
      .from("restaurants")
      .select("id,name,status,is_active")
      .eq("id", profile.restaurant_id)
      .maybeSingle();

    if (rErr?.code === "42P01" || !restaurant) {
      return null;
    }

    const status = restaurant.status || "pending";
    const active = restaurant.is_active !== false;
    if (!active || status === "suspended" || status === "pending") {
      persistProfile(profile, profile?.id);
      mountLogoutButton({ profile });
      window.__restaurantBlock = { status, name: restaurant.name || "" };
      const url = `suspended.html?status=${encodeURIComponent(status)}&name=${encodeURIComponent(restaurant.name || "")}`;
      if (!window.location.pathname.endsWith("/suspended.html")) {
        return redirectTo(url);
      }
    } else if (window.location.pathname.endsWith("/suspended.html")) {
      return redirectTo("dashboard.html");
    }
  } catch (_) {
    // Ignore and let RLS handle access.
  }

  return null;
}

export async function requireAuth() {
  const { data } = await supabase.auth.getSession();
  const user = data?.session?.user;
  if (!user) {
    clearProfileCache();
    return redirectTo("login.html");
  }
  const cachedProfile = readCachedProfile(user.id);
  const profileResult = cachedProfile
    ? { data: cachedProfile, error: null, fromCache: true }
    : await fetchProfile(user.id);
  const { data: profile, error } = profileResult;
  if (error || !profile) {
    showToast("Profile missing");
    try {
      await supabase.auth.signOut();
    } catch {}
    clearProfileCache();
    return redirectTo("login.html");
  }
  if (profile.is_active === false) {
    showToast("Account disabled. Contact the owner.");
    try {
      await supabase.auth.signOut();
    } catch {}
    clearProfileCache();
    return redirectTo("login.html");
  }
  if (!isStaffRole(profile.role)) {
    showToast("Access denied: staff only");
    try {
      await supabase.auth.signOut();
    } catch {}
    clearProfileCache();
    return redirectTo("login.html");
  }

  // Block suspended/pending restaurants from using the dashboard (platform admins excluded).
  const role = normalizeRole(profile.role);
  const normalizedProfile = { ...profile, id: profile.id || user.id, role };

  if (profileResult.fromCache) {
    enforceRestaurantAccess(normalizedProfile, role).catch(() => {});
  } else {
    const redirect = await enforceRestaurantAccess(normalizedProfile, role);
    if (redirect) return redirect;
  }
  persistProfile(normalizedProfile, user.id);
  try {
    window.__rerenderSidebar?.();
  } catch {}
  mountLogoutButton({ profile: normalizedProfile });
  window.__session = { user, profile: normalizedProfile, isPlatformAdmin: isPlatformRole(role) };
  return { user, profile: normalizedProfile };
}

export function getClient() {
  return supabase;
}

export function getCurrentScope() {
  try {
    const raw = localStorage.getItem(SESSION_STORAGE_KEY);
    const parsed = raw ? JSON.parse(raw) : {};
    const role = normalizeRole(parsed.role || localStorage.getItem("admin_role"));
    return {
      role,
      restaurant_id: parsed.restaurant_id || localStorage.getItem("admin_restaurant_id") || null,
      branch_id: parsed.branch_id || localStorage.getItem("admin_branch_id") || null,
    };
  } catch {
    return { role: null, restaurant_id: null, branch_id: null };
  }
}

export function isPlatformRolePublic(role) {
  return isPlatformRole(role);
}

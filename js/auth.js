import { createClient } from "./supabaseClient.js";
import { showToast } from "./ui.js";

const supabase = createClient();

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

export async function requireAuth() {
  const { data } = await supabase.auth.getSession();
  const user = data?.session?.user;
  if (!user) {
    window.location.href = "login.html";
    return null;
  }
  const { data: profile, error } = await supabase.from("profiles").select("*").eq("id", user.id).maybeSingle();
  if (error || !profile) {
    showToast("Profile missing");
    try {
      await supabase.auth.signOut();
    } catch {}
    window.location.href = "login.html";
    return null;
  }
  if (profile.is_active === false) {
    showToast("Account disabled. Contact the owner.");
    try {
      await supabase.auth.signOut();
    } catch {}
    window.location.href = "login.html";
    return null;
  }
  if (!["super_admin", "branch_admin", "admin", "staff"].includes(profile.role)) {
    showToast("Access denied: staff only");
    try {
      await supabase.auth.signOut();
    } catch {}
    window.location.href = "login.html";
    return null;
  }
  mountLogoutButton({ profile });
  return { user, profile };
}

export function getClient() {
  return supabase;
}

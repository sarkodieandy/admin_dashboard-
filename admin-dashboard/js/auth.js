import { createClient } from "./supabaseClient.js";
import { showToast } from "./ui.js";

const supabase = createClient();

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
  if (!["admin", "staff"].includes(profile.role)) {
    showToast("Access denied: staff only");
    try {
      await supabase.auth.signOut();
    } catch {}
    window.location.href = "login.html";
    return null;
  }
  return { user, profile };
}

export function getClient() {
  return supabase;
}

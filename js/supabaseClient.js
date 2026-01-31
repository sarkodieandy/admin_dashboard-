export function createClient() {
  if (!window.__SUPABASE_URL__ || !window.__SUPABASE_ANON_KEY__) {
    throw new Error("Supabase env missing. Set in env.js");
  }
  return window.supabase.createClient(window.__SUPABASE_URL__, window.__SUPABASE_ANON_KEY__);
}

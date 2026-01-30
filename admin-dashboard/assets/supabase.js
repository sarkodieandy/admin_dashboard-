function readMeta(name) {
  const meta = document.querySelector(`meta[name="${name}"]`);
  return meta?.getAttribute("content")?.trim() || "";
}

export function createSupabase() {
  const env = window.__ENV || {};

  const url = String(env.NEXT_PUBLIC_SUPABASE_URL || "").trim() || readMeta("supabase-url");
  const key = String(env.NEXT_PUBLIC_SUPABASE_ANON_KEY || "").trim() || readMeta("supabase-anon-key");

  if (!url || url === "__SUPABASE_URL__" || !key || key === "__SUPABASE_ANON_KEY__") {
    const hint =
      "Missing Supabase config. Set <meta name=\"supabase-url\"> and <meta name=\"supabase-anon-key\"> in index.html.";
    throw new Error(hint);
  }

  // global `supabase` provided by UMD bundle
  // eslint-disable-next-line no-undef
  return supabase.createClient(url, key);
}

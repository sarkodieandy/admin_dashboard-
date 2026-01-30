// Netlify overwrites this file at build time (see `netlify/build-env.sh`).
// Fallback is intentionally empty so local dev can use the meta tags in `index.html`.
window.__ENV = window.__ENV || {
  NEXT_PUBLIC_SUPABASE_URL: "",
  NEXT_PUBLIC_SUPABASE_ANON_KEY: "",
};


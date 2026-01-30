// deno-lint-ignore-file no-explicit-any
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { corsHeaders } from "../_shared/cors.ts";

// Stub endpoint for push/in-app notifications.
// In production you can:
// - Send FCM/APNs push
// - Insert into `public.notifications`
// - Fan-out to staff dashboards / riders
//
// This function is intentionally minimal.

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const payload = await req.json().catch(() => ({}));
  return new Response(JSON.stringify({ ok: true, received: payload }), {
    status: 200,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});


// deno-lint-ignore-file no-explicit-any
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";
import { paystackInitialize } from "../_shared/paystack.ts";

type InitBody = {
  email: string;
  amount: number;
  currency?: string;
  callback_url?: string;
  metadata?: Record<string, unknown>;
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const paystackSecretKey = Deno.env.get("PAYSTACK_SECRET_KEY");

    if (!supabaseUrl || !supabaseAnonKey) {
      return json(
        { error: "Missing SUPABASE_URL / SUPABASE_ANON_KEY" },
        500,
      );
    }
    if (!paystackSecretKey) {
      return json(
        { error: "Missing PAYSTACK_SECRET_KEY (set via `supabase secrets set`)" },
        500,
      );
    }

    const authHeader = req.headers.get("Authorization") ?? "";
    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: userData, error: userError } = await userClient.auth.getUser();
    if (userError || !userData.user) {
      return json({ error: "Unauthorized" }, 401);
    }

    const body = (await req.json()) as InitBody;
    const email = (body.email ?? "").trim();
    const amount = Number(body.amount ?? 0);
    const currency = (body.currency ?? "GHS").trim().toUpperCase();
    const callbackUrl = (body.callback_url ?? "").trim();

    if (!email) return json({ error: "Missing email" }, 400);
    if (!Number.isFinite(amount) || amount <= 0) {
      return json({ error: "Invalid amount" }, 400);
    }
    if (currency !== "GHS") return json({ error: "Only GHS is supported" }, 400);

    const init = await paystackInitialize(paystackSecretKey, {
      email,
      amount: Math.round(amount),
      currency,
      ...(callbackUrl ? { callback_url: callbackUrl } : {}),
      metadata: {
        user_id: userData.user.id,
        ...(body.metadata ?? {}),
      },
    });

    return json({ authorization_url: init.authorization_url, reference: init.reference }, 200);
  } catch (e) {
    return json({ error: e?.toString?.() ?? "Unknown error" }, 500);
  }
});

function json(payload: any, status: number) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}


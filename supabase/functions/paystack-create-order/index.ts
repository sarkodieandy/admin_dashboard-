// deno-lint-ignore-file no-explicit-any
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";
import { paystackVerify } from "../_shared/paystack.ts";

type CreateOrderItem = {
  item_id: string;
  name_snapshot: string;
  variant_snapshot?: string | null;
  addons_snapshot?: unknown[] | null;
  qty: number;
  price: number;
};

type CreatePaidOrderBody = {
  reference: string;
  subtotal: number;
  delivery_fee: number;
  discount: number;
  tip?: number;
  total: number;
  address_snapshot: Record<string, unknown>;
  scheduled_for?: string | null;
  items: CreateOrderItem[];
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const paystackSecretKey = Deno.env.get("PAYSTACK_SECRET_KEY");

    if (!supabaseUrl || !supabaseAnonKey) {
      return json(
        { error: "Missing SUPABASE_URL / SUPABASE_ANON_KEY" },
        500,
      );
    }
    if (!serviceRoleKey) {
      return json(
        { error: "Missing SUPABASE_SERVICE_ROLE_KEY (set via `supabase secrets set`)" },
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

    const body = (await req.json()) as CreatePaidOrderBody;
    const reference = (body.reference ?? "").trim();
    if (!reference) return json({ error: "Missing reference" }, 400);
    if (!Array.isArray(body.items) || body.items.length === 0) {
      return json({ error: "No items" }, 400);
    }

    const expectedAmount = Math.round(Number(body.total ?? 0) * 100);
    if (!Number.isFinite(expectedAmount) || expectedAmount <= 0) {
      return json({ error: "Invalid total" }, 400);
    }

    const verify = await paystackVerify(paystackSecretKey, reference);
    if (verify.status !== "success") {
      return json({ error: `Payment not successful (${verify.status})` }, 400);
    }
    if (verify.currency !== "GHS") {
      return json({ error: `Unexpected currency (${verify.currency})` }, 400);
    }
    if (verify.amount !== expectedAmount) {
      return json({ error: "Amount mismatch" }, 400);
    }

    const admin = createClient(supabaseUrl, serviceRoleKey);

    const { data: existingOrder, error: existingError } = await admin
      .from("orders")
      .select(
        "id,user_id,status,subtotal,delivery_fee,discount,tip,total,payment_method,payment_status,payment_reference,address_snapshot,scheduled_for,created_at",
      )
      .eq("payment_reference", reference)
      .maybeSingle();

    if (existingError) return json({ error: existingError.message }, 400);
    if (existingOrder) {
      if (existingOrder.user_id !== userData.user.id) {
        return json({ error: "Forbidden" }, 403);
      }
      return json({ order: existingOrder }, 200);
    }

    // NOTE: This is a stub implementation. For production:
    // - Recompute totals server-side from menu_items + variants + addons.
    // - Validate delivery fee rules, promo eligibility, minimum order, etc.
    const { data: order, error: orderError } = await admin
      .from("orders")
      .insert({
        user_id: userData.user.id,
        status: "placed",
        subtotal: body.subtotal,
        delivery_fee: body.delivery_fee,
        discount: body.discount,
        tip: body.tip ?? 0,
        total: body.total,
        payment_method: "paystack",
        payment_status: "paid",
        payment_reference: reference,
        address_snapshot: body.address_snapshot,
        scheduled_for: body.scheduled_for ?? null,
      })
      .select(
        "id,user_id,status,subtotal,delivery_fee,discount,tip,total,payment_method,payment_status,payment_reference,address_snapshot,scheduled_for,created_at",
      )
      .single();

    if (orderError) return json({ error: orderError.message }, 400);

    const items = body.items.map((it) => ({
      order_id: order.id,
      item_id: it.item_id,
      name_snapshot: it.name_snapshot,
      variant_snapshot: it.variant_snapshot ?? null,
      addons_snapshot: it.addons_snapshot ?? [],
      qty: it.qty,
      price: it.price,
    }));

    const { error: itemsError } = await admin.from("order_items").insert(items);
    if (itemsError) return json({ error: itemsError.message }, 400);

    return json({ order }, 200);
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


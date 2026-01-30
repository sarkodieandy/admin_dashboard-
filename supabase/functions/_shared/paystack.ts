// deno-lint-ignore-file no-explicit-any
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

type PaystackResponse<T> = {
  status: boolean;
  message?: string;
  data?: T;
};

export type PaystackInitData = {
  authorization_url: string;
  access_code: string;
  reference: string;
};

export type PaystackVerifyData = {
  status: string;
  reference: string;
  amount: number;
  currency: string;
};

export async function paystackInitialize(
  secretKey: string,
  payload: Record<string, unknown>,
): Promise<PaystackInitData> {
  const res = await fetch("https://api.paystack.co/transaction/initialize", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${secretKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  const json = (await res.json()) as PaystackResponse<PaystackInitData>;
  if (!res.ok || !json.status || !json.data) {
    throw new Error(json.message ?? "Paystack initialize failed");
  }
  return json.data;
}

export async function paystackVerify(
  secretKey: string,
  reference: string,
): Promise<PaystackVerifyData> {
  const res = await fetch(
    `https://api.paystack.co/transaction/verify/${encodeURIComponent(reference)}`,
    {
      headers: {
        Authorization: `Bearer ${secretKey}`,
        "Content-Type": "application/json",
      },
    },
  );

  const json = (await res.json()) as PaystackResponse<any>;
  if (!res.ok || !json.status || !json.data) {
    throw new Error(json.message ?? "Paystack verify failed");
  }

  return {
    status: String(json.data.status ?? ""),
    reference: String(json.data.reference ?? ""),
    amount: Number(json.data.amount ?? 0),
    currency: String(json.data.currency ?? ""),
  };
}


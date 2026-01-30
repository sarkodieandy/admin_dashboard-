"use client";

import { useMutation, useQuery } from "@tanstack/react-query";

import { useSupabase } from "@/lib/queries/supabase";
import type { Database } from "@/types/supabase";

type ProfileRow = Database["public"]["Tables"]["profiles"]["Row"];
type OrderRow = Database["public"]["Tables"]["orders"]["Row"];

export function useCustomers(params: { q: string; page: number; pageSize: number }) {
  const supabase = useSupabase();
  const { q, page, pageSize } = params;

  return useQuery({
    queryKey: ["customers", { q, page, pageSize }],
    queryFn: async () => {
      const from = page * pageSize;
      const to = from + pageSize - 1;

      let query = supabase
        .from("profiles")
        .select("*")
        .eq("role", "customer")
        .order("created_at", { ascending: false })
        .range(from, to);

      if (q.trim()) {
        const qq = q.trim();
        query = query.or(`name.ilike.%${qq}%,phone.ilike.%${qq}%`);
      }

      const { data, error } = await query;
      if (error) throw error;
      return (data as ProfileRow[]) ?? [];
    },
  });
}

export function useCustomerOrders(customerId: string | null) {
  const supabase = useSupabase();

  return useQuery({
    queryKey: ["customers", customerId, "orders"],
    enabled: !!customerId,
    queryFn: async () => {
      if (!customerId) return [];
      const { data, error } = await supabase
        .from("orders")
        .select("*")
        .eq("user_id", customerId)
        .order("created_at", { ascending: false })
        .limit(25);
      if (error) throw error;
      return (data as OrderRow[]) ?? [];
    },
  });
}

export function useUpdateCustomerProfile() {
  const supabase = useSupabase();

  return useMutation({
    mutationFn: async (vars: { id: string; name: string | null; phone: string | null; default_delivery_note: string | null }) => {
      const { error } = await supabase
        .from("profiles")
        .update({
          name: vars.name,
          phone: vars.phone,
          default_delivery_note: vars.default_delivery_note,
        })
        .eq("id", vars.id);
      if (error) throw error;
    },
  });
}


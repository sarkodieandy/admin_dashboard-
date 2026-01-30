"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { useProfile } from "@/lib/queries/profile";
import { useSupabase } from "@/lib/queries/supabase";
import type { Database } from "@/types/supabase";

type DeliverySettingsRow = Database["public"]["Tables"]["delivery_settings"]["Row"];

export function useDeliverySettings() {
  const supabase = useSupabase();
  const profile = useProfile();

  return useQuery({
    queryKey: ["settings", "delivery"],
    enabled: !!profile.data?.id,
    queryFn: async () => {
      const { data, error } = await supabase.from("delivery_settings").select("*").limit(1).maybeSingle();
      if (error) throw error;
      return (data as DeliverySettingsRow | null) ?? null;
    },
  });
}

export function useUpsertDeliverySettings() {
  const supabase = useSupabase();
  const qc = useQueryClient();

  return useMutation({
    mutationFn: async (values: Omit<DeliverySettingsRow, "id" | "updated_at">) => {
      const payload: Database["public"]["Tables"]["delivery_settings"]["Insert"] = values;
      const { error } = await supabase.from("delivery_settings").upsert(payload);
      if (error) throw error;
      return true;
    },
    onSuccess: async () => {
      await qc.invalidateQueries({ queryKey: ["settings", "delivery"] });
    },
  });
}

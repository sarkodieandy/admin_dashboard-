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
      // delivery_settings is intended as a singleton row.
      // Upsert without a stable unique key can accidentally create multiple rows,
      // so we update if a row exists, otherwise insert.
      const existing = await supabase.from("delivery_settings").select("id").limit(1).maybeSingle();
      if (existing.error) throw existing.error;

      if (existing.data?.id) {
        const { error } = await supabase.from("delivery_settings").update(values).eq("id", existing.data.id);
        if (error) throw error;
        return { id: existing.data.id, created: false };
      }

      const insertPayload: Database["public"]["Tables"]["delivery_settings"]["Insert"] = values;
      const { data, error } = await supabase.from("delivery_settings").insert(insertPayload).select("id").single();
      if (error) throw error;
      return { id: (data as { id: string }).id, created: true };
    },
    onSuccess: async () => {
      await qc.invalidateQueries({ queryKey: ["settings", "delivery"] });
    },
  });
}

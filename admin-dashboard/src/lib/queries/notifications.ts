"use client";

import { useQuery } from "@tanstack/react-query";

import { useSupabase } from "@/lib/queries/supabase";
import { useProfile } from "@/lib/queries/profile";
import type { Database } from "@/types/supabase";

type NotificationRow = Database["public"]["Tables"]["notifications"]["Row"];

export function useNotifications() {
  const supabase = useSupabase();
  const profile = useProfile();

  return useQuery({
    queryKey: ["notifications", profile.data?.id],
    enabled: !!profile.data?.id,
    queryFn: async () => {
      const userId = profile.data?.id;
      if (!userId) return [];
      const { data, error } = await supabase
        .from("notifications")
        .select("*")
        .eq("user_id", userId)
        .order("created_at", { ascending: false })
        .limit(20);
      if (error) throw error;
      return (data as NotificationRow[]) ?? [];
    },
  });
}

"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import * as React from "react";

import { useSupabase } from "@/lib/queries/supabase";
import { useProfile } from "@/lib/queries/profile";
import type { Database } from "@/types/supabase";

type NotificationRow = Database["public"]["Tables"]["notifications"]["Row"];
type StaffNotificationRow = Database["public"]["Tables"]["staff_notifications"]["Row"];

export type NotificationLike = {
  id: string;
  title: string;
  body: string | null;
  is_read: boolean;
  created_at: string;
  entity_type?: string | null;
  entity_id?: string | null;
  source: "staff_notifications" | "notifications";
};

export function useNotifications() {
  const supabase = useSupabase();
  const profile = useProfile();

  return useQuery({
    queryKey: ["notifications", profile.data?.id],
    enabled: !!profile.data?.id,
    queryFn: async () => {
      const userId = profile.data?.id;
      if (!userId) return [];

      // Prefer staff notifications (admin dashboard). Fall back to customer notifications if table doesn't exist.
      const staff = await supabase
        .from("staff_notifications")
        .select("*")
        .eq("recipient_id", userId)
        .order("created_at", { ascending: false })
        .limit(30);

      if (!staff.error) {
        return ((staff.data as StaffNotificationRow[]) ?? []).map(
          (n): NotificationLike => ({
            id: n.id,
            title: n.title,
            body: n.body,
            is_read: n.is_read,
            created_at: n.created_at,
            entity_type: n.entity_type,
            entity_id: n.entity_id,
            source: "staff_notifications",
          }),
        );
      }

      // 42P01 = undefined_table
      if (staff.error.code !== "42P01") throw staff.error;

      const { data, error } = await supabase
        .from("notifications")
        .select("*")
        .eq("user_id", userId)
        .order("created_at", { ascending: false })
        .limit(30);
      if (error) throw error;
      return ((data as NotificationRow[]) ?? []).map(
        (n): NotificationLike => ({
          id: n.id,
          title: n.title,
          body: n.body,
          is_read: n.is_read,
          created_at: n.created_at,
          source: "notifications",
        }),
      );
    },
  });
}

export function useRealtimeNotifications() {
  const supabase = useSupabase();
  const qc = useQueryClient();
  const profile = useProfile();

  React.useEffect(() => {
    const userId = profile.data?.id;
    if (!userId) return;

    const channel = supabase
      .channel(`realtime:notifications:${userId}`)
      .on("postgres_changes", { event: "*", schema: "public", table: "staff_notifications" }, () => {
        qc.invalidateQueries({ queryKey: ["notifications", userId] }).catch(() => {});
      })
      .on("postgres_changes", { event: "*", schema: "public", table: "notifications" }, () => {
        qc.invalidateQueries({ queryKey: ["notifications", userId] }).catch(() => {});
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [supabase, qc, profile.data?.id]);
}

export function useMarkNotificationRead() {
  const supabase = useSupabase();
  const qc = useQueryClient();
  const profile = useProfile();

  return useMutation({
    mutationFn: async (vars: { id: string; source: NotificationLike["source"] }) => {
      const table = vars.source;
      const idCol = "id";
      const { error } = await supabase.from(table).update({ is_read: true }).eq(idCol, vars.id);
      if (error) throw error;
    },
    onSuccess: async () => {
      await qc.invalidateQueries({ queryKey: ["notifications", profile.data?.id] });
    },
  });
}

export function useMarkAllNotificationsRead() {
  const supabase = useSupabase();
  const qc = useQueryClient();
  const profile = useProfile();

  return useMutation({
    mutationFn: async (vars: { source: NotificationLike["source"] }) => {
      const userId = profile.data?.id;
      if (!userId) return;
      if (vars.source === "staff_notifications") {
        const { error } = await supabase.from("staff_notifications").update({ is_read: true }).eq("recipient_id", userId).eq("is_read", false);
        if (error) throw error;
        return;
      }
      const { error } = await supabase.from("notifications").update({ is_read: true }).eq("user_id", userId).eq("is_read", false);
      if (error) throw error;
    },
    onSuccess: async () => {
      await qc.invalidateQueries({ queryKey: ["notifications", profile.data?.id] });
    },
  });
}

"use client";

import * as React from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { useProfile } from "@/lib/queries/profile";
import { useSupabase } from "@/lib/queries/supabase";
import type { Database, OrderStatus } from "@/types/supabase";

type OrderRow = Database["public"]["Tables"]["orders"]["Row"];
type OrderItemRow = Database["public"]["Tables"]["order_items"]["Row"];
type OrderStatusEventRow = Database["public"]["Tables"]["order_status_events"]["Row"];
type OrderListItem = OrderRow & { short_id: string };
type OrderDetail = OrderRow & { short_id: string; items: OrderItemRow[]; events: OrderStatusEventRow[] };

function shortId(id: string) {
  return id.replaceAll("-", "").slice(0, 8).toUpperCase();
}

export function useOrders(params: { statuses: OrderStatus[]; query: string }) {
  const supabase = useSupabase();
  const profile = useProfile();

  return useQuery({
    queryKey: ["orders", params.statuses, params.query],
    enabled: !!profile.data?.id,
    queryFn: async () => {
      let q = supabase.from("orders").select("*").in("status", params.statuses).order("created_at", { ascending: false }).limit(80);

      const needle = params.query.trim();
      if (needle) {
        q = q.or(`id.ilike.%${needle}%,payment_reference.ilike.%${needle}%`);
      }

      const { data, error } = await q;
      if (error) throw error;

      return (data as OrderRow[]).map((o) => ({ ...o, short_id: shortId(o.id) })) as OrderListItem[];
    },
  });
}

export function useOrderDetail(orderId: string | null) {
  const supabase = useSupabase();
  const profile = useProfile();

  return useQuery({
    queryKey: ["orders", "detail", orderId],
    enabled: !!profile.data?.id && !!orderId,
    queryFn: async () => {
      const { data: order, error: orderErr } = await supabase.from("orders").select("*").eq("id", orderId!).single();
      if (orderErr) throw orderErr;
      const { data: items, error: itemsErr } = await supabase.from("order_items").select("*").eq("order_id", orderId!).order("id", { ascending: true });
      if (itemsErr) throw itemsErr;
      const { data: events, error: eventsErr } = await supabase
        .from("order_status_events")
        .select("*")
        .eq("order_id", orderId!)
        .order("created_at", { ascending: true })
        .order("id", { ascending: true });
      if (eventsErr) throw eventsErr;
      return {
        ...(order as OrderRow),
        short_id: shortId((order as OrderRow).id),
        items: items as OrderItemRow[],
        events: (events as OrderStatusEventRow[]) ?? [],
      } as OrderDetail;
    },
  });
}

export function useUpdateOrderStatus() {
  const supabase = useSupabase();
  const profile = useProfile();
  const qc = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, status }: { id: string; status: OrderStatus }) => {
      if (!profile.data?.id) throw new Error("Not signed in");
      const { error } = await supabase.from("orders").update({ status }).eq("id", id);
      if (error) throw error;
      return { id, status };
    },
    onMutate: async ({ id, status }) => {
      if (!profile.data?.id) return;
      await qc.cancelQueries({ queryKey: ["orders"] });
      qc.setQueriesData({ queryKey: ["orders"] }, (prev) => {
        if (!Array.isArray(prev)) return prev;
        return (prev as OrderListItem[]).map((o) => (o.id === id ? { ...o, status } : o));
      });
      qc.setQueryData(["orders", "detail", id], (prev: unknown) => {
        if (!prev || typeof prev !== "object") return prev;
        return { ...(prev as OrderDetail), status };
      });
    },
    onSettled: async (_d, _e, vars) => {
      if (!profile.data?.id) return;
      await qc.invalidateQueries({ queryKey: ["orders"] });
      await qc.invalidateQueries({ queryKey: ["orders", "detail", vars?.id] });
    },
  });
}

export function useRealtimeOrders(params: { statuses: OrderStatus[]; query: string }) {
  const supabase = useSupabase();
  const profile = useProfile();
  const qc = useQueryClient();

  React.useEffect(() => {
    const channel = supabase
      .channel("orders:staff")
      .on(
        "postgres_changes",
        { event: "*", schema: "public", table: "orders" },
        () => {
          qc.invalidateQueries({ queryKey: ["orders", params.statuses, params.query] }).catch(() => {});
          qc.invalidateQueries({ queryKey: ["orders", "recent"] }).catch(() => {});
          qc.invalidateQueries({ queryKey: ["dashboard"] }).catch(() => {});
        },
      )
      .subscribe();

    return () => {
      void supabase.removeChannel(channel);
    };
  }, [supabase, qc, profile.data?.id, params.statuses, params.query]);
}

export function useOrdersRecent() {
  const supabase = useSupabase();
  const profile = useProfile();

  return useQuery({
    queryKey: ["orders", "recent"],
    enabled: !!profile.data?.id,
    queryFn: async () => {
      const { data, error } = await supabase.from("orders").select("*").order("created_at", { ascending: false }).limit(10);
      if (error) throw error;
      return (data as OrderRow[]).map((o) => ({ ...o, short_id: shortId(o.id) }));
    },
  });
}

export function useDashboardKPIs() {
  const supabase = useSupabase();
  const profile = useProfile();

  return useQuery({
    queryKey: ["dashboard", "kpis"],
    enabled: !!profile.data?.id,
    queryFn: async () => {
      const start = new Date();
      start.setHours(0, 0, 0, 0);
      const { data, error } = await supabase
        .from("orders")
        .select("status,total,created_at")
        .gte("created_at", start.toISOString());
      if (error) throw error;
      const rows = data as Pick<OrderRow, "status" | "total" | "created_at">[];
      const todayOrders = rows.length;
      const todayCancelled = rows.filter((r) => r.status === "cancelled").length;
      const todayRevenue = rows.filter((r) => r.status !== "cancelled").reduce((sum, r) => sum + Number(r.total ?? 0), 0);
      // Placeholder until prep time is stored; keep a stable UX slot.
      const avgPrepMin = 18;
      return { todayOrders, todayCancelled, todayRevenue, avgPrepMin };
    },
  });
}

export function useOrdersByHour() {
  const supabase = useSupabase();
  const profile = useProfile();

  return useQuery({
    queryKey: ["dashboard", "byHour"],
    enabled: !!profile.data?.id,
    queryFn: async () => {
      const start = new Date();
      start.setHours(0, 0, 0, 0);
      const { data, error } = await supabase.from("orders").select("created_at").gte("created_at", start.toISOString());
      if (error) throw error;
      const counts = new Array(24).fill(0);
      for (const row of data as { created_at: string }[]) {
        const d = new Date(row.created_at);
        counts[d.getHours()] += 1;
      }
      return counts.map((orders, h) => ({ hour: `${h}:00`, orders }));
    },
  });
}

export function useRevenueByDay() {
  const supabase = useSupabase();
  const profile = useProfile();

  return useQuery({
    queryKey: ["dashboard", "rev7"],
    enabled: !!profile.data?.id,
    queryFn: async () => {
      const start = new Date();
      start.setDate(start.getDate() - 6);
      start.setHours(0, 0, 0, 0);
      const { data, error } = await supabase
        .from("orders")
        .select("created_at,total,status")
        .gte("created_at", start.toISOString());
      if (error) throw error;
      const by = new Map<string, number>();
      for (const row of (data as Pick<OrderRow, "created_at" | "total" | "status">[]) ?? []) {
        if (row.status === "cancelled") continue;
        const day = new Date(row.created_at).toLocaleDateString(undefined, { weekday: "short" });
        by.set(day, (by.get(day) ?? 0) + Number(row.total ?? 0));
      }
      return Array.from(by.entries()).map(([day, revenue]) => ({ day, revenue: Number(revenue.toFixed(2)) }));
    },
  });
}

"use client";

import { useQuery } from "@tanstack/react-query";

import { useSupabase } from "@/lib/queries/supabase";
import type { Database } from "@/types/supabase";

type OrderRow = Pick<Database["public"]["Tables"]["orders"]["Row"], "id" | "created_at" | "status" | "total">;
type OrderItemRow = Pick<Database["public"]["Tables"]["order_items"]["Row"], "name_snapshot" | "qty" | "price" | "created_at">;

function startIso(days: number) {
  const d = new Date();
  d.setDate(d.getDate() - Math.max(1, days));
  return d.toISOString();
}

function dayKey(iso: string) {
  return iso.slice(0, 10);
}

export function useAnalytics(rangeDays: number) {
  const supabase = useSupabase();

  return useQuery({
    queryKey: ["analytics", { rangeDays }],
    queryFn: async () => {
      // Fetch 2 windows in one query then split:
      // - current: [start, now]
      // - previous: [prevStart, start)
      const start = startIso(rangeDays);
      const prevStart = startIso(rangeDays * 2);
      const { data, error } = await supabase
        .from("orders")
        .select("id,created_at,status,total")
        .gte("created_at", prevStart)
        .order("created_at", { ascending: true });
      if (error) throw error;
      const all = (data as OrderRow[]) ?? [];
      const orders = all.filter((o) => o.created_at >= start);
      const prevOrders = all.filter((o) => o.created_at < start);

      const kpiOrders = orders.length;
      const kpiRevenue = orders.reduce((sum, o) => sum + (o.total ?? 0), 0);
      const cancelled = orders.filter((o) => o.status === "cancelled").length;
      const delivered = orders.filter((o) => o.status === "delivered").length;
      const avgOrder = kpiOrders ? kpiRevenue / kpiOrders : 0;

      const prevKpiOrders = prevOrders.length;
      const prevKpiRevenue = prevOrders.reduce((sum, o) => sum + (o.total ?? 0), 0);
      const prevCancelled = prevOrders.filter((o) => o.status === "cancelled").length;
      const prevDelivered = prevOrders.filter((o) => o.status === "delivered").length;
      const prevAvgOrder = prevKpiOrders ? prevKpiRevenue / prevKpiOrders : 0;

      const byDayMap = new Map<string, { day: string; orders: number; revenue: number }>();
      for (const o of orders) {
        const k = dayKey(o.created_at);
        const cur = byDayMap.get(k) ?? { day: k, orders: 0, revenue: 0 };
        cur.orders += 1;
        cur.revenue += o.total ?? 0;
        byDayMap.set(k, cur);
      }
      const byDay = Array.from(byDayMap.values()).sort((a, b) => a.day.localeCompare(b.day));

      const byStatus = orders.reduce<Record<string, number>>((acc, o) => {
        acc[o.status] = (acc[o.status] ?? 0) + 1;
        return acc;
      }, {});

      const byHour = Array.from({ length: 24 }, (_, hour) => ({ hour: String(hour).padStart(2, "0"), orders: 0 }));
      for (const o of orders) {
        const hour = new Date(o.created_at).getHours();
        byHour[hour]!.orders += 1;
      }

      return {
        kpis: {
          orders: kpiOrders,
          revenue: kpiRevenue,
          avgOrder,
          cancelled,
          delivered,
          cancelRate: kpiOrders ? cancelled / kpiOrders : 0,
        },
        previous: {
          orders: prevKpiOrders,
          revenue: prevKpiRevenue,
          avgOrder: prevAvgOrder,
          cancelled: prevCancelled,
          delivered: prevDelivered,
          cancelRate: prevKpiOrders ? prevCancelled / prevKpiOrders : 0,
        },
        byDay,
        byHour,
        byStatus,
      };
    },
  });
}

export function useTopItems(rangeDays: number) {
  const supabase = useSupabase();

  return useQuery({
    queryKey: ["analytics", "top-items", { rangeDays }],
    queryFn: async () => {
      const start = startIso(rangeDays);
      const { data, error } = await supabase
        .from("order_items")
        .select("name_snapshot,qty,price,created_at")
        .gte("created_at", start)
        .order("created_at", { ascending: false })
        .limit(5000);
      if (error) throw error;
      const items = (data as OrderItemRow[]) ?? [];

      const map = new Map<string, { name: string; qty: number; revenue: number }>();
      for (const it of items) {
        const key = it.name_snapshot.trim();
        const cur = map.get(key) ?? { name: key, qty: 0, revenue: 0 };
        cur.qty += it.qty ?? 0;
        cur.revenue += (it.qty ?? 0) * (it.price ?? 0);
        map.set(key, cur);
      }

      return Array.from(map.values())
        .sort((a, b) => b.qty - a.qty)
        .slice(0, 10);
    },
  });
}

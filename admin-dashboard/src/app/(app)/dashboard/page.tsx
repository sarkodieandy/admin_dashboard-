"use client";

import { DollarSign, MessageSquare, Timer, XCircle } from "lucide-react";
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, Tooltip, CartesianGrid, LineChart, Line } from "recharts";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { useDashboardKPIs, useOrdersRecent, useOrdersByHour, useRevenueByDay } from "@/lib/queries/orders";
import { useChatsUnread } from "@/lib/queries/chats";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";

export default function DashboardPage() {
  const kpis = useDashboardKPIs();
  const recent = useOrdersRecent();
  const unread = useChatsUnread();
  const byHour = useOrdersByHour();
  const rev7 = useRevenueByDay();

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Dashboard</h1>
          <p className="text-sm text-muted-foreground">Today at a glance. Orders and chats update live.</p>
        </div>
        <Button variant="outline" onClick={() => window.location.href = "/orders"}>
          Go to Orders
        </Button>
      </div>

      <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-5">
        <KPI title="Today orders" value={kpis.data?.todayOrders} loading={kpis.isLoading} icon={<Timer className="h-4 w-4" />} />
        <KPI title="Revenue" value={kpis.data ? `₵${kpis.data.todayRevenue.toFixed(2)}` : undefined} loading={kpis.isLoading} icon={<DollarSign className="h-4 w-4" />} />
        <KPI title="Avg prep time" value={kpis.data ? `${Math.round(kpis.data.avgPrepMin)}m` : undefined} loading={kpis.isLoading} icon={<Timer className="h-4 w-4" />} />
        <KPI title="Cancellations" value={kpis.data?.todayCancelled} loading={kpis.isLoading} icon={<XCircle className="h-4 w-4" />} />
        <KPI title="Active chats" value={unread.data?.activeChats} loading={unread.isLoading} icon={<MessageSquare className="h-4 w-4" />} />
      </div>

      <div className="grid grid-cols-1 gap-4 xl:grid-cols-3">
        <Card className="xl:col-span-2">
          <CardHeader>
            <CardTitle>Orders by hour</CardTitle>
          </CardHeader>
          <CardContent className="h-[280px]">
            {byHour.isLoading ? (
              <Skeleton className="h-full w-full" />
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={byHour.data ?? []}>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} />
                  <XAxis dataKey="hour" tickLine={false} axisLine={false} />
                  <YAxis tickLine={false} axisLine={false} width={28} />
                  <Tooltip />
                  <Bar dataKey="orders" fill="hsl(var(--primary))" radius={[8, 8, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Unread chats</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            {unread.isLoading ? (
              <>
                <Skeleton className="h-10 w-full" />
                <Skeleton className="h-10 w-full" />
                <Skeleton className="h-10 w-full" />
              </>
            ) : (unread.data?.top ?? []).length === 0 ? (
              <div className="text-sm text-muted-foreground">No unread chats.</div>
            ) : (
              unread.data!.top.map((c) => (
                <a key={c.id} href={`/chats`} className="flex items-center justify-between rounded-[calc(var(--radius)-6px)] border bg-card px-3 py-2 hover:bg-accent">
                  <div className="min-w-0">
                    <div className="truncate text-sm font-semibold">Order #{c.order_short}</div>
                    <div className="truncate text-xs text-muted-foreground">{c.preview}</div>
                  </div>
                  <Badge variant="danger">{c.unread_count}</Badge>
                </a>
              ))
            )}
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 gap-4 xl:grid-cols-3">
        <Card className="xl:col-span-2">
          <CardHeader>
            <CardTitle>Revenue (7 days)</CardTitle>
          </CardHeader>
          <CardContent className="h-[280px]">
            {rev7.isLoading ? (
              <Skeleton className="h-full w-full" />
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={rev7.data ?? []}>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} />
                  <XAxis dataKey="day" tickLine={false} axisLine={false} />
                  <YAxis tickLine={false} axisLine={false} width={34} />
                  <Tooltip />
                  <Line type="monotone" dataKey="revenue" stroke="hsl(var(--primary))" strokeWidth={2.5} dot={false} />
                </LineChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Recent orders</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            {recent.isLoading ? (
              <>
                <Skeleton className="h-10 w-full" />
                <Skeleton className="h-10 w-full" />
                <Skeleton className="h-10 w-full" />
              </>
            ) : (
              (recent.data ?? []).slice(0, 6).map((o) => (
                <a key={o.id} href={`/orders?order=${o.id}`} className="flex items-center justify-between rounded-[calc(var(--radius)-6px)] border bg-card px-3 py-2 hover:bg-accent">
                  <div className="min-w-0">
                    <div className="truncate text-sm font-semibold">#{o.short_id}</div>
                    <div className="truncate text-xs text-muted-foreground">{o.status.replaceAll("_", " ")} • ₵{o.total.toFixed(2)}</div>
                  </div>
                  <Badge variant="muted">{o.status}</Badge>
                </a>
              ))
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

function KPI({ title, value, loading, icon }: { title: string; value?: React.ReactNode; loading: boolean; icon: React.ReactNode }) {
  return (
    <Card>
      <CardHeader className="flex-row items-center justify-between space-y-0">
        <CardTitle className="text-sm font-semibold text-muted-foreground">{title}</CardTitle>
        <div className="text-muted-foreground">{icon}</div>
      </CardHeader>
      <CardContent>
        {loading ? <Skeleton className="h-8 w-24" /> : <div className="text-2xl font-bold tracking-tight">{value ?? "—"}</div>}
      </CardContent>
    </Card>
  );
}

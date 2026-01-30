"use client";

import * as React from "react";
import {
  Bar,
  CartesianGrid,
  Cell,
  ComposedChart,
  Legend,
  Line,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { ArrowDownRight, ArrowUpRight, BarChart3, Minus, TrendingUp, XCircle } from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { useAnalytics, useTopItems } from "@/lib/queries/analytics";
import { formatCurrency } from "@/lib/utils/format";

export default function AnalyticsPage() {
  const [rangeDays, setRangeDays] = React.useState<7 | 30>(7);

  const analytics = useAnalytics(rangeDays);
  const top = useTopItems(rangeDays);

  const byDay = React.useMemo(() => {
    const rows = analytics.data?.byDay ?? [];
    return rows.map((r) => ({
      ...r,
      label: formatDayLabel(r.day),
      revenue: Number((r.revenue ?? 0).toFixed(2)),
    }));
  }, [analytics.data?.byDay]);

  const byHour = React.useMemo(() => {
    const rows = analytics.data?.byHour ?? [];
    return rows.map((r) => ({ ...r, label: `${r.hour}:00` }));
  }, [analytics.data?.byHour]);

  const statusRows = React.useMemo(() => {
    const map = analytics.data?.byStatus ?? {};
    return Object.entries(map)
      .map(([status, count]) => ({
        status,
        count,
        label: status.replaceAll("_", " "),
      }))
      .sort((a, b) => b.count - a.count);
  }, [analytics.data?.byStatus]);

  const maxTopQty = React.useMemo(() => {
    return Math.max(1, ...(top.data ?? []).map((t) => t.qty));
  }, [top.data]);

  const k = analytics.data?.kpis;
  const p = analytics.data?.previous;

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Analytics</h1>
          <p className="mt-1 text-sm text-muted-foreground">Operational insights (orders, revenue, and peak hours).</p>
        </div>
        <RangeToggle value={rangeDays} onChange={setRangeDays} />
      </div>

      <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-5">
        <KPI
          title="Orders"
          value={k?.orders}
          loading={analytics.isLoading}
          icon={<BarChart3 className="h-4 w-4" />}
          hint={`${rangeDays}d`}
          trend={k && p ? trend(k.orders, p.orders) : null}
        />
        <KPI
          title="Revenue"
          value={k ? formatCurrency(k.revenue) : undefined}
          loading={analytics.isLoading}
          icon={<TrendingUp className="h-4 w-4" />}
          hint={`${rangeDays}d`}
          trend={k && p ? trend(k.revenue, p.revenue) : null}
        />
        <KPI
          title="Avg order"
          value={k ? formatCurrency(k.avgOrder) : undefined}
          loading={analytics.isLoading}
          hint="AOV"
          trend={k && p ? trend(k.avgOrder, p.avgOrder) : null}
        />
        <KPI
          title="Cancelled"
          value={k?.cancelled}
          loading={analytics.isLoading}
          icon={<XCircle className="h-4 w-4" />}
          hint={k ? `${Math.round(k.cancelRate * 100)}% rate` : "—"}
          trend={k && p ? trend(k.cancelRate, p.cancelRate, { isPercent: true }) : null}
        />
        <KPI
          title="Delivered"
          value={k?.delivered}
          loading={analytics.isLoading}
          hint="Completed"
          trend={k && p ? trend(k.delivered, p.delivered) : null}
        />
      </div>

      <div className="grid grid-cols-1 gap-4 xl:grid-cols-3">
        <Card className="xl:col-span-2">
          <CardHeader className="flex-row items-center justify-between space-y-0">
            <CardTitle>Orders + revenue</CardTitle>
            <Badge variant="muted">{rangeDays}d</Badge>
          </CardHeader>
          <CardContent className="h-[340px]">
            {analytics.isLoading ? (
              <Skeleton className="h-full w-full" />
            ) : analytics.isError ? (
              <div className="text-sm text-red-600">Failed to load analytics.</div>
            ) : byDay.length === 0 ? (
              <div className="grid h-full place-items-center text-sm text-muted-foreground">No orders yet.</div>
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <ComposedChart data={byDay}>
                  <defs>
                    <linearGradient id="revGradient" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="hsl(var(--primary))" stopOpacity={0.26} />
                      <stop offset="100%" stopColor="hsl(var(--primary))" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} />
                  <XAxis dataKey="label" tickLine={false} axisLine={false} />
                  <YAxis yAxisId="left" tickLine={false} axisLine={false} width={28} allowDecimals={false} />
                  <YAxis
                    yAxisId="right"
                    orientation="right"
                    tickLine={false}
                    axisLine={false}
                    width={56}
                    tickFormatter={(v) => `₵${Number(v).toFixed(0)}`}
                  />
                  <Tooltip content={<NiceTooltip />} />
                  <Legend iconType="circle" />
                  <Bar yAxisId="left" dataKey="orders" name="Orders" fill="hsl(var(--primary))" radius={[10, 10, 0, 0]} />
                  <Line
                    yAxisId="right"
                    type="monotone"
                    dataKey="revenue"
                    name="Revenue"
                    stroke="hsl(var(--foreground))"
                    strokeWidth={2.25}
                    dot={false}
                  />
                  <Line
                    yAxisId="right"
                    type="monotone"
                    dataKey="revenue"
                    stroke="url(#revGradient)"
                    strokeWidth={8}
                    dot={false}
                    legendType="none"
                    opacity={0}
                  />
                </ComposedChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex-row items-center justify-between space-y-0">
            <CardTitle>Status split</CardTitle>
            <Badge variant="muted">{analytics.data?.kpis.orders ?? 0}</Badge>
          </CardHeader>
          <CardContent className="space-y-4">
            {analytics.isLoading ? (
              <>
                <Skeleton className="h-40 w-full" />
                <Skeleton className="h-8 w-full" />
              </>
            ) : statusRows.length === 0 ? (
              <div className="text-sm text-muted-foreground">No orders in range.</div>
            ) : (
              <>
                <div className="h-[180px]">
                  <ResponsiveContainer width="100%" height="100%">
                    <PieChart>
                      <Tooltip content={<NiceTooltip />} />
                      <Pie data={statusRows} dataKey="count" nameKey="label" innerRadius={55} outerRadius={80} paddingAngle={3}>
                        {statusRows.map((r) => (
                          <Cell key={r.status} fill={statusColor(r.status)} />
                        ))}
                      </Pie>
                    </PieChart>
                  </ResponsiveContainer>
                </div>
                <div className="space-y-2">
                  {statusRows.slice(0, 6).map((r) => (
                    <div key={r.status} className="flex items-center justify-between rounded-[calc(var(--radius)-6px)] border bg-card px-3 py-2">
                      <div className="flex items-center gap-2">
                        <span className="h-2.5 w-2.5 rounded-full" style={{ background: statusColor(r.status) }} />
                        <div className="text-sm font-semibold capitalize">{r.label}</div>
                      </div>
                      <Badge variant="muted">{r.count}</Badge>
                    </div>
                  ))}
                </div>
              </>
            )}
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 gap-4 xl:grid-cols-3">
        <Card className="xl:col-span-2">
          <CardHeader className="flex-row items-center justify-between space-y-0">
            <CardTitle>Peak hours</CardTitle>
            <Badge variant="muted">Last {rangeDays}d</Badge>
          </CardHeader>
          <CardContent className="h-[300px]">
            {analytics.isLoading ? (
              <Skeleton className="h-full w-full" />
            ) : byHour.length === 0 ? (
              <div className="grid h-full place-items-center text-sm text-muted-foreground">No hourly data yet.</div>
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <ComposedChart data={byHour}>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} />
                  <XAxis dataKey="hour" tickLine={false} axisLine={false} interval={2} />
                  <YAxis tickLine={false} axisLine={false} width={28} allowDecimals={false} />
                  <Tooltip content={<NiceTooltip />} />
                  <Bar dataKey="orders" name="Orders" fill="hsl(var(--primary))" radius={[10, 10, 0, 0]} />
                </ComposedChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex-row items-center justify-between space-y-0">
            <CardTitle>Top items</CardTitle>
            <Badge variant="muted">{rangeDays}d</Badge>
          </CardHeader>
          <CardContent className="space-y-2">
            {top.isLoading ? (
              <>
                <Skeleton className="h-10 w-full" />
                <Skeleton className="h-10 w-full" />
                <Skeleton className="h-10 w-full" />
              </>
            ) : (top.data ?? []).length === 0 ? (
              <div className="text-sm text-muted-foreground">No order items in range.</div>
            ) : (
              (top.data ?? []).map((it) => (
                <div key={it.name} className="rounded-[calc(var(--radius)-6px)] border bg-card px-3 py-2">
                  <div className="flex items-start justify-between gap-3">
                    <div className="min-w-0">
                      <div className="truncate text-sm font-semibold">{it.name}</div>
                      <div className="text-xs text-muted-foreground">{formatCurrency(it.revenue)} revenue</div>
                    </div>
                    <Badge variant="success">{it.qty}</Badge>
                  </div>
                  <div className="mt-2 h-1.5 w-full overflow-hidden rounded-full bg-muted">
                    <div
                      className="h-full rounded-full bg-primary/70"
                      style={{ width: `${Math.round((it.qty / maxTopQty) * 100)}%` }}
                    />
                  </div>
                </div>
              ))
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

function RangeToggle({ value, onChange }: { value: 7 | 30; onChange: (v: 7 | 30) => void }) {
  return (
    <div className="inline-flex items-center rounded-[calc(var(--radius)-6px)] border bg-card p-1">
      <Button size="sm" variant={value === 7 ? "default" : "ghost"} onClick={() => onChange(7)}>
        7 days
      </Button>
      <Button size="sm" variant={value === 30 ? "default" : "ghost"} onClick={() => onChange(30)}>
        30 days
      </Button>
    </div>
  );
}

function KPI({
  title,
  value,
  loading,
  icon,
  hint,
  trend,
}: {
  title: string;
  value?: React.ReactNode;
  loading: boolean;
  icon?: React.ReactNode;
  hint?: string;
  trend?: Trend | null;
}) {
  return (
    <Card>
      <CardHeader className="flex-row items-center justify-between space-y-0">
        <CardTitle className="text-sm font-semibold text-muted-foreground">{title}</CardTitle>
        <div className="text-muted-foreground">{icon}</div>
      </CardHeader>
      <CardContent>
        {loading ? <Skeleton className="h-8 w-24" /> : <div className="text-2xl font-bold tracking-tight">{value ?? "—"}</div>}
        <div className="mt-1 flex items-center justify-between gap-3">
          {hint ? <div className="text-xs text-muted-foreground">{hint}</div> : <div />}
          {trend ? <TrendPill trend={trend} /> : null}
        </div>
      </CardContent>
    </Card>
  );
}

type Trend = { kind: "up" | "down" | "flat" | "new"; label: string };

function trend(current: number, previous: number, opts?: { isPercent?: boolean }): Trend {
  const isPercent = opts?.isPercent ?? false;

  if (!Number.isFinite(current) || !Number.isFinite(previous)) return { kind: "flat", label: "—" };
  if (previous === 0) {
    if (current === 0) return { kind: "flat", label: "0%" };
    return { kind: "new", label: "New" };
  }

  const delta = current - previous;
  const pct = delta / previous;

  const prettyPct = `${pct >= 0 ? "+" : ""}${Math.round(pct * 100)}%`;
  if (Math.abs(pct) < 0.005) return { kind: "flat", label: "0%" };

  if (isPercent) {
    // Percent metrics (e.g. cancel rate) are easier to read as "pp" change.
    const pp = (current - previous) * 100;
    const ppLabel = `${pp >= 0 ? "+" : ""}${pp.toFixed(1)}pp`;
    return pp > 0 ? { kind: "up", label: ppLabel } : { kind: "down", label: ppLabel };
  }

  return delta > 0 ? { kind: "up", label: prettyPct } : { kind: "down", label: prettyPct };
}

function TrendPill({ trend }: { trend: Trend }) {
  const Icon = trend.kind === "up" ? ArrowUpRight : trend.kind === "down" ? ArrowDownRight : trend.kind === "flat" ? Minus : TrendingUp;
  const className =
    trend.kind === "up"
      ? "border-emerald-500/20 bg-emerald-500/10 text-emerald-700"
      : trend.kind === "down"
        ? "border-red-500/20 bg-red-500/10 text-red-700"
        : trend.kind === "new"
          ? "border-primary/20 bg-primary/10 text-primary"
          : "border-muted bg-muted text-muted-foreground";

  return (
    <span className={`inline-flex items-center gap-1 rounded-full border px-2 py-0.5 text-[11px] font-semibold ${className}`}>
      <Icon className="h-3.5 w-3.5" />
      <span>{trend.label}</span>
      <span className="text-muted-foreground/80">vs prev</span>
    </span>
  );
}

function NiceTooltip({ active, payload, label }: { active?: boolean; payload?: Array<{ name?: string; value?: unknown }>; label?: string }) {
  if (!active || !payload || payload.length === 0) return null;

  return (
    <div className="rounded-[calc(var(--radius)-6px)] border bg-card px-3 py-2 shadow-md">
      {label ? <div className="text-xs font-semibold text-muted-foreground">{label}</div> : null}
      <div className="mt-1 space-y-1">
        {payload
          .filter((p) => p?.value != null)
          .map((p) => (
            <div key={String(p.name)} className="flex items-center justify-between gap-6 text-sm">
              <div className="text-muted-foreground">{p.name}</div>
              <div className="font-semibold">
                {typeof p.value === "number" ? (p.name?.toLowerCase().includes("revenue") ? formatCurrency(p.value) : p.value) : String(p.value)}
              </div>
            </div>
          ))}
      </div>
    </div>
  );
}

function formatDayLabel(isoDay: string) {
  // isoDay is "YYYY-MM-DD"
  const d = new Date(`${isoDay}T00:00:00`);
  if (Number.isNaN(d.getTime())) return isoDay;
  return d.toLocaleDateString(undefined, { month: "short", day: "2-digit" });
}

function statusColor(status: string) {
  switch (status) {
    case "delivered":
      return "hsl(142 72% 45%)";
    case "en_route":
      return "hsl(221 83% 53%)";
    case "ready":
      return "hsl(270 80% 55%)";
    case "preparing":
      return "hsl(27 96% 61%)";
    case "confirmed":
      return "hsl(47 96% 53%)";
    case "placed":
      return "hsl(215 16% 47%)";
    case "cancelled":
      return "hsl(0 84% 60%)";
    default:
      return "hsl(var(--muted-foreground))";
  }
}

"use client";

import * as React from "react";
import { Download, Filter, RefreshCcw } from "lucide-react";
import { toast } from "sonner";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Sheet, SheetContent, SheetHeader, SheetTitle } from "@/components/ui/sheet";
import { Skeleton } from "@/components/ui/skeleton";
import { exportCsv } from "@/lib/utils/csv";
import { errorMessage } from "@/lib/utils/errors";
import { useOrders, useOrderDetail, useUpdateOrderStatus, useRealtimeOrders } from "@/lib/queries/orders";
import type { OrderStatus } from "@/types/supabase";

const statusTabs = [
  { key: "new", label: "New", statuses: ["placed", "confirmed"] as OrderStatus[] },
  { key: "preparing", label: "Preparing", statuses: ["preparing"] as OrderStatus[] },
  { key: "ready", label: "Ready", statuses: ["ready"] as OrderStatus[] },
  { key: "out", label: "Out for delivery", statuses: ["en_route"] as OrderStatus[] },
  { key: "completed", label: "Completed", statuses: ["delivered"] as OrderStatus[] },
  { key: "cancelled", label: "Cancelled", statuses: ["cancelled"] as OrderStatus[] },
] as const;

type StatusTabKey = (typeof statusTabs)[number]["key"];

export default function OrdersPage() {
  const [status, setStatus] = React.useState<StatusTabKey>("new");
  const [query, setQuery] = React.useState("");
  const [selected, setSelected] = React.useState<string | null>(null);

  const activeStatuses = statusTabs.find((t) => t.key === status)?.statuses ?? (["placed"] as OrderStatus[]);
  const orders = useOrders({ statuses: activeStatuses, query });
  useRealtimeOrders({ statuses: activeStatuses, query });

  const detail = useOrderDetail(selected);
  const updateStatus = useUpdateOrderStatus();

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Orders</h1>
          <p className="text-sm text-muted-foreground">Real-time operations view for kitchen + admin.</p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" onClick={() => orders.refetch()}>
            <RefreshCcw className="h-4 w-4" /> Refresh
          </Button>
          <Button
            variant="outline"
            onClick={() => exportCsv(`orders-${status}.csv`, orders.data ?? [])}
            disabled={orders.isLoading || (orders.data ?? []).length === 0}
          >
            <Download className="h-4 w-4" /> Export CSV
          </Button>
        </div>
      </div>

      <Card>
        <CardHeader className="gap-3 md:flex-row md:items-center md:justify-between">
          <CardTitle className="text-base">Pipeline</CardTitle>
          <div className="flex w-full flex-col gap-2 md:w-auto md:flex-row md:items-center">
            <div className="relative">
              <Filter className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                className="w-full pl-9 md:w-[280px]"
                placeholder="Search order id / phone…"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
              />
            </div>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <Tabs value={status} onValueChange={(v) => setStatus(v as StatusTabKey)}>
            <TabsList className="w-full justify-start overflow-auto">
              {statusTabs.map((t) => (
                <TabsTrigger key={t.key} value={t.key}>
                  {t.label}
                </TabsTrigger>
              ))}
            </TabsList>
          </Tabs>

          {orders.isLoading ? (
            <div className="space-y-2">
              <Skeleton className="h-12 w-full" />
              <Skeleton className="h-12 w-full" />
              <Skeleton className="h-12 w-full" />
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Order</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Payment</TableHead>
                  <TableHead>Total</TableHead>
                  <TableHead>Created</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {(orders.data ?? []).map((o) => (
                  <TableRow key={o.id} className="cursor-pointer" onClick={() => setSelected(o.id)}>
                    <TableCell className="font-semibold">#{o.short_id}</TableCell>
                    <TableCell className="capitalize">{o.status.replaceAll("_", " ")}</TableCell>
                    <TableCell>
                      <Badge
                        variant={
                          o.payment_status === "paid" ? "success" : o.payment_status === "failed" ? "danger" : "warning"
                        }
                      >
                        {o.payment_status}
                      </Badge>
                    </TableCell>
                    <TableCell>₵{o.total.toFixed(2)}</TableCell>
                    <TableCell className="text-muted-foreground">{new Date(o.created_at).toLocaleTimeString()}</TableCell>
                  </TableRow>
                ))}
                {(orders.data ?? []).length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={5} className="py-10 text-center text-sm text-muted-foreground">
                      No orders in this stage.
                    </TableCell>
                  </TableRow>
                ) : null}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      <Sheet open={!!selected} onOpenChange={(open) => (!open ? setSelected(null) : null)}>
        <SheetContent className="sm:max-w-xl">
          <SheetHeader>
            <SheetTitle>Order details</SheetTitle>
          </SheetHeader>
          {detail.isLoading ? (
            <div className="space-y-3">
              <Skeleton className="h-10 w-full" />
              <Skeleton className="h-40 w-full" />
              <Skeleton className="h-10 w-full" />
            </div>
          ) : detail.data ? (
            <div className="space-y-4">
              {(() => {
                const s = detail.data.status;
                const canConfirm = s === "placed";
                const canPreparing = s === "confirmed";
                const canReady = s === "preparing";
                const canEnRoute = s === "ready";
                const canDelivered = s === "en_route";
                const canCancel = s !== "delivered" && s !== "cancelled";

                return (
                  <>
              <div className="flex items-start justify-between gap-3 rounded-[--radius] border bg-card p-3">
                <div>
                  <div className="text-sm font-semibold">#{detail.data.short_id}</div>
                  <div className="text-xs text-muted-foreground">
                    {detail.data.payment_method} • {detail.data.payment_status} • {detail.data.status.replaceAll("_", " ")}
                  </div>
                </div>
                <div className="text-right">
                  <div className="text-sm font-bold">₵{detail.data.total.toFixed(2)}</div>
                  <div className="text-xs text-muted-foreground">{new Date(detail.data.created_at).toLocaleString()}</div>
                </div>
              </div>

              <Card>
                <CardHeader>
                  <CardTitle className="text-sm">Delivery address</CardTitle>
                </CardHeader>
                <CardContent className="text-sm">
                  <div className="text-muted-foreground">
                    {typeof detail.data.address_snapshot?.["address"] === "string"
                      ? (detail.data.address_snapshot["address"] as string)
                      : JSON.stringify(detail.data.address_snapshot)}
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle className="text-sm">Timeline</CardTitle>
                </CardHeader>
                <CardContent className="space-y-2">
                  {detail.data.events.map((e) => (
                    <div key={e.id} className="flex items-center justify-between text-sm">
                      <div className="font-semibold">{e.status.replaceAll("_", " ")}</div>
                      <div className="text-xs text-muted-foreground">{new Date(e.created_at).toLocaleString()}</div>
                    </div>
                  ))}
                  {detail.data.events.length === 0 ? (
                    <div className="text-sm text-muted-foreground">No status events yet.</div>
                  ) : null}
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle className="text-sm">Items</CardTitle>
                </CardHeader>
                <CardContent className="space-y-2">
                  {detail.data.items.map((it) => (
                    <div key={it.id} className="flex items-start justify-between gap-3">
                      <div className="min-w-0">
                        <div className="truncate text-sm font-semibold">{it.name_snapshot} × {it.qty}</div>
                        {it.variant_snapshot ? <div className="text-xs text-muted-foreground">{it.variant_snapshot}</div> : null}
                        {it.addons_snapshot && it.addons_snapshot.length > 0 ? (
                          <div className="text-xs text-muted-foreground">{JSON.stringify(it.addons_snapshot)}</div>
                        ) : null}
                      </div>
                      <div className="text-sm font-semibold">₵{(it.price * it.qty).toFixed(2)}</div>
                    </div>
                  ))}
                </CardContent>
              </Card>

              <div className="grid grid-cols-2 gap-2">
                <Button
                  variant="outline"
                  disabled={!canConfirm || updateStatus.isPending}
                  onClick={async () => {
                    if (!detail.data) return;
                    try {
                      await updateStatus.mutateAsync({ id: detail.data.id, status: "confirmed" });
                      toast.success("Confirmed");
                    } catch (e) {
                      console.error("[orders] update status failed", e);
                      toast.error("Failed", { description: errorMessage(e) });
                    }
                  }}
                >
                  Confirm
                </Button>
                <Button
                  variant="outline"
                  disabled={!canPreparing || updateStatus.isPending}
                  onClick={async () => {
                    if (!detail.data) return;
                    try {
                      await updateStatus.mutateAsync({ id: detail.data.id, status: "preparing" });
                      toast.success("Preparing");
                    } catch (e) {
                      console.error("[orders] update status failed", e);
                      toast.error("Failed", { description: errorMessage(e) });
                    }
                  }}
                >
                  Start preparing
                </Button>
                <Button
                  variant="outline"
                  disabled={!canReady || updateStatus.isPending}
                  onClick={async () => {
                    if (!detail.data) return;
                    try {
                      await updateStatus.mutateAsync({ id: detail.data.id, status: "ready" });
                      toast.success("Marked ready");
                    } catch (e) {
                      console.error("[orders] update status failed", e);
                      toast.error("Failed", { description: errorMessage(e) });
                    }
                  }}
                >
                  Mark ready
                </Button>
                <Button
                  variant="outline"
                  disabled={!canEnRoute || updateStatus.isPending}
                  onClick={async () => {
                    if (!detail.data) return;
                    try {
                      await updateStatus.mutateAsync({ id: detail.data.id, status: "en_route" });
                      toast.success("En route");
                    } catch (e) {
                      console.error("[orders] update status failed", e);
                      toast.error("Failed", { description: errorMessage(e) });
                    }
                  }}
                >
                  En route
                </Button>
              </div>

              <Button
                variant="outline"
                disabled={!canDelivered || updateStatus.isPending}
                onClick={async () => {
                  if (!detail.data) return;
                  try {
                    await updateStatus.mutateAsync({ id: detail.data.id, status: "delivered" });
                    toast.success("Delivered");
                  } catch (e) {
                    console.error("[orders] update status failed", e);
                    toast.error("Failed", { description: errorMessage(e) });
                  }
                }}
              >
                Delivered
              </Button>

              <Button
                variant="destructive"
                disabled={!canCancel || updateStatus.isPending}
                onClick={async () => {
                  if (!detail.data) return;
                  try {
                    await updateStatus.mutateAsync({ id: detail.data.id, status: "cancelled" });
                    toast.success("Cancelled");
                  } catch (e) {
                    console.error("[orders] update status failed", e);
                    toast.error("Failed", { description: errorMessage(e) });
                  }
                }}
              >
                Cancel order
              </Button>
                  </>
                );
              })()}
            </div>
          ) : (
            <div className="py-10 text-sm text-muted-foreground">Order not found.</div>
          )}
        </SheetContent>
      </Sheet>
    </div>
  );
}

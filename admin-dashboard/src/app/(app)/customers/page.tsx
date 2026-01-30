"use client";

import * as React from "react";
import { toast } from "sonner";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Sheet, SheetContent, SheetHeader, SheetTitle } from "@/components/ui/sheet";
import { Skeleton } from "@/components/ui/skeleton";
import { Textarea } from "@/components/ui/textarea";
import { useCustomerOrders, useCustomers, useUpdateCustomerProfile } from "@/lib/queries/customers";
import { formatCurrency, formatDateTimeShort } from "@/lib/utils/format";

export default function CustomersPage() {
  const [q, setQ] = React.useState("");
  const [debounced, setDebounced] = React.useState("");
  const [page, setPage] = React.useState(0);
  const [selectedId, setSelectedId] = React.useState<string | null>(null);

  React.useEffect(() => {
    const t = setTimeout(() => setDebounced(q), 250);
    return () => clearTimeout(t);
  }, [q]);

  React.useEffect(() => setPage(0), [debounced]);

  const customers = useCustomers({ q: debounced, page, pageSize: 25 });
  const selected = (customers.data ?? []).find((c) => c.id === selectedId) ?? null;

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Customers</h1>
          <p className="mt-1 text-sm text-muted-foreground">Search customer profiles and review order history.</p>
        </div>
      </div>

      <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div className="w-full md:max-w-md">
          <Input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search by name or phone…" />
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" disabled={page === 0} onClick={() => setPage((p) => Math.max(0, p - 1))}>
            Prev
          </Button>
          <Button variant="outline" disabled={(customers.data ?? []).length < 25} onClick={() => setPage((p) => p + 1)}>
            Next
          </Button>
        </div>
      </div>

      <Card>
        <CardHeader className="flex-row items-center justify-between space-y-0">
          <CardTitle>Customer list</CardTitle>
          <Badge variant="muted">{customers.isLoading ? "…" : `${(customers.data ?? []).length} shown`}</Badge>
        </CardHeader>
        <CardContent className="p-0">
          {customers.isLoading ? (
            <div className="space-y-2 p-4">
              <Skeleton className="h-10 w-full" />
              <Skeleton className="h-10 w-full" />
              <Skeleton className="h-10 w-full" />
            </div>
          ) : customers.isError ? (
            <div className="p-4 text-sm text-red-600">Failed to load customers.</div>
          ) : (customers.data ?? []).length === 0 ? (
            <div className="p-6 text-sm text-muted-foreground">No customers match your search.</div>
          ) : (
            <div className="divide-y">
              {(customers.data ?? []).map((c) => (
                <button
                  key={c.id}
                  type="button"
                  onClick={() => setSelectedId(c.id)}
                  className="flex w-full items-center justify-between gap-4 px-4 py-3 text-left transition-colors hover:bg-accent"
                >
                  <div className="min-w-0">
                    <div className="truncate text-sm font-semibold">{c.name ?? "Customer"}</div>
                    <div className="truncate text-xs text-muted-foreground">{c.phone ?? "No phone"}</div>
                  </div>
                  <div className="text-right">
                    <div className="text-xs text-muted-foreground">Joined</div>
                    <div className="text-sm font-semibold">{formatDateTimeShort(c.created_at)}</div>
                  </div>
                </button>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      <CustomerDrawer
        customer={selected}
        open={!!selectedId}
        onOpenChange={(v) => {
          if (!v) setSelectedId(null);
        }}
      />
    </div>
  );
}

function CustomerDrawer({
  customer,
  open,
  onOpenChange,
}: {
  customer: { id: string; name: string | null; phone: string | null; default_delivery_note: string | null; created_at: string } | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}) {
  const orders = useCustomerOrders(customer?.id ?? null);
  const update = useUpdateCustomerProfile();

  const [name, setName] = React.useState<string>("");
  const [phone, setPhone] = React.useState<string>("");
  const [note, setNote] = React.useState<string>("");

  React.useEffect(() => {
    setName(customer?.name ?? "");
    setPhone(customer?.phone ?? "");
    setNote(customer?.default_delivery_note ?? "");
  }, [customer?.id, customer?.name, customer?.phone, customer?.default_delivery_note]);

  const totals = React.useMemo(() => {
    const list = orders.data ?? [];
    const revenue = list.reduce((sum, o) => sum + (o.total ?? 0), 0);
    const delivered = list.filter((o) => o.status === "delivered").length;
    const cancelled = list.filter((o) => o.status === "cancelled").length;
    return { count: list.length, revenue, delivered, cancelled };
  }, [orders.data]);

  async function onSave() {
    if (!customer) return;
    try {
      await update.mutateAsync({
        id: customer.id,
        name: name.trim() ? name.trim() : null,
        phone: phone.trim() ? phone.trim() : null,
        default_delivery_note: note.trim() ? note.trim() : null,
      });
      toast.success("Customer updated");
    } catch (e) {
      toast.error("Update failed", { description: e instanceof Error ? e.message : String(e) });
    }
  }

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent side="right" className="w-full max-w-3xl overflow-y-auto p-0">
        <div className="p-6">
          <SheetHeader className="p-0">
            <SheetTitle className="text-xl">Customer</SheetTitle>
          </SheetHeader>

          {!customer ? (
            <div className="mt-4 text-sm text-muted-foreground">No customer selected.</div>
          ) : (
            <div className="mt-6 grid grid-cols-1 gap-4 lg:grid-cols-3">
              <Card className="lg:col-span-1">
                <CardHeader>
                  <CardTitle className="text-base">Profile</CardTitle>
                </CardHeader>
                <CardContent className="space-y-3">
                  <div className="space-y-1.5">
                    <div className="text-sm font-semibold">Name</div>
                    <Input value={name} onChange={(e) => setName(e.target.value)} />
                  </div>
                  <div className="space-y-1.5">
                    <div className="text-sm font-semibold">Phone</div>
                    <Input value={phone} onChange={(e) => setPhone(e.target.value)} />
                  </div>
                  <div className="space-y-1.5">
                    <div className="text-sm font-semibold">Default delivery note</div>
                    <Textarea value={note} onChange={(e) => setNote(e.target.value)} className="min-h-[96px]" />
                  </div>
                  <div className="flex items-center gap-2">
                    <Button onClick={onSave} disabled={update.isPending}>
                      {update.isPending ? "Saving…" : "Save"}
                    </Button>
                    <Button variant="outline" onClick={() => onOpenChange(false)}>
                      Close
                    </Button>
                  </div>
                  <div className="text-xs text-muted-foreground">
                    Joined: <span className="font-mono">{formatDateTimeShort(customer.created_at)}</span>
                  </div>
                </CardContent>
              </Card>

              <Card className="lg:col-span-2">
                <CardHeader className="flex-row items-center justify-between space-y-0">
                  <CardTitle className="text-base">Orders</CardTitle>
                  <div className="flex items-center gap-2 text-xs text-muted-foreground">
                    <span>{totals.count} total</span>
                    <span>•</span>
                    <span>{totals.delivered} delivered</span>
                    <span>•</span>
                    <span>{totals.cancelled} cancelled</span>
                    <span>•</span>
                    <span className="font-semibold text-foreground">{formatCurrency(totals.revenue)}</span>
                  </div>
                </CardHeader>
                <CardContent className="space-y-2">
                  {orders.isLoading ? (
                    <>
                      <Skeleton className="h-10 w-full" />
                      <Skeleton className="h-10 w-full" />
                      <Skeleton className="h-10 w-full" />
                    </>
                  ) : orders.isError ? (
                    <div className="text-sm text-red-600">Failed to load orders.</div>
                  ) : (orders.data ?? []).length === 0 ? (
                    <div className="text-sm text-muted-foreground">No orders yet.</div>
                  ) : (
                    <div className="divide-y rounded-[--radius] border">
                      {(orders.data ?? []).map((o) => (
                        <div key={o.id} className="flex items-center justify-between gap-3 px-3 py-2">
                          <div className="min-w-0">
                            <div className="text-sm font-semibold font-mono">#{o.id.slice(0, 8)}</div>
                            <div className="text-xs text-muted-foreground">{formatDateTimeShort(o.created_at)}</div>
                          </div>
                          <div className="flex items-center gap-2">
                            <Badge variant={o.status === "cancelled" ? "danger" : o.status === "delivered" ? "success" : "muted"}>{o.status}</Badge>
                            <div className="text-sm font-semibold">{formatCurrency(o.total)}</div>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </CardContent>
              </Card>
            </div>
          )}
        </div>
      </SheetContent>
    </Sheet>
  );
}

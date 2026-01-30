"use client";

import * as React from "react";
import { Plus, Upload } from "lucide-react";
import { toast } from "sonner";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import { Skeleton } from "@/components/ui/skeleton";
import { useCategories, useMenuItems, useUpsertMenuItem, useUpdateCategoryOrder, useUploadMenuImage } from "@/lib/queries/menu";

export default function MenuPage() {
  const categories = useCategories();
  const items = useMenuItems();
  const upsert = useUpsertMenuItem();
  const upload = useUploadMenuImage();
  const reorder = useUpdateCategoryOrder();

  const [open, setOpen] = React.useState(false);
  const [draft, setDraft] = React.useState({
    id: "",
    name: "",
    description: "",
    base_price: "0",
    category_id: "",
    is_active: true,
    is_sold_out: false,
    spice_level: "0",
    image_url: "",
  });

  function resetDraft() {
    setDraft({
      id: "",
      name: "",
      description: "",
      base_price: "0",
      category_id: categories.data?.[0]?.id ?? "",
      is_active: true,
      is_sold_out: false,
      spice_level: "0",
      image_url: "",
    });
  }

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Menu</h1>
          <p className="text-sm text-muted-foreground">Manage categories, items, availability, and images.</p>
        </div>

        <Dialog open={open} onOpenChange={(v) => { setOpen(v); if (v) resetDraft(); }}>
          <DialogTrigger asChild>
            <Button>
              <Plus className="h-4 w-4" /> New item
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Item editor</DialogTitle>
              <DialogDescription>Changes reflect in the customer app via Supabase and realtime.</DialogDescription>
            </DialogHeader>

            <div className="grid gap-3">
              <div className="grid gap-1.5">
                <div className="text-sm font-semibold">Name</div>
                <Input value={draft.name} onChange={(e) => setDraft((d) => ({ ...d, name: e.target.value }))} />
              </div>
              <div className="grid gap-1.5">
                <div className="text-sm font-semibold">Description</div>
                <Textarea value={draft.description} onChange={(e) => setDraft((d) => ({ ...d, description: e.target.value }))} />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div className="grid gap-1.5">
                  <div className="text-sm font-semibold">Price (₵)</div>
                  <Input value={draft.base_price} onChange={(e) => setDraft((d) => ({ ...d, base_price: e.target.value }))} />
                </div>
                <div className="grid gap-1.5">
                  <div className="text-sm font-semibold">Spice level (0–3)</div>
                  <Input value={draft.spice_level} onChange={(e) => setDraft((d) => ({ ...d, spice_level: e.target.value }))} />
                </div>
              </div>
              <div className="grid gap-1.5">
                <div className="text-sm font-semibold">Category</div>
                <select
                  value={draft.category_id}
                  onChange={(e) => setDraft((d) => ({ ...d, category_id: e.target.value }))}
                  className="h-10 w-full rounded-[calc(var(--radius)-4px)] border bg-card px-3 text-sm shadow-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                >
                  {(categories.data ?? []).map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.name}
                    </option>
                  ))}
                </select>
              </div>

              <div className="flex items-center justify-between rounded-[--radius] border bg-card px-3 py-2">
                <div>
                  <div className="text-sm font-semibold">Active</div>
                  <div className="text-xs text-muted-foreground">Controls visibility in the customer app.</div>
                </div>
                <Switch checked={draft.is_active} onCheckedChange={(v) => setDraft((d) => ({ ...d, is_active: v }))} />
              </div>
              <div className="flex items-center justify-between rounded-[--radius] border bg-card px-3 py-2">
                <div>
                  <div className="text-sm font-semibold">Sold out</div>
                  <div className="text-xs text-muted-foreground">One-tap kitchen availability toggle.</div>
                </div>
                <Switch checked={draft.is_sold_out} onCheckedChange={(v) => setDraft((d) => ({ ...d, is_sold_out: v }))} />
              </div>

              <div className="grid gap-1.5">
                <div className="text-sm font-semibold">Image</div>
                <div className="flex items-center gap-2">
                  <Input value={draft.image_url} onChange={(e) => setDraft((d) => ({ ...d, image_url: e.target.value }))} placeholder="https://…" />
                  <Button
                    variant="outline"
                    type="button"
                    onClick={async () => {
                      const pick = document.createElement("input");
                      pick.type = "file";
                      pick.accept = "image/*";
                      pick.onchange = async () => {
                        const file = pick.files?.[0];
                        if (!file) return;
                        try {
                          const url = await upload.mutateAsync(file);
                          setDraft((d) => ({ ...d, image_url: url }));
                          toast.success("Uploaded");
                        } catch (e) {
                          toast.error("Upload failed", { description: String(e) });
                        }
                      };
                      pick.click();
                    }}
                    disabled={upload.isPending}
                  >
                    <Upload className="h-4 w-4" />
                  </Button>
                </div>
              </div>
            </div>

            <DialogFooter>
              <Button variant="outline" onClick={() => setOpen(false)}>
                Cancel
              </Button>
              <Button
                onClick={async () => {
                  try {
                    const price = Number(draft.base_price);
                    if (!Number.isFinite(price) || price < 0) throw new Error("Invalid price");
                    const spice = Number(draft.spice_level);
                    if (!Number.isFinite(spice) || spice < 0 || spice > 3) throw new Error("Invalid spice level");
                    await upsert.mutateAsync({
                      name: draft.name.trim(),
                      description: draft.description.trim() || null,
                      base_price: price,
                      category_id: draft.category_id || null,
                      spice_level: spice,
                      is_active: draft.is_active,
                      is_sold_out: draft.is_sold_out,
                      image_url: draft.image_url.trim() || null,
                    });
                    toast.success("Saved");
                    setOpen(false);
                  } catch (e) {
                    toast.error("Save failed", { description: String(e) });
                  }
                }}
                disabled={upsert.isPending}
              >
                Save
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </div>

      <div className="grid gap-4 xl:grid-cols-[360px_1fr]">
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Categories</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            {categories.isLoading ? (
              <>
                <Skeleton className="h-10 w-full" />
                <Skeleton className="h-10 w-full" />
              </>
            ) : (
              (categories.data ?? []).map((c, idx) => (
                <div key={c.id} className="flex items-center justify-between rounded-[calc(var(--radius)-6px)] border bg-card px-3 py-2">
                  <div className="min-w-0">
                    <div className="truncate text-sm font-semibold">{c.name}</div>
                    <div className="text-xs text-muted-foreground">Order: {c.sort_order}</div>
                  </div>
                  <div className="flex items-center gap-2">
                    <Button
                      variant="outline"
                      size="sm"
                      disabled={idx === 0}
                      onClick={() => reorder.mutate({ id: c.id, direction: "up" })}
                    >
                      ↑
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      disabled={idx === (categories.data?.length ?? 0) - 1}
                      onClick={() => reorder.mutate({ id: c.id, direction: "down" })}
                    >
                      ↓
                    </Button>
                  </div>
                </div>
              ))
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">Items</CardTitle>
          </CardHeader>
          <CardContent>
            {items.isLoading ? (
              <div className="space-y-2">
                <Skeleton className="h-12 w-full" />
                <Skeleton className="h-12 w-full" />
                <Skeleton className="h-12 w-full" />
              </div>
            ) : (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Item</TableHead>
                    <TableHead>Category</TableHead>
                    <TableHead>Price</TableHead>
                    <TableHead>Status</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {(items.data ?? []).map((it) => (
                    <TableRow key={it.id}>
                      <TableCell className="flex items-center gap-3">
                        {/* eslint-disable-next-line @next/next/no-img-element */}
                        <img
                          src={it.image_url ?? "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=128&q=80"}
                          alt=""
                          className="h-10 w-10 rounded-[12px] border object-cover"
                        />
                        <div className="min-w-0">
                          <div className="truncate font-semibold">{it.name}</div>
                          <div className="truncate text-xs text-muted-foreground">
                            Spice: {it.spice_level} • {it.is_active ? "Active" : "Hidden"}
                          </div>
                        </div>
                      </TableCell>
                      <TableCell className="text-muted-foreground">{it.category_name ?? "—"}</TableCell>
                      <TableCell>₵{it.base_price.toFixed(2)}</TableCell>
                      <TableCell>
                        <Badge variant={!it.is_active ? "muted" : it.is_sold_out ? "danger" : "success"}>
                          {!it.is_active ? "Hidden" : it.is_sold_out ? "Sold out" : "Available"}
                        </Badge>
                      </TableCell>
                    </TableRow>
                  ))}
                  {(items.data ?? []).length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={4} className="py-10 text-center text-sm text-muted-foreground">
                        No items.
                      </TableCell>
                    </TableRow>
                  ) : null}
                </TableBody>
              </Table>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

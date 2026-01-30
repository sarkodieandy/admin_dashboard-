"use client";

import * as React from "react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { useDeliverySettings, useUpsertDeliverySettings } from "@/lib/queries/settings";

export default function DeliverySettingsPage() {
  const settings = useDeliverySettings();
  const upsert = useUpsertDeliverySettings();

  const [draft, setDraft] = React.useState({
    base_fee: "",
    free_radius_km: "",
    per_km_fee_after_free_radius: "",
    minimum_order_amount: "",
    max_delivery_distance_km: "",
  });

  React.useEffect(() => {
    if (!settings.data) return;
    setDraft({
      base_fee: settings.data.base_fee.toString(),
      free_radius_km: settings.data.free_radius_km.toString(),
      per_km_fee_after_free_radius: settings.data.per_km_fee_after_free_radius.toString(),
      minimum_order_amount: settings.data.minimum_order_amount.toString(),
      max_delivery_distance_km: settings.data.max_delivery_distance_km.toString(),
    });
  }, [settings.data]);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Delivery settings</h1>
        <p className="text-sm text-muted-foreground">Fees, distance limits, and minimum order rules.</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Fee rules</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {settings.isLoading ? (
            <Skeleton className="h-40 w-full" />
          ) : (
            <div className="grid gap-3 md:grid-cols-2">
              <Field label="Base fee" value={draft.base_fee} onChange={(v) => setDraft((d) => ({ ...d, base_fee: v }))} />
              <Field label="Free radius (km)" value={draft.free_radius_km} onChange={(v) => setDraft((d) => ({ ...d, free_radius_km: v }))} />
              <Field label="Per km fee after free radius" value={draft.per_km_fee_after_free_radius} onChange={(v) => setDraft((d) => ({ ...d, per_km_fee_after_free_radius: v }))} />
              <Field label="Minimum order amount" value={draft.minimum_order_amount} onChange={(v) => setDraft((d) => ({ ...d, minimum_order_amount: v }))} />
              <Field label="Max delivery distance (km)" value={draft.max_delivery_distance_km} onChange={(v) => setDraft((d) => ({ ...d, max_delivery_distance_km: v }))} />
            </div>
          )}

          <div className="flex justify-end">
            <Button
              onClick={async () => {
                try {
                  await upsert.mutateAsync({
                    base_fee: Number(draft.base_fee),
                    free_radius_km: Number(draft.free_radius_km),
                    per_km_fee_after_free_radius: Number(draft.per_km_fee_after_free_radius),
                    minimum_order_amount: Number(draft.minimum_order_amount),
                    max_delivery_distance_km: Number(draft.max_delivery_distance_km),
                  });
                  toast.success("Saved");
                } catch (e) {
                  toast.error("Save failed", { description: String(e) });
                }
              }}
              disabled={upsert.isPending}
            >
              Save
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

function Field({ label, value, onChange }: { label: string; value: string; onChange: (v: string) => void }) {
  return (
    <div className="space-y-1.5">
      <div className="text-sm font-semibold">{label}</div>
      <Input value={value} onChange={(e) => onChange(e.target.value)} />
    </div>
  );
}


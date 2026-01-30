"use client";

import * as React from "react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { useDeliverySettings, useUpsertDeliverySettings } from "@/lib/queries/settings";
import { errorMessage } from "@/lib/utils/errors";
import { formatCurrency, formatDateTimeShort } from "@/lib/utils/format";

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

  const missingTable = (settings.error as { code?: string } | null)?.code === "42P01";

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Delivery settings</h1>
        <p className="text-sm text-muted-foreground">Fees, distance limits, and minimum order rules.</p>
      </div>

      <Card>
        <CardHeader className="flex-row items-center justify-between space-y-0">
          <CardTitle className="text-base">Fee rules</CardTitle>
          {settings.data?.updated_at ? <Badge variant="muted">Updated {formatDateTimeShort(settings.data.updated_at)}</Badge> : null}
        </CardHeader>
        <CardContent className="space-y-4">
          {settings.isLoading ? (
            <Skeleton className="h-40 w-full" />
          ) : missingTable ? (
            <div className="space-y-2 rounded-[--radius] border bg-card p-4">
              <div className="text-sm font-semibold">Missing table: delivery_settings</div>
              <div className="text-sm text-muted-foreground">
                Apply the Supabase migration <code className="font-mono">supabase/migrations/0017_delivery_settings.sql</code> (or run <code className="font-mono">supabase db push</code>), then refresh.
              </div>
            </div>
          ) : settings.isError ? (
            <div className="rounded-[--radius] border bg-card p-4 text-sm text-red-600">
              Failed to load settings: {errorMessage(settings.error)}
            </div>
          ) : (
            <div className="grid gap-3 md:grid-cols-2">
              <Field label="Base fee" hint={formatCurrency(Number(draft.base_fee || 0))} value={draft.base_fee} onChange={(v) => setDraft((d) => ({ ...d, base_fee: v }))} />
              <Field label="Free radius (km)" hint="0 = no free radius" value={draft.free_radius_km} onChange={(v) => setDraft((d) => ({ ...d, free_radius_km: v }))} />
              <Field label="Per km fee after free radius" hint={formatCurrency(Number(draft.per_km_fee_after_free_radius || 0))} value={draft.per_km_fee_after_free_radius} onChange={(v) => setDraft((d) => ({ ...d, per_km_fee_after_free_radius: v }))} />
              <Field label="Minimum order amount" hint={formatCurrency(Number(draft.minimum_order_amount || 0))} value={draft.minimum_order_amount} onChange={(v) => setDraft((d) => ({ ...d, minimum_order_amount: v }))} />
              <Field label="Max delivery distance (km)" hint="0 = no limit" value={draft.max_delivery_distance_km} onChange={(v) => setDraft((d) => ({ ...d, max_delivery_distance_km: v }))} />
            </div>
          )}

          <div className="flex justify-end">
            <Button
              onClick={async () => {
                try {
                  const values = {
                    base_fee: Number(draft.base_fee),
                    free_radius_km: Number(draft.free_radius_km),
                    per_km_fee_after_free_radius: Number(draft.per_km_fee_after_free_radius),
                    minimum_order_amount: Number(draft.minimum_order_amount),
                    max_delivery_distance_km: Number(draft.max_delivery_distance_km),
                  };

                  for (const [k, v] of Object.entries(values)) {
                    if (!Number.isFinite(v) || v < 0) throw new Error(`Invalid value for ${k}`);
                  }

                  const res = await upsert.mutateAsync(values);
                  toast.success(res.created ? "Saved (created)" : "Saved");
                } catch (e) {
                  toast.error("Save failed", { description: errorMessage(e) });
                }
              }}
              disabled={upsert.isPending || settings.isLoading || missingTable}
            >
              Save
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

function Field({
  label,
  hint,
  value,
  onChange,
}: {
  label: string;
  hint?: string;
  value: string;
  onChange: (v: string) => void;
}) {
  return (
    <div className="space-y-1.5">
      <div className="flex items-center justify-between gap-3">
        <div className="text-sm font-semibold">{label}</div>
        {hint ? <div className="text-xs text-muted-foreground">{hint}</div> : null}
      </div>
      <Input inputMode="decimal" value={value} onChange={(e) => onChange(e.target.value)} placeholder="0" />
    </div>
  );
}

"use client";

import * as React from "react";
import { toast } from "sonner";

import { createSupabaseBrowserClient } from "@/lib/supabase/client";
import { useProfile } from "@/lib/queries/profile";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";

const allowed = new Set(["admin", "staff"]);

export function RoleGuard({ children }: { children: React.ReactNode }) {
  const profile = useProfile();

  if (profile.isLoading) {
    return (
      <div className="p-6">
        <Skeleton className="h-16 w-full" />
      </div>
    );
  }

  const role = profile.data?.role;
  if (!role || !allowed.has(role)) {
    return (
      <div className="grid min-h-[60vh] place-items-center p-6">
        <Card className="max-w-md">
          <CardHeader>
            <CardTitle>Access restricted</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="text-sm text-muted-foreground">
              Your account doesn’t have staff access. Ask an admin to set your <code className="font-mono">profiles.role</code> to{" "}
              <code className="font-mono">admin</code> or <code className="font-mono">staff</code>.
            </div>
            <Button
              variant="outline"
              onClick={async () => {
                const supabase = createSupabaseBrowserClient();
                await supabase.auth.signOut();
                toast.message("Signed out");
                window.location.href = "/login";
              }}
            >
              Back to login
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  return <>{children}</>;
}

"use client";

import * as React from "react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { createSupabaseBrowserClient } from "@/lib/supabase/client";

export default function LoginPage() {
  const [redirectTo, setRedirectTo] = React.useState("/dashboard");

  React.useEffect(() => {
    const p = new URLSearchParams(window.location.search);
    const raw = p.get("redirect") ?? "/dashboard";
    const normalized = raw.startsWith("/app/") ? raw.replace(/^\/app/, "") : raw;
    const safe = normalized.startsWith("/") ? normalized : "/dashboard";
    setRedirectTo(safe === "/login" || safe === "/" ? "/dashboard" : safe);
  }, []);

  const [email, setEmail] = React.useState("");
  const [password, setPassword] = React.useState("");
  const [loading, setLoading] = React.useState(false);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    try {
      const supabase = createSupabaseBrowserClient();
      const { error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) throw error;
      console.debug("[login] signed in; redirecting", { redirectTo });
      toast.success("Welcome back");
      window.location.href = redirectTo;
    } catch (err) {
      console.error("[login] sign in failed", err);
      toast.error("Sign in failed", { description: err instanceof Error ? err.message : String(err) });
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="grid min-h-screen place-items-center p-6">
      <div className="w-full max-w-md">
        <div className="mb-6 flex items-center justify-center gap-2">
          <div className="grid h-10 w-10 place-items-center rounded-[14px] bg-primary text-primary-foreground shadow-sm">
            <span className="text-sm font-black tracking-tight">FL</span>
          </div>
          <div className="leading-tight">
            <div className="text-base font-bold">Finger Licking Restaurant</div>
            <div className="text-sm text-muted-foreground">Admin Dashboard</div>
          </div>
        </div>

        <Card>
          <CardHeader>
            <CardTitle>Sign in</CardTitle>
            <CardDescription>Use your staff account (owner/admin/staff).</CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={onSubmit} className="space-y-3">
              <div className="space-y-1.5">
                <div className="text-sm font-semibold">Email</div>
                <Input value={email} onChange={(e) => setEmail(e.target.value)} autoComplete="email" />
              </div>
              <div className="space-y-1.5">
                <div className="text-sm font-semibold">Password</div>
                <Input type="password" value={password} onChange={(e) => setPassword(e.target.value)} autoComplete="current-password" />
              </div>
              <Button className="w-full" disabled={loading}>
                {loading ? "Signing in…" : "Sign in"}
              </Button>
              <div className="text-xs text-muted-foreground">
                Tip: create staff users in Supabase Auth, then add a matching row in <code className="font-mono">profiles</code>.
              </div>
            </form>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

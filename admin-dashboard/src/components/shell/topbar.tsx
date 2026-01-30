"use client";

import * as React from "react";
import { Bell, Search } from "lucide-react";
import { toast } from "sonner";

import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { useProfile } from "@/lib/queries/profile";
import { useNotifications } from "@/lib/queries/notifications";
import { createSupabaseBrowserClient } from "@/lib/supabase/client";

export function Topbar() {
  const profile = useProfile();
  const notifications = useNotifications();

  const me = profile.data;
  const unread = (notifications.data ?? []).filter((n) => !n.is_read).length;

  async function signOut() {
    const supabase = createSupabaseBrowserClient();
    await supabase.auth.signOut();
    toast.success("Signed out");
    window.location.href = "/login";
  }

  return (
    <header className="sticky top-0 z-20 flex items-center justify-between gap-3 border-b bg-background/75 px-4 py-3 backdrop-blur lg:px-6">
      <div className="flex items-center gap-3">
        <div className="lg:hidden">
          {/* Sidebar button is rendered inside <Sidebar /> */}
        </div>

        <div className="hidden md:flex md:w-[380px]">
          <div className="relative w-full">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input className="pl-9" placeholder="Search orders, customers, chats…" />
          </div>
        </div>
      </div>

      <div className="flex items-center gap-2">
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="outline" size="icon" className="relative">
              <Bell className="h-4 w-4" />
              {unread > 0 ? (
                <span className="absolute right-2 top-2 h-2 w-2 rounded-full bg-red-500" />
              ) : null}
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="w-[340px]">
            <DropdownMenuLabel>Notifications</DropdownMenuLabel>
            <DropdownMenuSeparator />
            {(notifications.data ?? []).slice(0, 6).map((n) => (
              <DropdownMenuItem key={n.id} className="flex flex-col items-start gap-0.5">
                <div className="text-sm font-semibold">{n.title}</div>
                {n.body ? <div className="text-xs text-muted-foreground">{n.body}</div> : null}
              </DropdownMenuItem>
            ))}
            {notifications.isLoading ? (
              <div className="px-3 py-2 text-sm text-muted-foreground">Loading…</div>
            ) : null}
            {!notifications.isLoading && (notifications.data ?? []).length === 0 ? (
              <div className="px-3 py-2 text-sm text-muted-foreground">All clear.</div>
            ) : null}
          </DropdownMenuContent>
        </DropdownMenu>

        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="outline" className="h-10 gap-2 px-3">
              <Avatar className="h-7 w-7">
                <AvatarFallback>
                  {(me?.name ?? "Staff").slice(0, 1).toUpperCase()}
                </AvatarFallback>
              </Avatar>
              <div className="hidden text-left leading-tight sm:block">
                <div className="text-sm font-semibold">{me?.name ?? "Staff"}</div>
                <div className="text-xs text-muted-foreground">{me?.role ?? "staff"}</div>
              </div>
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="w-56">
            <DropdownMenuLabel>Account</DropdownMenuLabel>
            <DropdownMenuSeparator />
            <DropdownMenuItem onSelect={(e) => e.preventDefault()} onClick={() => toast.message("Settings coming soon")}>
              Settings
            </DropdownMenuItem>
            <DropdownMenuSeparator />
            <DropdownMenuItem className="text-red-600" onSelect={(e) => e.preventDefault()} onClick={signOut}>
              Sign out
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>
    </header>
  );
}

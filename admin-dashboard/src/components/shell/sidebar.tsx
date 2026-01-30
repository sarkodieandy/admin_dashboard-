"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import * as React from "react";
import { ChevronLeft, Menu } from "lucide-react";

import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { Sheet, SheetContent, SheetTrigger } from "@/components/ui/sheet";
import { navItems } from "@/components/shell/nav";

function SidebarInner({ collapsed, onToggle }: { collapsed: boolean; onToggle: () => void }) {
  const pathname = usePathname();

  return (
    <div className="flex h-full flex-col gap-4 p-4">
      <div className="flex items-center justify-between">
        <div className={cn("flex items-center gap-2", collapsed && "justify-center")}>
          <div className="grid h-9 w-9 place-items-center rounded-[12px] bg-primary text-primary-foreground shadow-sm">
            <span className="text-sm font-black tracking-tight">FL</span>
          </div>
          {!collapsed && (
            <div className="leading-tight">
              <div className="text-sm font-bold">Finger Licking</div>
              <div className="text-xs text-muted-foreground">Restaurant Admin</div>
            </div>
          )}
        </div>
        <Button variant="ghost" size="icon" className={cn("hidden lg:inline-flex", collapsed && "rotate-180")} onClick={onToggle}>
          <ChevronLeft className="h-4 w-4" />
        </Button>
      </div>

      <nav className="flex-1 space-y-1">
        {navItems.map((item) => {
          const active = pathname === item.href;
          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                "group flex items-center gap-3 rounded-[calc(var(--radius)-6px)] px-3 py-2 text-sm font-semibold text-muted-foreground transition-all hover:-translate-y-[1px] hover:bg-accent hover:text-foreground",
                active && "border bg-card text-foreground shadow-sm",
                collapsed && "justify-center px-2",
              )}
              data-active={active ? "true" : "false"}
            >
              <span
                className={cn(
                  "grid h-8 w-8 place-items-center rounded-[12px] transition-all",
                  active ? "bg-secondary" : "bg-transparent group-hover:bg-secondary/60",
                )}
              >
                <span className={cn(active && "motion-safe:animate-[navPop_.24s_ease-out]")}>{item.icon}</span>
              </span>
              {!collapsed && <span className="truncate">{item.label}</span>}
            </Link>
          );
        })}
      </nav>

      <div className={cn("text-xs text-muted-foreground", collapsed && "text-center")}>
        {!collapsed ? "v1 • Live via Supabase" : "v1"}
      </div>
    </div>
  );
}

export function Sidebar() {
  const [collapsed, setCollapsed] = React.useState(false);

  return (
    <>
      <aside className={cn("hidden h-screen border-r bg-card/80 backdrop-blur lg:sticky lg:top-0 lg:block", collapsed ? "w-[76px]" : "w-[280px]")}>
        <SidebarInner collapsed={collapsed} onToggle={() => setCollapsed((v) => !v)} />
      </aside>
    </>
  );
}

export function MobileSidebar() {
  return (
    <Sheet>
      <SheetTrigger asChild>
        <Button variant="outline" size="icon" className="h-10 w-10">
          <Menu className="h-4 w-4" />
        </Button>
      </SheetTrigger>
      <SheetContent side="left" className="p-0 sm:max-w-sm">
        <SidebarInner collapsed={false} onToggle={() => {}} />
      </SheetContent>
    </Sheet>
  );
}

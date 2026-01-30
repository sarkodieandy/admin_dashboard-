import * as React from "react";

import { Sidebar } from "@/components/shell/sidebar";
import { Topbar } from "@/components/shell/topbar";
import { RoleGuard } from "@/components/shell/role-guard";
import { PageTransition } from "@/components/shell/page-transition";

export function AppShell({ children }: { children: React.ReactNode }) {
  return (
    <div className="relative min-h-screen bg-background">
      <div
        aria-hidden="true"
        className="pointer-events-none fixed inset-0 -z-10 opacity-100"
      >
        <div
          className="absolute inset-0 bg-cover bg-center opacity-[0.52] saturate-150 contrast-125 brightness-110"
          style={{
            backgroundImage:
              "url(https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=2400&q=60)",
          }}
        />
        <div className="absolute inset-0 bg-gradient-to-b from-background/0 via-background/15 to-background/35" />
      </div>

      <div className="mx-auto flex min-h-screen w-full max-w-[1600px]">
        <Sidebar />
        <div className="flex min-w-0 flex-1 flex-col">
          <Topbar />
          <main className="min-w-0 flex-1 px-4 py-6 lg:px-6">
            <RoleGuard>
              <PageTransition>{children}</PageTransition>
            </RoleGuard>
          </main>
        </div>
      </div>
    </div>
  );
}

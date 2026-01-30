"use client";

import { ArrowRight, SlidersHorizontal, Users } from "lucide-react";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";

export default function SettingsPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Settings</h1>
        <p className="text-sm text-muted-foreground">Configure how the restaurant operates.</p>
      </div>

      <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
        <Card className="transition-colors hover:bg-accent">
          <CardHeader className="flex-row items-center justify-between space-y-0">
            <CardTitle className="text-base">Delivery settings</CardTitle>
            <SlidersHorizontal className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent className="flex items-center justify-between gap-4">
            <div className="text-sm text-muted-foreground">Fees, minimum order, and distance limits.</div>
            <Button variant="outline" onClick={() => (window.location.href = "/delivery-settings")}>
              Open <ArrowRight className="h-4 w-4" />
            </Button>
          </CardContent>
        </Card>

        <Card className="transition-colors hover:bg-accent">
          <CardHeader className="flex-row items-center justify-between space-y-0">
            <CardTitle className="text-base">Staff & roles</CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent className="flex items-center justify-between gap-4">
            <div className="text-sm text-muted-foreground">Manage admins/staff access.</div>
            <Button variant="outline" onClick={() => (window.location.href = "/staff")}>
              Open <ArrowRight className="h-4 w-4" />
            </Button>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}


"use client";

import * as React from "react";
import { toast } from "sonner";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { useMarkAllNotificationsRead, useMarkNotificationRead, useNotifications, useRealtimeNotifications } from "@/lib/queries/notifications";
import { formatDateTimeShort } from "@/lib/utils/format";

export default function NotificationsPage() {
  const notifications = useNotifications();
  useRealtimeNotifications();
  const markRead = useMarkNotificationRead();
  const markAll = useMarkAllNotificationsRead();

  const [filter, setFilter] = React.useState<"all" | "unread">("unread");

  const rows = (notifications.data ?? []).filter((n) => (filter === "unread" ? !n.is_read : true));
  const unreadCount = (notifications.data ?? []).filter((n) => !n.is_read).length;
  const source = (notifications.data ?? [])[0]?.source ?? "staff_notifications";

  async function onMarkAll() {
    try {
      await markAll.mutateAsync({ source });
      toast.success("All notifications marked as read");
    } catch (e) {
      toast.error("Failed", { description: e instanceof Error ? e.message : String(e) });
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Notifications</h1>
          <p className="mt-1 text-sm text-muted-foreground">Staff alerts for new orders and customer messages.</p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant={filter === "unread" ? "default" : "outline"} onClick={() => setFilter("unread")}>
            Unread <Badge className="ml-2" variant="muted">{unreadCount}</Badge>
          </Button>
          <Button variant={filter === "all" ? "default" : "outline"} onClick={() => setFilter("all")}>
            All
          </Button>
          <Button variant="outline" onClick={onMarkAll} disabled={unreadCount === 0 || markAll.isPending}>
            {markAll.isPending ? "Marking…" : "Mark all read"}
          </Button>
        </div>
      </div>

      <Card>
        <CardHeader className="flex-row items-center justify-between space-y-0">
          <CardTitle>Inbox</CardTitle>
          <Badge variant="muted">{notifications.isLoading ? "…" : `${rows.length}`}</Badge>
        </CardHeader>
        <CardContent className="p-0">
          {notifications.isLoading ? (
            <div className="space-y-2 p-4">
              <Skeleton className="h-12 w-full" />
              <Skeleton className="h-12 w-full" />
              <Skeleton className="h-12 w-full" />
            </div>
          ) : notifications.isError ? (
            <div className="p-4 text-sm text-red-600">Failed to load notifications.</div>
          ) : rows.length === 0 ? (
            <div className="p-6 text-sm text-muted-foreground">No notifications.</div>
          ) : (
            <div className="divide-y">
              {rows.map((n) => (
                <div key={n.id} className="flex items-start justify-between gap-4 px-4 py-3">
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2">
                      <div className="truncate text-sm font-semibold">{n.title}</div>
                      {!n.is_read ? <Badge variant="danger">New</Badge> : null}
                    </div>
                    {n.body ? <div className="mt-0.5 text-sm text-muted-foreground">{n.body}</div> : null}
                    <div className="mt-1 text-xs text-muted-foreground">{formatDateTimeShort(n.created_at)}</div>
                    {n.entity_type === "order" && n.entity_id ? (
                      <div className="mt-2">
                        <Button variant="outline" size="sm" onClick={() => (window.location.href = `/orders?order=${n.entity_id}`)}>
                          Open order
                        </Button>
                      </div>
                    ) : null}
                  </div>
                  <div className="flex items-center gap-2">
                    {!n.is_read ? (
                      <Button
                        variant="outline"
                        size="sm"
                        disabled={markRead.isPending}
                        onClick={async () => {
                          try {
                            await markRead.mutateAsync({ id: n.id, source: n.source });
                          } catch (e) {
                            toast.error("Failed", { description: e instanceof Error ? e.message : String(e) });
                          }
                        }}
                      >
                        Mark read
                      </Button>
                    ) : null}
                  </div>
                </div>
              ))}
            </div>
          )}
          {source === "notifications" ? (
            <div className="border-t px-4 py-3 text-xs text-muted-foreground">
              Showing <code className="font-mono">public.notifications</code>. For staff alerts, run <code className="font-mono">admin-dashboard/db/compat/003_staff_notifications.sql</code>.
            </div>
          ) : null}
        </CardContent>
      </Card>
    </div>
  );
}

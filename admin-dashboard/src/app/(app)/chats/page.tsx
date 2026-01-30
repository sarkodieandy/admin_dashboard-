"use client";

import * as React from "react";
import { Search } from "lucide-react";
import { toast } from "sonner";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Skeleton } from "@/components/ui/skeleton";
import { useProfile } from "@/lib/queries/profile";
import { useChats, useChatMessages, useRealtimeChatMessages, useSendChatMessage } from "@/lib/queries/chats";

export default function ChatsPage() {
  const [selected, setSelected] = React.useState<string | null>(null);
  const [search, setSearch] = React.useState("");

  const profile = useProfile();
  const chats = useChats({ search });
  const messages = useChatMessages(selected);
  useRealtimeChatMessages(selected);

  const send = useSendChatMessage();

  const [text, setText] = React.useState("");

  const active = (chats.data ?? []).find((c) => c.id === selected) ?? null;

  return (
    <div className="grid gap-4 xl:grid-cols-[360px_1fr_360px]">
      <Card className="p-3">
        <div className="mb-3 flex items-center gap-2">
          <div className="relative w-full">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input className="pl-9" placeholder="Search order id / customer…" value={search} onChange={(e) => setSearch(e.target.value)} />
          </div>
        </div>

        <div className="space-y-1">
          {chats.isLoading ? (
            <>
              <Skeleton className="h-14 w-full" />
              <Skeleton className="h-14 w-full" />
              <Skeleton className="h-14 w-full" />
            </>
          ) : (chats.data ?? []).length === 0 ? (
            <div className="py-8 text-center text-sm text-muted-foreground">No chats.</div>
          ) : (
            (chats.data ?? []).map((c) => (
              <button
                key={c.id}
                onClick={() => setSelected(c.id)}
                className={"flex w-full items-center justify-between rounded-[calc(var(--radius)-6px)] border px-3 py-2 text-left transition-colors hover:bg-accent " + (selected === c.id ? "bg-accent" : "bg-card")}
              >
                <div className="min-w-0">
                  <div className="truncate text-sm font-semibold">
                    Order #{c.order_short}
                    {c.order_status ? (
                      <span className="text-xs text-muted-foreground"> • {c.order_status.replaceAll("_", " ")}</span>
                    ) : null}
                  </div>
                  <div className="truncate text-xs text-muted-foreground">{c.preview}</div>
                </div>
                <div className="flex flex-col items-end gap-1">
                  {c.unread_count > 0 ? <Badge variant="danger">{c.unread_count}</Badge> : null}
                </div>
              </button>
            ))
          )}
        </div>
      </Card>

      <Card className="flex min-h-[640px] flex-col">
        <div className="flex items-center justify-between border-b px-4 py-3">
          <div>
            <div className="text-sm font-semibold">Chat</div>
            <div className="text-xs text-muted-foreground">{active ? `Order #${active.order_short}` : "Select a chat"}</div>
          </div>
          {active?.order_status ? <Badge variant="muted">{active.order_status}</Badge> : null}
        </div>

        <div className="flex-1 overflow-auto p-4">
          {!active ? (
            <div className="grid h-full place-items-center text-sm text-muted-foreground">Pick a chat to start.</div>
          ) : messages.isLoading ? (
            <div className="space-y-2">
              <Skeleton className="h-10 w-2/3" />
              <Skeleton className="h-10 w-1/2" />
              <Skeleton className="h-10 w-2/3" />
            </div>
          ) : (
            <div className="space-y-2">
              {(messages.data ?? []).map((m) => (
                <div key={m.id} className={"flex " + (m.sender_id && m.sender_id === profile.data?.id ? "justify-end" : "justify-start")}>
                  <div
                    className={
                      "max-w-[70%] rounded-[--radius] border px-3 py-2 text-sm shadow-sm " +
                      (m.sender_id && m.sender_id === profile.data?.id ? "bg-primary text-primary-foreground border-transparent" : "bg-card")
                    }
                  >
                    <div className="mb-1 text-[11px] font-semibold opacity-80">
                      {m.sender_id && m.sender_id === profile.data?.id ? "Staff" : "Customer"}
                    </div>
                    <div className="whitespace-pre-wrap">{m.message}</div>
                  </div>
                </div>
              ))}
              {(messages.data ?? []).length === 0 ? <div className="text-sm text-muted-foreground">No messages yet.</div> : null}
            </div>
          )}
        </div>

        <div className="border-t p-3">
          <form
            className="flex items-end gap-2"
            onSubmit={async (e) => {
              e.preventDefault();
              if (!active) return;
              const trimmed = text.trim();
              if (!trimmed) return;
              setText("");
              try {
                await send.mutateAsync({ chatId: active.id, message: trimmed });
              } catch (e) {
                setText(trimmed);
                toast.error("Send failed", { description: String(e) });
              }
            }}
          >
            <Textarea value={text} onChange={(e) => setText(e.target.value)} placeholder="Type a message…" className="min-h-[44px]" />
            <Button type="submit" disabled={!active || send.isPending}>
              Send
            </Button>
          </form>
        </div>
      </Card>

      <Card className="p-4">
        <div className="text-sm font-semibold">Order context</div>
        <div className="mt-1 text-xs text-muted-foreground">Quick tools for staff during a chat.</div>
        <div className="mt-4 space-y-3">
          {active ? (
            <>
              <div className="rounded-[--radius] border bg-card p-3">
                <div className="text-xs text-muted-foreground">Order</div>
                <div className="text-sm font-semibold">#{active.order_short}</div>
              </div>
              <Button variant="outline" onClick={() => window.location.href = `/orders?order=${active.order_id}`}>
                Open order
              </Button>

              <Button variant="outline" onClick={() => toast.message("Call action (integrate tel: link)")} disabled>
                Call customer (soon)
              </Button>
            </>
          ) : (
            <div className="text-sm text-muted-foreground">Select a chat to see order details.</div>
          )}
        </div>
      </Card>
    </div>
  );
}

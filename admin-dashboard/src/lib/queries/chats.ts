"use client";

import * as React from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { useProfile } from "@/lib/queries/profile";
import { useSupabase } from "@/lib/queries/supabase";
import type { Database } from "@/types/supabase";

type ChatRow = Database["public"]["Tables"]["chats"]["Row"];
type ChatMessageRow = Database["public"]["Tables"]["chat_messages"]["Row"];
type OrderRow = Database["public"]["Tables"]["orders"]["Row"];

function shortId(id: string) {
  return id.replaceAll("-", "").slice(0, 8).toUpperCase();
}

export type ChatListItem = ChatRow & {
  order_short: string;
  order_status: OrderRow["status"] | null;
  preview: string;
  last_at: string | null;
  unread_count: number;
};

export function useChats({ search }: { search: string }) {
  const supabase = useSupabase();
  const profile = useProfile();

  return useQuery({
    queryKey: ["chats", "list", search],
    enabled: !!profile.data?.id,
    queryFn: async () => {
      const { data: auth } = await supabase.auth.getUser();
      const meId = auth.user?.id ?? null;

      const { data, error } = await supabase
        .from("chats")
        .select("id,order_id,created_at,orders(status)")
        .order("created_at", { ascending: false })
        .limit(80);
      if (error) throw error;

      const chats = (data as (ChatRow & { orders: Pick<OrderRow, "status"> | null })[]) ?? [];
      const ids = chats.map((c) => c.id);

      const msgs: ChatMessageRow[] = [];
      if (ids.length > 0) {
        const { data: msgData, error: msgErr } = await supabase
          .from("chat_messages")
          .select("id,chat_id,sender_id,message,created_at")
          .in("chat_id", ids)
          .order("created_at", { ascending: false })
          .limit(400);
        if (msgErr) throw msgErr;
        msgs.push(...(((msgData as ChatMessageRow[]) ?? []) as ChatMessageRow[]));
      }

      const lastByChat = new Map<string, ChatMessageRow>();
      for (const m of msgs) {
        if (!lastByChat.has(m.chat_id)) lastByChat.set(m.chat_id, m);
      }

      const needle = search.trim().toLowerCase();

      const list: ChatListItem[] = chats.map((c) => {
        const last = lastByChat.get(c.id);
        const preview = (last?.message ?? "").trim() || "No messages yet";
        const unread_count = meId && last && last.sender_id && last.sender_id !== meId ? 1 : 0;
        return {
          id: c.id,
          order_id: c.order_id,
          created_at: c.created_at,
          order_short: shortId(c.order_id),
          order_status: c.orders?.status ?? null,
          preview,
          last_at: last?.created_at ?? null,
          unread_count,
        };
      });

      const filtered = !needle
        ? list
        : list.filter((c) => c.order_id.toLowerCase().includes(needle) || c.order_short.toLowerCase().includes(needle) || c.preview.toLowerCase().includes(needle));

      return filtered.sort((a, b) => (b.unread_count - a.unread_count) || (new Date(b.last_at ?? b.created_at).getTime() - new Date(a.last_at ?? a.created_at).getTime()));
    },
  });
}

export function useChatMessages(chatId: string | null) {
  const supabase = useSupabase();
  const profile = useProfile();

  return useQuery({
    queryKey: ["chats", "messages", chatId],
    enabled: !!profile.data?.id && !!chatId,
    queryFn: async () => {
      const { data, error } = await supabase
        .from("chat_messages")
        .select("*")
        .eq("chat_id", chatId!)
        .order("created_at", { ascending: true })
        .order("id", { ascending: true })
        .limit(300);
      if (error) throw error;
      return (data as ChatMessageRow[]) ?? [];
    },
  });
}

export function useRealtimeChatMessages(chatId: string | null) {
  const supabase = useSupabase();
  const qc = useQueryClient();
  const profile = useProfile();

  React.useEffect(() => {
    if (!profile.data?.id) return;

    const channel = supabase
      .channel(`chat_messages:${chatId ?? "none"}`)
      .on("postgres_changes", { event: "INSERT", schema: "public", table: "chat_messages" }, () => {
        qc.invalidateQueries({ queryKey: ["chats", "list"] }).catch(() => {});
        if (chatId) qc.invalidateQueries({ queryKey: ["chats", "messages", chatId] }).catch(() => {});
      })
      .subscribe();

    return () => void supabase.removeChannel(channel);
  }, [supabase, qc, profile.data?.id, chatId]);
}

export function useSendChatMessage() {
  const supabase = useSupabase();
  const profile = useProfile();
  const qc = useQueryClient();

  return useMutation({
    mutationFn: async ({ chatId, message }: { chatId: string; message: string }) => {
      if (!profile.data?.id) throw new Error("Not signed in");
      const { data: auth } = await supabase.auth.getUser();
      const user = auth.user;
      if (!user) throw new Error("Not signed in");
      const { error } = await supabase.from("chat_messages").insert({ chat_id: chatId, sender_id: user.id, message });
      if (error) throw error;
      return true;
    },
    onSuccess: async (_d, vars) => {
      await qc.invalidateQueries({ queryKey: ["chats", "list"] });
      await qc.invalidateQueries({ queryKey: ["chats", "messages", vars.chatId] });
    },
  });
}

export function useChatsUnread() {
  const chats = useChats({ search: "" });
  const activeChats = (chats.data ?? []).length;
  const top = (chats.data ?? []).filter((c) => c.unread_count > 0).slice(0, 5);
  return { ...chats, data: chats.data ? { activeChats, top } : undefined };
}

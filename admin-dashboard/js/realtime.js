import { getClient } from "./auth.js";
import { fetchRecentOrders, fetchConversations, fetchNotifications } from "./api.js";

const supabase = getClient();

export function subscribeRealtime({ onOrders, onMessages, onNotifications }) {
  const channel = supabase
    .channel("admin-realtime")
    .on("postgres_changes", { event: "*", schema: "public", table: "orders" }, async () => {
      onOrders && onOrders();
      await fetchRecentOrders();
    })
    .on("postgres_changes", { event: "INSERT", schema: "public", table: "messages" }, async (payload) => {
      onMessages && onMessages(payload);
    })
    .on("postgres_changes", { event: "INSERT", schema: "public", table: "staff_notifications" }, async () => {
      onNotifications && onNotifications();
      await fetchNotifications();
    });
  channel.subscribe((status) => console.log("[realtime]", status));
  return () => supabase.removeChannel(channel);
}

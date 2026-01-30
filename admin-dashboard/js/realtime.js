import { getClient } from "./auth.js";
import { fetchNotifications } from "./api.js";

const supabase = getClient();

/**
 * Subscribe to orders + chat_messages + staff_notifications realtime streams.
 */
export function subscribeRealtime({ onOrders, onMessages, onNotifications }) {
  const channel = supabase
    .channel("admin-realtime")
    .on("postgres_changes", { event: "*", schema: "public", table: "orders" }, (payload) => {
      onOrders && onOrders(payload);
    })
    .on("postgres_changes", { event: "INSERT", schema: "public", table: "chat_messages" }, (payload) => {
      onMessages && onMessages(payload);
    })
    .on("postgres_changes", { event: "INSERT", schema: "public", table: "staff_notifications" }, async () => {
      onNotifications && onNotifications();
      await fetchNotifications();
    });
  channel.subscribe((status) => console.log("[realtime]", status));
  return () => supabase.removeChannel(channel);
}

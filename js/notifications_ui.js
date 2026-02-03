import { fetchNotifications, markAllNotificationsRead, markNotificationRead } from "./api.js";
import { fmtDateTime } from "./utils.js";

export function mountNotifications({ supabase, buttonId = "notifBtn" } = {}) {
  const btn = document.getElementById(buttonId);
  if (!btn) return () => {};

  btn.classList.add("icon-btn");
  btn.innerHTML = `
    <span aria-hidden="true">🔔</span>
    <span class="notif-badge" id="notifBadge" style="display:none;"></span>
  `;

  const wrap = document.createElement("div");
  wrap.className = "notif-wrap";
  btn.insertAdjacentElement("afterend", wrap);
  wrap.appendChild(btn);

  const pop = document.createElement("div");
  pop.className = "notif-popover";
  pop.innerHTML = `
    <div class="notif-head">
      <div>
        <div class="font-semibold">Notifications</div>
        <div class="muted text-sm">New orders & customer messages</div>
      </div>
      <button class="btn ghost" id="notifMarkAll">Mark all read</button>
    </div>
    <div class="notif-list" id="notifList"></div>
  `;
  wrap.appendChild(pop);

  const badge = btn.querySelector("#notifBadge");
  const list = pop.querySelector("#notifList");
  const markAll = pop.querySelector("#notifMarkAll");

  let open = false;
  let lastUnread = 0;

  function setOpen(next) {
    open = next;
    pop.classList.toggle("show", open);
  }

  btn.addEventListener("click", (e) => {
    e.preventDefault();
    e.stopPropagation();
    setOpen(!open);
    if (open) refresh();
  });

  document.addEventListener("click", (e) => {
    if (!open) return;
    if (wrap.contains(e.target) || btn.contains(e.target)) return;
    setOpen(false);
  });

  markAll.addEventListener("click", async () => {
    const { error } = await markAllNotificationsRead();
    if (!error) await refresh();
  });

  async function refresh() {
    list.innerHTML = `<div class="skeleton" style="height:42px; border-radius:12px;"></div>`;
    const { data, error } = await fetchNotifications();
    if (error) {
      list.innerHTML = `<div class="muted">Error: ${error.message}</div>`;
      return;
    }
    const items = data || [];
    const unread = items.filter((n) => !n.is_read).length;
    const unreadIncreased = unread > lastUnread;
    lastUnread = unread;
    if (badge) {
      badge.style.display = unread ? "grid" : "none";
      badge.textContent = unread > 99 ? "99+" : String(unread);
      if (unreadIncreased) {
        badge.classList.remove("pulse");
        // Force reflow to restart animation.
        // eslint-disable-next-line no-unused-expressions
        badge.offsetWidth;
        badge.classList.add("pulse");
        btn.classList.remove("pulse");
        btn.offsetWidth;
        btn.classList.add("pulse");
      }
    }
    if (!items.length) {
      list.innerHTML = `<div class="muted" style="padding:10px 12px;">No notifications yet.</div>`;
      return;
    }
    list.innerHTML = items
      .map((n) => {
        const icon = n.type === "new_order" ? "🧾" : n.type === "customer_message" ? "💬" : "🔔";
        const href = n.entity_id ? `orders.html#${n.entity_id}` : "orders.html";
        return `
          <a class="notif-item ${n.is_read ? "" : "unread"}" data-id="${n.id}" href="${href}">
            <div class="notif-icon">${icon}</div>
            <div class="notif-body">
              <div class="notif-title">${escapeHtml(n.title || "Notification")}</div>
              <div class="muted text-sm">${escapeHtml(n.body || "")}</div>
              <div class="muted text-xs" style="margin-top:4px;">${fmtDateTime(n.created_at)}</div>
            </div>
          </a>
        `;
      })
      .join("");

    list.querySelectorAll(".notif-item").forEach((a) =>
      a.addEventListener("click", async () => {
        const id = a.dataset.id;
        if (id) await markNotificationRead(id);
      })
    );
  }

  // Realtime refresh
  const channel = supabase
    ?.channel
    ?.("notif-ui")
    ?.on("postgres_changes", { event: "INSERT", schema: "public", table: "staff_notifications" }, refresh);
  channel?.subscribe?.();

  refresh();

  return () => {
    if (channel && supabase?.removeChannel) supabase.removeChannel(channel);
  };
}

function escapeHtml(s) {
  return String(s ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function el(tag, attrs = {}, children = []) {
  const node = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs)) {
    if (k === "class") node.className = v;
    else if (k === "html") node.innerHTML = v;
    else node.setAttribute(k, String(v));
  }
  for (const c of children) node.append(c);
  return node;
}

export async function renderNotifications({ supabase, toast }) {
  const root = el("div", { class: "grid" });

  const card = el("div", { class: "card" }, [
    el("div", { class: "card-header" }, [
      el("div", { class: "card-title", html: "Notifications" }),
      el("div", { class: "card-sub", html: "Staff notifications." }),
    ]),
  ]);
  const content = el("div", { class: "card-content" });
  card.append(content);
  root.append(card);

  const { data: auth } = await supabase.auth.getUser();
  if (!auth.user) throw new Error("Not signed in");

  const { data, error } = await supabase
    .from("staff_notifications")
    .select("id,title,body,is_read,created_at")
    .eq("recipient_id", auth.user.id)
    .order("created_at", { ascending: false })
    .limit(60);
  if (error) throw error;

  const markAll = el("button", { class: "btn", type: "button" }, [document.createTextNode("Mark all read")]);
  markAll.addEventListener("click", async () => {
    markAll.setAttribute("disabled", "true");
    try {
      const { error: uErr } = await supabase
        .from("staff_notifications")
        .update({ is_read: true })
        .eq("recipient_id", auth.user.id)
        .eq("is_read", false);
      if (uErr) throw uErr;
      toast.success("Updated", "Marked all as read. Refresh to see changes.");
    } catch (e) {
      toast.error("Update failed", e?.message || String(e));
    } finally {
      markAll.removeAttribute("disabled");
    }
  });

  content.append(el("div", { style: "display:flex; justify-content:flex-end; margin-bottom:12px" }, [markAll]));

  const list = el("div", { class: "grid" });
  for (const n of data || []) {
    const row = el("div", { class: "kpi-card" }, [
      el("div", { class: "p", html: `<span style="font-weight:900">${escapeHtml(n.title || "Notification")}</span> ${n.is_read ? "" : "<span style='color:var(--primary)'>• new</span>"}` }),
      el("div", { class: "hint", html: escapeHtml(n.body || "") }),
    ]);
    list.append(row);
  }
  if ((data || []).length === 0) list.append(el("div", { class: "p", html: "No notifications yet." }));

  content.append(list);
  return root;
}

function escapeHtml(s) {
  return String(s).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#039;" }[c] || c));
}


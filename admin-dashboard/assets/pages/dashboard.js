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

function money(n) {
  const x = Number(n || 0);
  return `GH₵ ${x.toFixed(2)}`;
}

export async function renderDashboard({ supabase }) {
  const root = el("div", { class: "grid", style: "gap:14px" });

  const header = el("div", { class: "card" }, [
    el("div", { class: "card-content" }, [
      el("div", { class: "card-title", html: "Overview" }),
      el("div", { class: "card-sub", html: "Quick stats from recent orders." }),
    ]),
  ]);

  root.append(header);

  // recent orders + basic KPIs
  const { data: orders, error } = await supabase
    .from("orders")
    .select("id,total,status,created_at")
    .order("created_at", { ascending: false })
    .limit(80);
  if (error) throw error;

  const totalRevenue = (orders || []).reduce((sum, o) => sum + Number(o.total || 0), 0);
  const totalOrders = (orders || []).length;
  const pending = (orders || []).filter((o) => o.status !== "delivered" && o.status !== "cancelled").length;
  const delivered = (orders || []).filter((o) => o.status === "delivered").length;

  const kpis = el("div", { class: "card" }, [
    el("div", { class: "card-content" }, [
      el("div", { class: "grid kpi" }, [
        el("div", { class: "kpi-card" }, [
          el("div", { class: "kpi-top" }, [el("div", { class: "kpi-ico", html: "💰" })]),
          el("div", { class: "kpi-label", html: "Revenue (recent)" }),
          el("div", { class: "kpi-value", html: money(totalRevenue) }),
        ]),
        el("div", { class: "kpi-card" }, [
          el("div", { class: "kpi-top" }, [el("div", { class: "kpi-ico", html: "🧾" })]),
          el("div", { class: "kpi-label", html: "Orders (recent)" }),
          el("div", { class: "kpi-value", html: String(totalOrders) }),
        ]),
        el("div", { class: "kpi-card" }, [
          el("div", { class: "kpi-top" }, [el("div", { class: "kpi-ico", html: "⏳" })]),
          el("div", { class: "kpi-label", html: "In progress" }),
          el("div", { class: "kpi-value", html: String(pending) }),
        ]),
        el("div", { class: "kpi-card" }, [
          el("div", { class: "kpi-top" }, [el("div", { class: "kpi-ico", html: "✅" })]),
          el("div", { class: "kpi-label", html: "Delivered" }),
          el("div", { class: "kpi-value", html: String(delivered) }),
        ]),
      ]),
    ]),
  ]);
  root.append(kpis);

  const list = el("div", { class: "card" }, [
    el("div", { class: "card-header" }, [
      el("div", { class: "card-title", html: "Latest orders" }),
      el("div", { class: "card-sub", html: "Most recent 10 orders." }),
    ]),
  ]);
  const body = el("div", { class: "card-body" });
  const rows = el("div", { class: "grid" });

  const latest = (orders || []).slice(0, 10);
  for (const o of latest) {
    rows.append(
      el("div", { class: "kpi-card", style: "display:flex; align-items:center; justify-content:space-between; gap:10px" }, [
        el("div", { class: "p", html: `<span style="font-weight:900">#${String(o.id).slice(0, 8)}</span> <span style="color:rgba(231,237,245,.72)">• ${o.status}</span>` }),
        el("div", { class: "p", html: money(o.total) }),
      ]),
    );
  }
  if (latest.length === 0) {
    rows.append(el("div", { class: "p", html: "No orders yet." }));
  }

  body.append(rows);
  list.append(body);
  root.append(list);

  return root;
}


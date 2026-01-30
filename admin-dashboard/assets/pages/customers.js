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

export async function renderCustomers({ supabase }) {
  const root = el("div", { class: "grid" });

  const card = el("div", { class: "card" }, [
    el("div", { class: "card-header" }, [
      el("div", { class: "card-title", html: "Customers" }),
      el("div", { class: "card-sub", html: "Latest customers (profiles)." }),
    ]),
  ]);
  const content = el("div", { class: "card-content" });
  card.append(content);
  root.append(card);

  const { data, error } = await supabase
    .from("profiles")
    .select("id,name,phone,role,created_at")
    .order("created_at", { ascending: false })
    .limit(60);
  if (error) throw error;

  const list = el("div", { class: "grid" });
  for (const p of data || []) {
    list.append(
      el("div", { class: "kpi-card", style: "display:flex; align-items:center; justify-content:space-between; gap:10px" }, [
        el("div", { class: "p", html: `<span style="font-weight:900">${p.name || "Unnamed"}</span><div style="color:rgba(231,237,245,.72); font-size:12px">${p.phone || "—"} • ${p.role}</div>` }),
        el("div", { class: "p", html: String(p.id).slice(0, 8) }),
      ]),
    );
  }
  if ((data || []).length === 0) list.append(el("div", { class: "p", html: "No profiles found." }));
  content.append(list);

  return root;
}


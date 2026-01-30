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

const statuses = ["placed", "confirmed", "preparing", "ready", "en_route", "delivered", "cancelled"];

export async function renderOrders({ supabase, toast }) {
  const root = el("div", { class: "grid" });

  const card = el("div", { class: "card" }, [
    el("div", { class: "card-header" }, [
      el("div", { class: "card-title", html: "Orders" }),
      el("div", { class: "card-sub", html: "View and update recent orders." }),
    ]),
  ]);
  const content = el("div", { class: "card-content" });
  card.append(content);
  root.append(card);

  const { data, error } = await supabase
    .from("orders")
    .select("id,user_id,status,total,created_at")
    .order("created_at", { ascending: false })
    .limit(80);
  if (error) throw error;

  const list = el("div", { class: "grid" });
  for (const o of data || []) {
    const select = el("select", { class: "input", style: "max-width: 200px" });
    for (const s of statuses) {
      const opt = document.createElement("option");
      opt.value = s;
      opt.textContent = s.replace(/_/g, " ");
      if (s === o.status) opt.selected = true;
      select.append(opt);
    }

    const save = el("button", { class: "btn", type: "button" }, [document.createTextNode("Update")]);
    save.addEventListener("click", async () => {
      save.setAttribute("disabled", "true");
      try {
        const status = select.value;
        const { error: uErr } = await supabase.from("orders").update({ status }).eq("id", o.id);
        if (uErr) throw uErr;
        toast.success("Updated", `Order #${String(o.id).slice(0, 8)} → ${status}`);
      } catch (e) {
        toast.error("Update failed", e?.message || String(e));
      } finally {
        save.removeAttribute("disabled");
      }
    });

    list.append(
      el("div", { class: "kpi-card", style: "display:flex; flex-wrap:wrap; align-items:center; justify-content:space-between; gap:10px" }, [
        el("div", { class: "p", html: `<span style="font-weight:900">#${String(o.id).slice(0, 8)}</span> <span style="color:rgba(231,237,245,.72)">• ${o.status}</span>` }),
        el("div", { style: "display:flex; align-items:center; gap:8px" }, [
          el("div", { class: "p", html: money(o.total) }),
          select,
          save,
        ]),
      ]),
    );
  }
  if ((data || []).length === 0) list.append(el("div", { class: "p", html: "No orders yet." }));

  content.append(list);
  return root;
}


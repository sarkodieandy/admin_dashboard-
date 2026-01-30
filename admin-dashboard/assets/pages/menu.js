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

export async function renderMenu({ supabase, toast }) {
  const root = el("div", { class: "grid" });

  const card = el("div", { class: "card" }, [
    el("div", { class: "card-header" }, [
      el("div", { class: "card-title", html: "Menu" }),
      el("div", { class: "card-sub", html: "Manage categories and menu items (basic)." }),
    ]),
  ]);
  const content = el("div", { class: "card-content" });
  card.append(content);
  root.append(card);

  const [{ data: categories, error: cErr }, { data: items, error: iErr }] = await Promise.all([
    supabase.from("categories").select("*").order("sort_order", { ascending: true }),
    supabase.from("menu_items").select("*").order("created_at", { ascending: false }).limit(80),
  ]);
  if (cErr) throw cErr;
  if (iErr) throw iErr;

  const cats = el("div", { class: "kpi-card" }, [
    el("div", { class: "p", html: "<span style='font-weight:900'>Categories</span>" }),
    el(
      "div",
      { class: "grid", style: "grid-template-columns: repeat(2, minmax(0,1fr)); gap:10px; margin-top:10px" },
      (categories || []).map((c) =>
        el("div", { class: "kpi-card", style: "padding:12px" }, [
          el("div", { class: "p", html: `<span style="font-weight:900">${c.name}</span><div style="color:rgba(231,237,245,.72); font-size:12px">sort: ${c.sort_order}</div>` }),
        ]),
      ),
    ),
  ]);

  const list = el("div", { class: "grid" });
  for (const it of items || []) {
    list.append(
      el("div", { class: "kpi-card", style: "display:flex; align-items:center; justify-content:space-between; gap:10px" }, [
        el("div", { class: "p", html: `<span style="font-weight:900">${it.name}</span><div style="color:rgba(231,237,245,.72); font-size:12px">${it.category_id || "No category"} • ${it.is_sold_out ? "Sold out" : "Available"}</div>` }),
        el("div", { class: "p", html: money(it.base_price) }),
      ]),
    );
  }
  if ((items || []).length === 0) list.append(el("div", { class: "p", html: "No menu items yet." }));

  content.append(el("div", { class: "grid", style: "gap:12px" }, [cats, el("div", { class: "kpi-card" }, [el("div", { class: "p", html: "<span style='font-weight:900'>Items</span>" }), list])])));

  // Add item (basic)
  const addCard = el("div", { class: "card" }, [
    el("div", { class: "card-header" }, [
      el("div", { class: "card-title", html: "Add menu item" }),
      el("div", { class: "card-sub", html: "Uploads an image to Supabase Storage (menu-images) and inserts menu_items row." }),
    ]),
  ]);
  const addBody = el("div", { class: "card-content" });
  addCard.append(addBody);

  const name = el("input", { class: "input", placeholder: "Name" });
  const price = el("input", { class: "input", inputmode: "decimal", placeholder: "Base price" });
  const cat = el("select", { class: "input" });
  const none = document.createElement("option");
  none.value = "";
  none.textContent = "No category";
  cat.append(none);
  for (const c of categories || []) {
    const opt = document.createElement("option");
    opt.value = c.id;
    opt.textContent = c.name;
    cat.append(opt);
  }
  const file = el("input", { class: "input", type: "file", accept: "image/*" });
  const save = el("button", { class: "btn btn-primary", type: "button" }, [document.createTextNode("Create")]);

  addBody.append(
    el("div", { class: "grid", style: "grid-template-columns: repeat(2, minmax(0,1fr)); gap:12px" }, [
      el("label", { class: "field" }, [el("div", { class: "field-label", html: "Name" }), name]),
      el("label", { class: "field" }, [el("div", { class: "field-label", html: "Base price" }), price]),
      el("label", { class: "field" }, [el("div", { class: "field-label", html: "Category" }), cat]),
      el("label", { class: "field" }, [el("div", { class: "field-label", html: "Image" }), file]),
    ]),
  );
  addBody.append(el("div", { style: "display:flex; justify-content:flex-end; margin-top:12px" }, [save]));

  save.addEventListener("click", async () => {
    save.setAttribute("disabled", "true");
    try {
      const n = name.value.trim();
      const p = Number(price.value || 0);
      if (!n) throw new Error("Name is required");
      if (!Number.isFinite(p) || p <= 0) throw new Error("Price must be > 0");

      const f = file.files?.[0] || null;
      let imageUrl = null;
      if (f) {
        const ext = (f.name.split(".").pop() || "jpg").toLowerCase();
        const path = `${Date.now()}-${Math.random().toString(16).slice(2)}.${ext}`;
        const up = await supabase.storage.from("menu-images").upload(path, f, { upsert: false });
        if (up.error) throw up.error;
        const pub = supabase.storage.from("menu-images").getPublicUrl(path);
        imageUrl = pub.data.publicUrl;
      }

      const payload = {
        name: n,
        base_price: p,
        category_id: cat.value || null,
        image_url: imageUrl,
        is_active: true,
        is_sold_out: false,
        spice_level: 0,
      };
      const ins = await supabase.from("menu_items").insert(payload);
      if (ins.error) throw ins.error;

      toast.success("Created", "Menu item added. Refresh to see it.");
      name.value = "";
      price.value = "";
      cat.value = "";
      file.value = "";
    } catch (e) {
      toast.error("Create failed", e?.message || String(e));
    } finally {
      save.removeAttribute("disabled");
    }
  });

  root.append(addCard);
  return root;
}


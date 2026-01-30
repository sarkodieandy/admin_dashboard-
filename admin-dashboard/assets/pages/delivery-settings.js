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

function field(label, value = "") {
  const input = el("input", { class: "input", inputmode: "decimal", value: String(value ?? ""), placeholder: "0" });
  return { input, node: el("label", { class: "field" }, [el("div", { class: "field-label", html: label }), input]) };
}

export async function renderDeliverySettings({ supabase, toast }) {
  const root = el("div", { class: "grid" });

  const card = el("div", { class: "card" }, [
    el("div", { class: "card-header" }, [
      el("div", { class: "card-title", html: "Delivery settings" }),
      el("div", { class: "card-sub", html: "Fees, distance limits, and minimum order rules." }),
    ]),
  ]);

  const content = el("div", { class: "card-content" });
  card.append(content);
  root.append(card);

  const { data, error } = await supabase
    .from("delivery_settings")
    .select("*")
    .order("updated_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  if (error) throw error;

  const base = field("Base fee", data?.base_fee ?? "");
  const freeRadius = field("Free radius (km)", data?.free_radius_km ?? "");
  const perKm = field("Per km fee after free radius", data?.per_km_fee_after_free_radius ?? "");
  const minOrder = field("Minimum order amount", data?.minimum_order_amount ?? "");
  const maxDist = field("Max delivery distance (km)", data?.max_delivery_distance_km ?? "");

  content.append(
    el("div", { class: "grid", style: "grid-template-columns: repeat(2, minmax(0,1fr)); gap:12px" }, [
      base.node,
      freeRadius.node,
      perKm.node,
      minOrder.node,
      maxDist.node,
    ]),
  );

  const saveBtn = el("button", { class: "btn btn-primary", type: "button" }, [document.createTextNode("Save")]);
  const row = el("div", { style: "display:flex; justify-content:flex-end; margin-top:12px" }, [saveBtn]);
  content.append(row);

  saveBtn.addEventListener("click", async () => {
    saveBtn.setAttribute("disabled", "true");
    try {
      const values = {
        base_fee: Number(base.input.value || 0),
        free_radius_km: Number(freeRadius.input.value || 0),
        per_km_fee_after_free_radius: Number(perKm.input.value || 0),
        minimum_order_amount: Number(minOrder.input.value || 0),
        max_delivery_distance_km: Number(maxDist.input.value || 0),
      };

      for (const [k, v] of Object.entries(values)) {
        if (!Number.isFinite(v) || v < 0) throw new Error(`Invalid value for ${k}`);
      }

      // singleton semantics: update first row if exists else insert
      const existing = await supabase.from("delivery_settings").select("id").limit(1).maybeSingle();
      if (existing.error) throw existing.error;

      if (existing.data?.id) {
        const { error: uErr } = await supabase.from("delivery_settings").update(values).eq("id", existing.data.id);
        if (uErr) throw uErr;
        toast.success("Saved", "Updated delivery settings.");
      } else {
        const { error: iErr } = await supabase.from("delivery_settings").insert(values);
        if (iErr) throw iErr;
        toast.success("Saved", "Created delivery settings.");
      }
    } catch (e) {
      toast.error("Save failed", e?.message || String(e));
    } finally {
      saveBtn.removeAttribute("disabled");
    }
  });

  return root;
}


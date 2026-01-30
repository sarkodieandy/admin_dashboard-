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

export async function renderStaff({ supabase, toast }) {
  const root = el("div", { class: "grid" });

  const { data: auth } = await supabase.auth.getUser();
  if (!auth.user) throw new Error("Not signed in");
  const { data: me, error: meErr } = await supabase.from("profiles").select("role").eq("id", auth.user.id).maybeSingle();
  if (meErr) throw meErr;
  const isAdmin = me?.role === "admin";

  const card = el("div", { class: "card" }, [
    el("div", { class: "card-header" }, [
      el("div", { class: "card-title", html: "Staff allowlist" }),
      el("div", { class: "card-sub", html: "Add multiple admin/staff emails. Only admins can edit." }),
    ]),
  ]);
  const content = el("div", { class: "card-content" });
  card.append(content);
  root.append(card);

  const { data, error } = await supabase.from("staff_allowlist").select("email,role,created_at").order("created_at", { ascending: false });
  if (error) throw error;

  if (!isAdmin) {
    content.append(el("div", { class: "kpi-card" }, [el("div", { class: "p", html: "You can view staff, but only an admin can add/remove." })]));
  }

  const email = el("input", { class: "input", placeholder: "staff@example.com", type: "email" });
  const role = el("select", { class: "input" });
  for (const r of ["staff", "admin"]) {
    const opt = document.createElement("option");
    opt.value = r;
    opt.textContent = r;
    role.append(opt);
  }
  const add = el("button", { class: "btn btn-primary", type: "button" }, [document.createTextNode("Add / Update")]);
  add.disabled = !isAdmin;

  add.addEventListener("click", async () => {
    const e = email.value.trim().toLowerCase();
    if (!e.includes("@")) return toast.error("Invalid email");
    add.setAttribute("disabled", "true");
    try {
      const { error: upErr } = await supabase.from("staff_allowlist").upsert({ email: e, role: role.value }, { onConflict: "email" });
      if (upErr) throw upErr;
      toast.success("Saved", "Allowlist updated.");
      email.value = "";
    } catch (err) {
      toast.error("Save failed", err?.message || String(err));
    } finally {
      if (isAdmin) add.removeAttribute("disabled");
    }
  });

  content.append(
    el("div", { class: "grid", style: "grid-template-columns: 1fr 180px auto; gap:10px; align-items:end" }, [
      el("label", { class: "field" }, [el("div", { class: "field-label", html: "Email" }), email]),
      el("label", { class: "field" }, [el("div", { class: "field-label", html: "Role" }), role]),
      add,
    ]),
  );

  const list = el("div", { class: "grid", style: "margin-top:12px" });
  for (const row of data || []) {
    const rm = el("button", { class: "btn", type: "button" }, [document.createTextNode("Remove")]);
    rm.disabled = !isAdmin;
    rm.addEventListener("click", async () => {
      rm.setAttribute("disabled", "true");
      try {
        const { error: dErr } = await supabase.from("staff_allowlist").delete().eq("email", row.email);
        if (dErr) throw dErr;
        toast.success("Removed", "Refresh to see changes.");
      } catch (e) {
        toast.error("Remove failed", e?.message || String(e));
      } finally {
        if (isAdmin) rm.removeAttribute("disabled");
      }
    });

    list.append(
      el("div", { class: "kpi-card", style: "display:flex; align-items:center; justify-content:space-between; gap:10px" }, [
        el("div", { class: "p", html: `<span style="font-weight:900">${row.email}</span><div style="color:rgba(231,237,245,.72); font-size:12px">${row.role}</div>` }),
        rm,
      ]),
    );
  }
  if ((data || []).length === 0) list.append(el("div", { class: "p", html: "No allowlisted emails yet." }));
  content.append(list);

  content.append(
    el("div", { class: "hint", style: "margin-top:12px" }, [
      document.createTextNode("Note: existing users may need a role backfill in SQL if they were created before allowlisting."),
    ]),
  );

  return root;
}


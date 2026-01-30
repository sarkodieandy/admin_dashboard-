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

export async function renderChats({ supabase, toast }) {
  const root = el("div", { class: "grid" });

  const card = el("div", { class: "card" }, [
    el("div", { class: "card-header" }, [
      el("div", { class: "card-title", html: "Chats" }),
      el("div", { class: "card-sub", html: "View recent chats and send a message (basic)." }),
    ]),
  ]);
  const content = el("div", { class: "card-content" });
  card.append(content);
  root.append(card);

  const { data: chats, error } = await supabase.from("chats").select("id,user_id,created_at").order("created_at", { ascending: false }).limit(30);
  if (error) throw error;

  const chatSelect = el("select", { class: "input" });
  for (const c of chats || []) {
    const opt = document.createElement("option");
    opt.value = c.id;
    opt.textContent = `Chat ${String(c.id).slice(0, 8)} • ${String(c.user_id).slice(0, 8)}`;
    chatSelect.append(opt);
  }

  const msg = el("input", { class: "input", placeholder: "Type a message…" });
  const send = el("button", { class: "btn btn-primary", type: "button" }, [document.createTextNode("Send")]);
  const messages = el("div", { class: "grid", style: "margin-top:12px" });

  async function loadMessages(chatId) {
    messages.innerHTML = "";
    if (!chatId) return;
    const res = await supabase.from("chat_messages").select("id,sender_id,message,created_at").eq("chat_id", chatId).order("created_at", { ascending: true }).limit(60);
    if (res.error) throw res.error;
    for (const m of res.data || []) {
      messages.append(el("div", { class: "kpi-card" }, [el("div", { class: "p", html: `<div style="font-weight:900">${String(m.sender_id).slice(0, 8)}</div><div style="color:rgba(231,237,245,.9)">${escapeHtml(m.message)}</div>` })]));
    }
    if ((res.data || []).length === 0) messages.append(el("div", { class: "p", html: "No messages yet." }));
  }

  function escapeHtml(s) {
    return String(s).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#039;" }[c] || c));
  }

  chatSelect.addEventListener("change", () => void loadMessages(chatSelect.value));

  send.addEventListener("click", async () => {
    const chatId = chatSelect.value;
    const text = msg.value.trim();
    if (!chatId || !text) return;
    send.setAttribute("disabled", "true");
    try {
      const { data: auth } = await supabase.auth.getUser();
      if (!auth.user) throw new Error("Not signed in");
      const ins = await supabase.from("chat_messages").insert({ chat_id: chatId, sender_id: auth.user.id, message: text });
      if (ins.error) throw ins.error;
      msg.value = "";
      toast.success("Sent");
      await loadMessages(chatId);
    } catch (e) {
      toast.error("Send failed", e?.message || String(e));
    } finally {
      send.removeAttribute("disabled");
    }
  });

  content.append(
    el("div", { class: "grid", style: "gap:12px" }, [
      el("div", { class: "grid", style: "grid-template-columns: 1fr 1fr auto; gap:10px" }, [
        el("label", { class: "field" }, [el("div", { class: "field-label", html: "Chat" }), chatSelect]),
        el("label", { class: "field" }, [el("div", { class: "field-label", html: "Message" }), msg]),
        el("div", { style: "display:flex; align-items:end" }, [send]),
      ]),
      messages,
    ]),
  );

  if ((chats || []).length > 0) {
    await loadMessages(chatSelect.value);
  } else {
    messages.append(el("div", { class: "p", html: "No chats found." }));
  }

  return root;
}


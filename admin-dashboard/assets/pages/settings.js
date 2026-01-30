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

export async function renderSettings() {
  const root = el("div", { class: "grid" });
  root.append(
    el("div", { class: "card" }, [
      el("div", { class: "card-header" }, [
        el("div", { class: "card-title", html: "Settings" }),
        el("div", { class: "card-sub", html: "General dashboard settings." }),
      ]),
      el("div", { class: "card-content" }, [el("div", { class: "p", html: "No settings yet." })]),
    ]),
  );
  return root;
}


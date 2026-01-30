const el = document.getElementById("toast");
let timer = null;

function show(kind, title, sub) {
  if (!el) return;
  if (timer) window.clearTimeout(timer);

  el.innerHTML = `
    <div class="t-title">${escapeHtml(title)}</div>
    ${sub ? `<div class="t-sub">${escapeHtml(sub)}</div>` : ""}
  `;
  el.classList.add("show");

  timer = window.setTimeout(() => {
    el.classList.remove("show");
  }, 3200);
}

function escapeHtml(s) {
  return String(s).replace(/[&<>"']/g, (c) => {
    switch (c) {
      case "&":
        return "&amp;";
      case "<":
        return "&lt;";
      case ">":
        return "&gt;";
      case '"':
        return "&quot;";
      case "'":
        return "&#039;";
      default:
        return c;
    }
  });
}

export const toast = {
  success(title, sub) {
    show("success", title, sub);
  },
  error(title, sub) {
    show("error", title, sub);
  },
  info(title, sub) {
    show("info", title, sub);
  },
};


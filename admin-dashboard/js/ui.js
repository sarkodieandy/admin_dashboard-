export function showToast(message) {
  let el = document.getElementById("toast");
  if (!el) {
    el = document.createElement("div");
    el.id = "toast";
    document.body.appendChild(el);
  }
  el.className = "toast";
  el.textContent = message;
  requestAnimationFrame(() => {
    el.classList.add("show");
    setTimeout(() => el.classList.remove("show"), 2200);
  });
}

export function renderSidebar(activeId) {
  const items = [
    ["dashboard.html", "Dashboard", "📊"],
    ["orders.html", "Orders", "🧾"],
    ["chats.html", "Chats", "💬"],
    ["menu.html", "Menu", "🍔"],
    ["customers.html", "Customers", "👥"],
    ["riders.html", "Riders", "🛵"],
    ["delivery-settings.html", "Delivery", "🚚"],
    ["promotions.html", "Promotions", "🏷️"],
    ["reviews-support.html", "Reviews", "⭐"],
    ["staff-roles.html", "Staff", "🧑‍🍳"],
    ["analytics.html", "Analytics", "📈"],
    ["settings.html", "Settings", "⚙️"],
  ];
  const nav = document.querySelector(".sidebar .nav");
  if (!nav) return;
  nav.innerHTML = items
    .map(
      ([href, label, icon]) =>
        `<a class="nav-item ${href.endsWith(activeId) ? "active" : ""}" href="${href}">${icon}<span>${label}</span></a>`
    )
    .join("");
}

export function renderTopbar(title) {
  const t = document.getElementById("pageTitle");
  if (t) t.textContent = title;
}

export function mountThemeToggle() {
  if (document.getElementById("themeToggle")) return;
  const btn = document.createElement("button");
  btn.id = "themeToggle";
  btn.className = "btn ghost";
  btn.style.position = "fixed";
  btn.style.top = "14px";
  btn.style.right = "14px";
  btn.style.zIndex = "80";
  const apply = (mode) => {
    document.documentElement.setAttribute("data-theme", mode);
    localStorage.setItem("theme", mode);
    btn.textContent = mode === "dark" ? "☀️ Light" : "🌙 Dark";
  };
  btn.addEventListener("click", () => {
    const current = document.documentElement.getAttribute("data-theme") || "light";
    apply(current === "light" ? "dark" : "light");
  });
  const saved = localStorage.getItem("theme") || "light";
  apply(saved);
  document.body.appendChild(btn);
}

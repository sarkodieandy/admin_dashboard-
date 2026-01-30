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

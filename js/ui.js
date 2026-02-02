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
    ["branches.html", "Branches", "🏠"],
    ["delivery-settings.html", "Delivery", "🚚"],
    ["promotions.html", "Promotions", "🏷️"],
    ["reviews-support.html", "Reviews", "⭐"],
    ["staff-roles.html", "Staff", "🧑‍🍳"],
    ["audit-logs.html", "Audit", "🧾"],
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

  mountMobileSidebar();
}

export function renderTopbar(title) {
  const t = document.getElementById("pageTitle");
  if (t) t.textContent = title;
}

export function mountMobileSidebar() {
  const layout = document.querySelector(".layout");
  const sidebar = document.querySelector(".sidebar");
  const topbar = document.querySelector(".topbar");
  if (!layout || !sidebar || !topbar) return;

  if (document.getElementById("sidebarBackdrop")) return;

  const backdrop = document.createElement("div");
  backdrop.id = "sidebarBackdrop";
  backdrop.className = "sidebar-backdrop";
  document.body.appendChild(backdrop);

  const btn = document.createElement("button");
  btn.id = "sidebarToggle";
  btn.className = "btn ghost icon-btn";
  btn.type = "button";
  btn.title = "Menu";
  btn.setAttribute("aria-label", "Open menu");
  btn.textContent = "☰";

  topbar.prepend(btn);

  const close = () => {
    layout.classList.remove("sidebar-open");
    document.body.classList.remove("sidebar-open");
    btn.setAttribute("aria-label", "Open menu");
  };
  const open = () => {
    layout.classList.add("sidebar-open");
    document.body.classList.add("sidebar-open");
    btn.setAttribute("aria-label", "Close menu");
  };
  const toggle = () => {
    if (layout.classList.contains("sidebar-open")) close();
    else open();
  };

  btn.addEventListener("click", toggle);
  backdrop.addEventListener("click", close);

  // Close on navigation.
  sidebar.addEventListener("click", (e) => {
    const a = e.target?.closest?.("a.nav-item");
    if (a) close();
  });

  // Close on escape.
  window.addEventListener("keydown", (e) => {
    if (e.key === "Escape") close();
  });

  // Close when leaving mobile breakpoint.
  const mq = window.matchMedia("(min-width: 821px)");
  mq.addEventListener?.("change", (ev) => {
    if (ev.matches) close();
  });
}

export function mountThemeToggle() {
  if (document.getElementById("themeToggle")) return;
  const btn = document.createElement("button");
  btn.id = "themeToggle";
  btn.className = "btn ghost";
  // Mount inside the topbar to avoid a floating overlay ("FAB") on pages.
  btn.style.padding = "8px 10px";
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
  const topbar = document.querySelector(".topbar");
  if (topbar) {
    topbar.appendChild(btn);
  }
}

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

const SESSION_STORAGE_KEY = "admin_session_profile_v1";

function humanizeRole(role) {
  return String(role || "")
    .trim()
    .replaceAll("_", " ")
    .replace(/\b\w/g, (match) => match.toUpperCase());
}

function getSidebarBrandTitle() {
  try {
    const raw = localStorage.getItem(SESSION_STORAGE_KEY);
    const profile = raw ? JSON.parse(raw) : null;
    const role = String(profile?.role || localStorage.getItem("admin_role") || "").trim();
    const name = String(profile?.name || "").trim();
    const restaurantName = String(profile?.restaurant_name || "").trim();

    if (role === "restaurant_owner") {
      return restaurantName || name || "Restaurant Owner";
    }

    if (name) {
      return name;
    }

    if (role) {
      return humanizeRole(role);
    }
  } catch {}
  return "Dashboard";
}

export function renderSidebar(activeId) {
  const role = (localStorage.getItem("admin_role") || "").trim();

  const menus = {
    platform_admin: [
      ["global-overview.html", "Dashboard", "🌐"],
      ["dashboard.html", "Operations", "📊"],
      ["restaurants.html", "Restaurants", "🏪"],
      ["branches.html", "Branches", "🏠"],
      ["riders.html", "Riders", "🛵"],
      ["commissions.html", "Revenue", "💸"],
      ["users.html", "Users", "👥"],
      ["analytics.html", "Analytics", "📈"],
      ["settings.html", "Settings", "⚙️"],
    ],
    restaurant_owner: [
      ["dashboard.html", "Overview", "📊"],
      ["branches.html", "Branches", "🏠"],
      ["orders.html", "Orders", "🧾"],
      ["menu.html", "Menu", "🍔"],
      ["riders.html", "Riders", "🛵"],
      ["customers.html", "Customers", "👥"],
      ["chats.html", "Chats", "💬"],
      ["analytics.html", "Analytics", "📈"],
      ["staff-roles.html", "Staff", "🧑‍🍳"],
      ["settings.html", "Settings", "⚙️"],
    ],
    branch_admin: [
      ["orders.html", "Orders", "🧾"],
      ["menu.html", "Menu", "🍔"],
      ["chats.html", "Chats", "💬"],
      ["settings.html", "Settings", "⚙️"],
    ],
    staff: [
      ["orders.html", "Orders", "🧾"],
      ["menu.html", "Menu", "🍔"],
      ["chats.html", "Chats", "💬"],
      ["settings.html", "Settings", "⚙️"],
    ],
    super_admin: [
      ["dashboard.html", "Overview", "📊"],
      ["restaurants.html", "Restaurants", "🏪"],
      ["branches.html", "Branches", "🏠"],
      ["orders.html", "Orders", "🧾"],
      ["deliveries.html", "Deliveries", "🛵"],
      ["riders.html", "Riders", "🛵"],
      ["commissions.html", "Revenue & Commissions", "💸"],
      ["users.html", "Users", "👥"],
      ["analytics.html", "Analytics", "📈"],
      ["settings.html", "Settings", "⚙️"],
    ],
  };

  const items = menus[role] || menus.staff;
  const brand = document.querySelector(".sidebar .brand");
  const nav = document.querySelector(".sidebar .nav");
  if (brand) {
    brand.textContent = getSidebarBrandTitle();
    brand.title = brand.textContent;
  }
  if (!nav) return;
  nav.innerHTML = items
    .map(
      ([href, label, icon]) =>
        `<a class="nav-item ${href.endsWith(activeId) ? "active" : ""}" href="${href}">${icon}<span>${label}</span></a>`
    )
    .join("");

  mountMobileSidebar();

  // Allow auth layer to re-render the sidebar after it refreshes session/profile.
  try {
    window.__rerenderSidebar = () => renderSidebar(activeId);
  } catch {}
}

export function renderTopbar(title) {
  const t = document.getElementById("pageTitle");
  if (t) t.textContent = title;
}

// Mounts a status banner if the restaurant is pending/suspended (non-platform roles).
export function mountStatusBanner() {
  const block = window.__restaurantBlock;
  const role = (localStorage.getItem("admin_role") || "").trim();
  if (!block || ["platform_admin", "super_admin"].includes(role)) return;
  if (document.getElementById("statusBanner")) return;
  const banner = document.createElement("div");
  banner.id = "statusBanner";
  banner.className = "status-banner";
  banner.innerHTML = `
    <div class="status-banner__icon">⚠️</div>
    <div>
      <div class="status-banner__title">Your restaurant is ${block.status || "pending"}.</div>
      <div class="status-banner__body">You can browse data but actions like managing orders or menu are disabled until approval.</div>
    </div>
  `;
  const layout = document.querySelector(".page");
  if (layout) {
    layout.prepend(banner);
  } else {
    document.body.prepend(banner);
  }
  document.body.classList.add("status-blocked");

  // Hard-disable interactive controls except those explicitly allowed.
  const allowSelectors = ["#logoutBtn", "#logoutBtnInline", "#refreshBtn", "#refreshBtnInline", ".status-banner button"];
  const allow = (el) => allowSelectors.some((sel) => el.matches(sel)) || el.closest("#statusBanner");
  document.querySelectorAll("button, input, select, textarea").forEach((el) => {
    if (allow(el)) return;
    el.dataset._prevDisabled = el.disabled ? "1" : "0";
    el.disabled = true;
  });
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

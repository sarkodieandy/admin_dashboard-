export const routeTitles = {
  "/dashboard": "Dashboard",
  "/orders": "Orders",
  "/menu": "Menu",
  "/customers": "Customers",
  "/chats": "Chats",
  "/notifications": "Notifications",
  "/delivery-settings": "Delivery settings",
  "/staff": "Staff & Roles",
  "/settings": "Settings",
};

function parseHash() {
  const raw = window.location.hash || "";
  const route = raw.startsWith("#") ? raw.slice(1) : raw;
  if (!route) return "/dashboard";
  if (!route.startsWith("/")) return "/dashboard";
  return route.split("?")[0] || "/dashboard";
}

export const router = {
  _onRoute: null,
  _defaultRoute: "/dashboard",
  start({ defaultRoute, onRoute }) {
    this._defaultRoute = defaultRoute || "/dashboard";
    this._onRoute = onRoute;
    const handle = () => {
      const r = this.current();
      if (typeof this._onRoute === "function") this._onRoute(r);
    };
    window.addEventListener("hashchange", handle);
    if (!window.location.hash) {
      window.location.hash = `#${this._defaultRoute}`;
    } else {
      handle();
    }
  },
  current() {
    return parseHash() || this._defaultRoute;
  },
  navigate(route) {
    window.location.hash = `#${route}`;
  },
};


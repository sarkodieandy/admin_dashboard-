export const fmtMoney = (n) => `GH₵ ${Number(n || 0).toFixed(2)}`;
export const fmtDateTime = (d) => new Date(d).toLocaleString();
export const debounce = (fn, wait = 250) => {
  let t;
  return (...args) => {
    clearTimeout(t);
    t = setTimeout(() => fn(...args), wait);
  };
};
export const debugEnabled = () => localStorage.getItem("admin_debug") === "1";
export const debug = (...args) => {
  if (!debugEnabled()) return;
  // eslint-disable-next-line no-console
  console.log("[admin]", ...args);
};
export const statusLabel = (s) => {
  const map = {
    placed: "Placed",
    confirmed: "Confirmed",
    preparing: "Preparing",
    ready: "Ready",
    en_route: "On the way",
    delivered: "Delivered",
    cancelled: "Cancelled",
  };
  return map[s] || s;
};

export const deliveryStatusLabel = (s) => {
  const map = {
    assigned: "Assigned",
    picked_up: "Picked up",
    en_route: "On the way",
    delivered: "Delivered",
    cancelled: "Cancelled",
  };
  return map[s] || s;
};

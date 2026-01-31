export const fmtMoney = (n) => `GH₵ ${Number(n || 0).toFixed(2)}`;
export const fmtDateTime = (d) => new Date(d).toLocaleString();
export const debounce = (fn, wait = 250) => {
  let t;
  return (...args) => {
    clearTimeout(t);
    t = setTimeout(() => fn(...args), wait);
  };
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

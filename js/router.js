export function setActiveNav(pathname) {
  document.querySelectorAll(".nav-item").forEach((el) => {
    const href = el.getAttribute("href");
    el.classList.toggle("active", href === pathname);
  });
}

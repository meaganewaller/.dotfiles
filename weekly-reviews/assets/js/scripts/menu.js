document.addEventListener("DOMContentLoaded", initMenu);

function initMenu() {
  const button = document.getElementById("menu-button");
  const menu = document.getElementById("menu");
  const burger = document.getElementById("burger");
  const closeIcon = document.getElementById("close");

  if (!button || !menu) return;

  const body = document.body;
  let open = false;

  let scrollY = 0;

  function lockScroll() {
    scrollY = window.scrollY;
    body.style.position = "fixed";
    body.style.top = `-${scrollY}px`;
  }

  function unlockScroll() {
    body.style.position = "";
    body.style.top = "";
    window.scrollTo(0, scrollY);
  }

  function openMenu() {
    open = true;

    menu.classList.remove("hidden");
    burger?.classList.add("hidden");
    closeIcon?.classList.remove("hidden");

    lockScroll();

    button.setAttribute("aria-expanded", "true");
  }

  function closeMenu() {
    open = false;

    menu.classList.add("hidden");
    burger?.classList.remove("hidden");
    closeIcon?.classList.add("hidden");

    unlockScroll();
    button.setAttribute("aria-expanded", "false");
  }

  function toggleMenu() {
    open ? closeMenu() : openMenu();
  }

  button.addEventListener("click", toggleMenu);

  /* -----------------------------
     Close when clicking outside
  --------------------------------*/

  document.addEventListener("click", (e) => {
    if (!open) return;

    if (!menu.contains(e.target) && !button.contains(e.target)) {
      closeMenu();
    }
  });

  /* -----------------------------
     Escape key closes menu
  --------------------------------*/

  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape" && open) {
      closeMenu();
    }
  });
}

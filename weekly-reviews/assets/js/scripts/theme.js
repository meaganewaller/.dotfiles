document.addEventListener("DOMContentLoaded", initTheme);

function initTheme() {
  const html = document.documentElement;

  const toggleButton = document.getElementById("theme-toggle");
  const themeLabel = document.getElementById("theme-label");
  const optionsMenu = document.getElementById("theme-options");
  const iconWrapper = toggleButton?.querySelector(".icon-wrapper");

  const optionButtons = document.querySelectorAll(".theme-option");
  const metaTheme = document.querySelector('meta[name="theme-color"]');

  if (!toggleButton || !optionsMenu) return;

  const COLORS = {
    dark: "#1b1b1a",
    light: "#fafaf9"
  };

  const icons = {
    system: `<svg class="w-4 h-4 fill-gray-700 dark:fill-gray-300" viewBox="0 0 32 32"><path d="M16 2.667c-7.36 0-13.333 5.973-13.333 13.333s5.973 13.333 13.333 13.333c7.36 0 13.333-5.973 13.333-13.333s-5.973-13.333-13.333-13.333zM16 5.333c5.893 0 10.667 4.773 10.667 10.667s-4.773 10.667-10.667 10.667v-21.333z"></path></svg>`,
    dark: `<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646A9 9 0 1012 21a9 9 0 008.354-5.646z"></path></svg>`,
    light: `<svg class="w-4 h-4 fill-gray-700" viewBox="0 0 32 32"><path d="M4.733 24.72l1.88 1.88 2.4-2.387L7.12 22.32zm9.934 5.213h2.667V26h-2.667zM16 7.333c-4.413 0-8 3.587-8 8s3.587 8 8 8 8-3.587 8-8c0-4.427-3.587-8-8-8zm10.667 9.334h4V14h-4zm-3.68 7.546l2.4 2.387 1.88-1.88-2.387-2.4zm4.28-18.266l-1.88-1.88-2.4 2.387 1.893 1.893zM17.333.733h-2.667v3.933h2.667zM5.333 14h-4v2.667h4zm3.68-7.547l-2.4-2.387-1.88 1.88 2.387 2.4 1.893-1.893z"></path></svg>`
  };

  const mediaQuery = window.matchMedia("(prefers-color-scheme: dark)");

  let menuOpen = false;

  /* -----------------------------
     Helpers
  --------------------------------*/

  const systemTheme = () => (mediaQuery.matches ? "dark" : "light");

  function setThemeColor(theme) {
    if (metaTheme) metaTheme.setAttribute("content", COLORS[theme]);
  }

  function updateUI(mode) {
    if (themeLabel) {
      themeLabel.textContent = mode.charAt(0).toUpperCase() + mode.slice(1);
    }

    if (iconWrapper) {
      iconWrapper.innerHTML = icons[mode];
    }
  }

  /* -----------------------------
     Apply Theme
  --------------------------------*/

  function applyTheme(mode) {
    const actualTheme = mode === "system" ? systemTheme() : mode;

    html.classList.remove("dark", "light");
    html.classList.add(actualTheme);

    setThemeColor(actualTheme);
    updateUI(mode);

    if (mode === "system") {
      localStorage.removeItem("theme");
    } else {
      localStorage.setItem("theme", mode);
    }
  }

  /* -----------------------------
     Menu Controls
  --------------------------------*/

  function showMenu() {
    menuOpen = true;
    optionsMenu.classList.remove("opacity-0", "scale-95", "pointer-events-none");
    optionsMenu.classList.add("opacity-100", "scale-100", "pointer-events-auto");
  }

  function hideMenu() {
    menuOpen = false;
    optionsMenu.classList.remove("opacity-100", "scale-100", "pointer-events-auto");
    optionsMenu.classList.add("opacity-0", "scale-95", "pointer-events-none");
  }

  /* -----------------------------
     Events
  --------------------------------*/

  toggleButton.addEventListener("click", () => {
    menuOpen ? hideMenu() : showMenu();
  });

  optionButtons.forEach(btn => {
    btn.addEventListener("click", () => {
      const theme = btn.dataset.theme;
      applyTheme(theme);
      hideMenu();
    });
  });

  window.addEventListener("click", e => {
    if (!toggleButton.contains(e.target) && !optionsMenu.contains(e.target)) {
      hideMenu();
    }
  });

  window.addEventListener("keydown", e => {
    if (e.key === "Escape") hideMenu();
  });

  window.addEventListener("scroll", hideMenu);

  /* -----------------------------
     System theme change
  --------------------------------*/

  mediaQuery.addEventListener("change", () => {
    if (!localStorage.getItem("theme")) {
      applyTheme("system");
    }
  });

  /* -----------------------------
     Initial load
  --------------------------------*/

  const saved = localStorage.getItem("theme") || "system";
  applyTheme(saved);
}

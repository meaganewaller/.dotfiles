function initScrollIndicator() {
  const article = document.querySelector("article");
  if (!article) return;

  // Prevent duplicate indicators
  if (document.getElementById("scroll-indicator-container")) return;

  const container = document.createElement("div");
  container.id = "scroll-indicator-container";
  container.className =
    "fixed top-0 left-0 w-full h-1 bg-paper dark:bg-gray-950 z-50 pointer-events-none";

  const indicator = document.createElement("div");
  indicator.id = "scroll-indicator";
  indicator.className = "h-full bg-primary origin-left will-change-transform";

  indicator.style.transform = "scaleX(0)";

  container.appendChild(indicator);
  document.body.prepend(container);

  let scrollMax = 0;
  let ticking = false;

  function calculateScrollMax() {
    scrollMax = document.documentElement.scrollHeight - window.innerHeight;
  }

  function update() {
    const scrollTop = window.pageYOffset || document.documentElement.scrollTop;

    const progress = scrollMax > 0 ? scrollTop / scrollMax : 0;

    indicator.style.transform = `scaleX(${Math.min(progress, 1)})`;

    ticking = false;
  }

  function onScroll() {
    if (!ticking) {
      requestAnimationFrame(update);
      ticking = true;
    }
  }

  calculateScrollMax();
  update();

  window.addEventListener("scroll", onScroll, { passive: true });
  window.addEventListener("resize", () => {
    calculateScrollMax();
    update();
  });
}

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", initScrollIndicator);
} else {
  initScrollIndicator();
}

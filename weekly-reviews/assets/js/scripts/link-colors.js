(function () {
  "use strict";

  /* -----------------------------
       Palettes
    --------------------------------*/

  const INTERNAL = [
    "#ff3b8d",
    "#ff6ec7",
    "#ff4fa3",
    "#ff8fab",
    "#f472b6",
    "#ff9de2",
    "#c084fc",
    "#a78bfa",
    "#7c7cff",
  ];

  const EXTERNAL = [
    "#10a2f5",
    "#5aa9ff",
    "#2dd4bf",
    "#24d05a",
    "#a3e635",
    "#ffd166",
    "#ffa552",
    "#ff7a45",
  ];

  const assigned = new WeakMap();

  /* -----------------------------
       Utilities
    --------------------------------*/

  function hash(str) {
    let h = 0;
    for (let i = 0; i < str.length; i++) {
      h = (h << 5) - h + str.charCodeAt(i);
      h |= 0;
    }
    return Math.abs(h);
  }

  function brighten(hex, amount = 0.18) {
    const num = parseInt(hex.slice(1), 16);

    let r = (num >> 16) + Math.floor(255 * amount);
    let g = ((num >> 8) & 255) + Math.floor(255 * amount);
    let b = (num & 255) + Math.floor(255 * amount);

    r = Math.min(255, r);
    g = Math.min(255, g);
    b = Math.min(255, b);

    return `rgb(${r}, ${g}, ${b})`;
  }

  function isExternal(link) {
    return link.hostname && link.hostname !== location.hostname;
  }

  function applyColor(link, color) {
    link.style.color = color;
    link.style.textDecorationColor = color;
  }

  /* -----------------------------
       Assign colors
    --------------------------------*/

  function assignColors() {
    const links = document.querySelectorAll("main a, article a");

    let lastColor = null;

    links.forEach((link) => {
      const palette = isExternal(link) ? EXTERNAL : INTERNAL;

      const key = link.href || link.textContent;
      const index = hash(key) % palette.length;

      let color = palette[index];

      if (color === lastColor) {
        color = palette[(index + 1) % palette.length];
      }

      assigned.set(link, color);
      applyColor(link, color);

      lastColor = color;
    });
  }

  /* -----------------------------
       Hover behavior
    --------------------------------*/

  function handleHover(e) {
    const link = e.target.closest("a");
    if (!link) return;

    const base = assigned.get(link);
    if (!base) return;

    applyColor(link, brighten(base));
  }

  function restore(e) {
    const link = e.target.closest("a");
    if (!link) return;

    const base = assigned.get(link);
    if (!base) return;

    applyColor(link, base);
  }

  /* -----------------------------
       Init
    --------------------------------*/

  function init() {
    assignColors();

    document.addEventListener("mouseover", handleHover);
    document.addEventListener("mouseout", restore);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();

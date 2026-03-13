document.addEventListener("DOMContentLoaded", () => {
  const lightbox = document.getElementById("lightbox");
  const img = document.getElementById("lightbox-img");

  if (!lightbox || !img) return;

  const body = document.body;
  let open = false;

  /* -----------------------------
       Open lightbox
    --------------------------------*/

  function openLightbox(target) {
    const src = target.dataset.full || target.currentSrc || target.src;
    const alt = target.alt || "";

    img.classList.remove("opacity-100");
    img.classList.add("opacity-0");

    img.src = src;
    img.alt = alt;

    lightbox.classList.remove("hidden");
    body.classList.add("overflow-hidden");

    img.addEventListener(
      "load",
      () => {
        requestAnimationFrame(() => {
          lightbox.classList.replace("opacity-0", "opacity-100");
          img.classList.replace("opacity-0", "opacity-100");
        });
      },
      { once: true },
    );

    open = true;
  }

  /* -----------------------------
       Close lightbox
    --------------------------------*/

  function closeLightbox() {
    if (!open) return;

    lightbox.classList.replace("opacity-100", "opacity-0");
    img.classList.replace("opacity-100", "opacity-0");

    setTimeout(() => {
      lightbox.classList.add("hidden");
      img.src = "";
      body.classList.remove("overflow-hidden");
      open = false;
    }, 250);
  }

  /* -----------------------------
       Click handling (delegated)
    --------------------------------*/

  document.addEventListener("click", (e) => {
    const image = e.target.closest("img[data-lightbox]");

    if (image) {
      openLightbox(image);
      return;
    }

    if (open && e.target === lightbox) {
      closeLightbox();
    }
  });

  /* -----------------------------
       Keyboard support
    --------------------------------*/

  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape") closeLightbox();
  });

  /* -----------------------------
       Hi-res preloading
    --------------------------------*/

  const observer = new IntersectionObserver(
    (entries, obs) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;

        const hiRes = entry.target.dataset.full;

        if (hiRes) {
          const preload = new Image();
          preload.src = hiRes;
        }

        obs.unobserve(entry.target);
      });
    },
    { rootMargin: "200px" },
  );

  document
    .querySelectorAll("img[data-full]")
    .forEach((image) => observer.observe(image));
});

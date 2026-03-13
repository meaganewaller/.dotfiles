document.addEventListener("DOMContentLoaded", () => {
    const preview = createPreview();
    let activeLink = null;
    let visible = false;
    let moveRAF = null;

    document.body.appendChild(preview.container);

    /* -----------------------------
       Event delegation
    --------------------------------*/

    document.addEventListener("mouseover", (e) => {
      const link = e.target.closest("a.internal-link");
      if (!link) return;

      const title = link.dataset.previewTitle;
      const excerpt = link.dataset.previewExcerpt;

      if (!title || !excerpt) return;

      activeLink = link;

      preview.title.textContent = title;
      preview.excerpt.textContent = excerpt;

      preview.container.style.display = "block";
      visible = true;
    });

    document.addEventListener("mouseout", (e) => {
      if (!activeLink) return;

      if (!e.relatedTarget || !activeLink.contains(e.relatedTarget)) {
        preview.container.style.display = "none";
        visible = false;
        activeLink = null;
      }
    });

    document.addEventListener("mousemove", (e) => {
      if (!visible) return;

      if (!moveRAF) {
        moveRAF = requestAnimationFrame(() => {
          positionPreview(e.pageX, e.pageY);
          moveRAF = null;
        });
      }
    });

    /* -----------------------------
       Positioning
    --------------------------------*/

    function positionPreview(x, y) {
      const offset = 16;

      let left = x + offset;
      let top = y + offset;

      const rect = preview.container.getBoundingClientRect();

      if (left + rect.width > window.innerWidth) {
        left = x - rect.width - offset;
      }

      if (top + rect.height > window.innerHeight) {
        top = y - rect.height - offset;
      }

      preview.container.style.left = `${left}px`;
      preview.container.style.top = `${top}px`;
    }

    /* -----------------------------
       DOM creation
    --------------------------------*/

    function createPreview() {
      const container = document.createElement("div");

      container.id = "link-preview";
      container.style.position = "absolute";
      container.style.display = "none";

      container.className = `
        bg-gray-50 text-black border border-gray-100
        rounded shadow-lg text-sm leading-snug p-2 z-50
        dark:bg-gray-800 dark:text-white dark:border-gray-600
        max-w-sm pointer-events-none
      `;

      const title = document.createElement("div");
      title.className = "font-bold text-lg capitalize";

      const excerpt = document.createElement("div");
      excerpt.className =
        "mt-1 max-h-[8em] overflow-hidden relative text-sm whitespace-pre-wrap";

      const gradient = document.createElement("div");
      gradient.className =
        "absolute bottom-0 left-0 w-full h-[4em] bg-gradient-to-t from-gray-50 dark:from-gray-800 to-transparent";

      container.appendChild(title);
      container.appendChild(excerpt);
      container.appendChild(gradient);

      return { container, title, excerpt };
    }
  });

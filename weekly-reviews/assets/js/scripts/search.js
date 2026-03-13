document.addEventListener("DOMContentLoaded", initSearch);

function initSearch() {
  const modal = document.getElementById("search-modal");
  const input = document.getElementById("search-input");
  const resultsEl = document.getElementById("search-results");

  if (!modal || !input || !resultsEl) return;

  const triggerDesktop = document.getElementById("search-trigger");
  const triggerMobile = document.getElementById("search-trigger-mobile");
  const closeButton = document.getElementById("modal-close");

  let index;
  let store = {};
  let loaded = false;
  let currentFocus = -1;

  const isMac = navigator.userAgent.includes("Mac");

  /* -----------------------------
     Modal controls
  --------------------------------*/

  function openModal() {
    modal.classList.add("opacity-100");
    modal.classList.remove("opacity-0", "pointer-events-none");
    input.focus();

    loadSearch();
  }

  function closeModal() {
    modal.classList.remove("opacity-100");
    modal.classList.add("opacity-0", "pointer-events-none");

    input.blur();
    currentFocus = -1;
  }

  /* -----------------------------
     Event bindings
  --------------------------------*/

  triggerDesktop?.addEventListener("click", openModal);
  triggerMobile?.addEventListener("click", openModal);
  closeButton?.addEventListener("click", closeModal);

  modal.addEventListener("click", (e) => {
    if (e.target === modal) closeModal();
  });

  document.addEventListener("keydown", (e) => {
    const shortcut =
      (isMac && e.metaKey && e.key === "k") ||
      (!isMac && e.ctrlKey && e.key === "k");

    if (shortcut) {
      e.preventDefault();

      if (typeof fathom !== "undefined") {
        fathom.trackEvent("Search");
      }

      openModal();
    }

    if (e.key === "Escape") closeModal();
  });

  /* -----------------------------
     Load search index
  --------------------------------*/

  async function loadSearch() {
    if (loaded) return;

    loaded = true;

    try {
      const { default: FlexSearch } = await import(
        "/assets/js/vendor/flexsearch.bundle.module.min.js"
      );

      index = new FlexSearch.Document({
        document: {
          id: "url",
          index: ["title", "content", "tags"],
          store: ["title", "url"],
        },
        tokenize: "forward",
        cache: true,
      });

      const res = await fetch("/search.json");
      const posts = await res.json();

      posts.forEach((post) => {
        index.add(post);
        store[post.url] = post;
      });

      attachSearchHandlers();
    } catch (err) {
      console.error("Search failed to load", err);
    }
  }

  /* -----------------------------
     Search input
  --------------------------------*/

  function attachSearchHandlers() {
    input.addEventListener("input", handleSearch);
    input.addEventListener("keydown", handleKeyboardNav);
  }

  function handleSearch() {
    const query = input.value.trim();

    currentFocus = -1;

    if (!query) {
      renderMessage("Quick search for anything");
      return;
    }

    const results = index.search(query, { enrich: true });

    const urls = new Set();

    results.forEach((group) => {
      group.result.forEach((r) => urls.add(r.doc.url));
    });

    if (urls.size === 0) {
      renderMessage("No results found");
      return;
    }

    renderResults([...urls]);
  }

  /* -----------------------------
     Render results
  --------------------------------*/

  function renderMessage(text) {
    resultsEl.innerHTML = `
      <div class="text-gray-400 dark:text-gray-200 text-center">
        ${text}
      </div>
    `;
  }

  function renderResults(urls) {
    resultsEl.innerHTML = urls
      .map((url) => {
        const post = store[url];

        return `
          <a href="${post.url}"
             class="search-item block px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 rounded">
             <div class="font-medium text-gray-800 dark:text-gray-200">
               ${post.title}
             </div>
          </a>
        `;
      })
      .join("");

    resultsEl.querySelectorAll(".search-item").forEach((item) => {
      item.addEventListener("click", closeModal);
    });
  }

  /* -----------------------------
     Keyboard navigation
  --------------------------------*/

  function handleKeyboardNav(e) {
    const items = resultsEl.querySelectorAll(".search-item");
    if (!items.length) return;

    if (e.key === "ArrowDown") {
      currentFocus = (currentFocus + 1) % items.length;
      updateActive(items);
      e.preventDefault();
    }

    if (e.key === "ArrowUp") {
      currentFocus = (currentFocus - 1 + items.length) % items.length;
      updateActive(items);
      e.preventDefault();
    }

    if (e.key === "Enter" && currentFocus >= 0) {
      items[currentFocus].click();
    }
  }

  function updateActive(items) {
    items.forEach((item, i) => {
      const active = i === currentFocus;

      item.classList.toggle("bg-gray-100", active);
      item.classList.toggle("dark:bg-gray-600", active);

      if (active) {
        item.scrollIntoView({ block: "nearest" });
      }
    });
  }
}

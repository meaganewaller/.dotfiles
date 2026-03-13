// Table of Contents Generator
document.addEventListener("DOMContentLoaded", initTOC);

function initTOC() {
  const DEBUG = false;

  const tocContainer = document.getElementById("table-of-contents");
  const tocContent = document.getElementById("toc-content");
  const article = document.querySelector(".prose");

  if (!tocContainer || !tocContent || !article) {
    if (DEBUG) console.log("TOC: required elements missing");
    return;
  }

  const headings = [...article.querySelectorAll("h2, h3, h4, h5, h6")];

  if (!headings.length) {
    tocContainer.style.display = "none";
    return;
  }

  generateHeadingIDs(headings);

  tocContent.innerHTML = buildTOC(headings);

  setupScrolling(tocContainer);

  setupActiveSection(headings, tocContainer);

  setupCollapse();
}

/* -----------------------------
   Generate unique heading IDs
--------------------------------*/
function generateHeadingIDs(headings) {
  const used = new Set();

  headings.forEach((heading, i) => {
    if (!heading.id) {
      let slug = heading.textContent
        .toLowerCase()
        .trim()
        .replace(/[^\w\s-]/g, "")
        .replace(/\s+/g, "-");

      if (!slug) slug = `heading-${i}`;

      let unique = slug;
      let counter = 1;

      while (used.has(unique)) {
        unique = `${slug}-${counter++}`;
      }

      heading.id = unique;
      used.add(unique);
    }
  });
}

/* -----------------------------
   Build TOC HTML
--------------------------------*/
function buildTOC(headings) {
  return headings
    .map((heading) => {
      const level = Number(heading.tagName[1]);
      const indent = Math.max(level - 2, 0);

      return `
        <div class="toc-item" style="padding-left:${indent * 1}rem">
          <a href="#${heading.id}" class="toc-link">
            ${heading.textContent}
          </a>
        </div>
      `;
    })
    .join("");
}

/* -----------------------------
   Smooth scrolling
--------------------------------*/
function setupScrolling(tocContainer) {
  tocContainer.addEventListener("click", (e) => {
    const link = e.target.closest(".toc-link");
    if (!link) return;

    e.preventDefault();

    const id = link.getAttribute("href").substring(1);
    const target = document.getElementById(id);

    if (!target) return;

    target.scrollIntoView({
      behavior: "smooth",
      block: "start",
    });

    history.replaceState(null, "", `#${id}`);
  });
}

/* -----------------------------
   Active section highlighting
--------------------------------*/
function setupActiveSection(headings, tocContainer) {
  const links = [...tocContainer.querySelectorAll(".toc-link")];

  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;

        links.forEach((link) => link.classList.remove("active"));

        const link = tocContainer.querySelector(
          `.toc-link[href="#${entry.target.id}"]`
        );

        if (link) link.classList.add("active");
      });
    },
    {
      rootMargin: "-40% 0px -55% 0px",
      threshold: 0,
    }
  );

  headings.forEach((h) => observer.observe(h));
}

/* -----------------------------
   Collapse / expand
--------------------------------*/
function setupCollapse() {
  const toggle = document.getElementById("toc-toggle");
  const chevron = document.getElementById("toc-chevron");
  const content = document.getElementById("toc-content");

  if (!toggle || !chevron || !content) return;

  let expanded = false;

  toggle.addEventListener("click", () => {
    expanded = !expanded;

    content.style.maxHeight = expanded
      ? content.scrollHeight + "px"
      : "0px";

    chevron.style.transform = expanded
      ? "rotate(90deg)"
      : "rotate(0deg)";

    toggle.setAttribute("aria-expanded", expanded);
  });

  toggle.setAttribute("aria-expanded", "false");
  content.style.maxHeight = "0px";
}

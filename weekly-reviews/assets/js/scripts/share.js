(() => {
  "use strict";

  document.addEventListener("DOMContentLoaded", initShare);

  function initShare() {
    const shareBtn = document.getElementById("share-btn");
    const popup = document.getElementById("copied-popup");

    if (!shareBtn || !popup) return;

    let hideTimer = null;

    shareBtn.addEventListener("click", async (e) => {
      e.preventDefault();

      const url = shareBtn.dataset.url || window.location.href;

      if (!url) return;

      const copied = await copyToClipboard(url);

      if (copied) showFeedback(popup);
    });

    /* -----------------------------
         Copy logic
      --------------------------------*/

    async function copyToClipboard(text) {
      try {
        if (navigator.clipboard && window.isSecureContext) {
          await navigator.clipboard.writeText(text);
          return true;
        }

        return fallbackCopy(text);
      } catch (err) {
        console.warn("Clipboard API failed, using fallback", err);
        return fallbackCopy(text);
      }
    }

    function fallbackCopy(text) {
      const textarea = document.createElement("textarea");

      textarea.value = text;
      textarea.style.position = "fixed";
      textarea.style.opacity = "0";

      document.body.appendChild(textarea);

      textarea.select();

      const success = document.execCommand("copy");

      textarea.remove();

      return success;
    }

    /* -----------------------------
         UI feedback
      --------------------------------*/

    function showFeedback(el) {
      el.classList.remove("opacity-0");
      el.classList.add("opacity-100");

      clearTimeout(hideTimer);

      hideTimer = setTimeout(() => {
        el.classList.remove("opacity-100");
        el.classList.add("opacity-0");
      }, 1800);
    }
  }
})();

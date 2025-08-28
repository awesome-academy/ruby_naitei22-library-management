function initBorrowCart() {
  const form = document.querySelector("#borrow-cart-form");
  if (!form) return;

  const updateUrl = form.dataset.updateUrl;
  const startDateField = form.querySelector("#start_date");
  const endDateField = form.querySelector("#end_date");

  // ===== Auto-save =====
  async function autoSave() {
    try {
      const formData = new FormData(form);
      const res = await fetch(updateUrl, {
        method: "PATCH",
        body: formData,
        headers: {
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "X-Requested-With": "XMLHttpRequest"
        },
        credentials: "same-origin"
      });
      if (!res.ok) showFlash("danger", I18n.t("borrow_request.auto_save_failed"));
    } catch (err) {
      console.error("Auto-save error:", err);
      showFlash("danger", I18n.t("borrow_request.auto_save_failed"));
    }
  }

  // ===== Update min end_date =====
  function updateMinEndDate() {
    if (startDateField && endDateField && startDateField.value) {
      const startDate = new Date(startDateField.value);
      if (!isNaN(startDate)) {
        const minEndDate = new Date(startDate);
        minEndDate.setDate(minEndDate.getDate() + 1);
        const minStr = minEndDate.toISOString().split("T")[0];
        endDateField.min = minStr;
        if (new Date(endDateField.value) <= startDate) endDateField.value = minStr;
      }
    }
  }

  updateMinEndDate();

  // ===== Event delegation =====
  form.addEventListener("change", (e) => {
    if (!e.target) return;
    if (e.target === startDateField) updateMinEndDate();
    if (
      e.target.matches(".auto-save") ||
      e.target.matches(".borrow-book-checkbox") ||
      e.target === startDateField ||
      e.target === endDateField
    ) autoSave();
  });

  form.addEventListener("click", async (e) => {
    const btn = e.target.closest(".js-remove-from-cart");
    if (!btn) return;

    const bookId = btn.dataset.bookId;
    const url = btn.dataset.url;
    const confirmMsg = btn.dataset.confirm || I18n.t("borrow_request.cart_item.confirm_remove");

    if (!confirm(confirmMsg)) return;

    try {
      const res = await fetch(url, {
        method: "DELETE",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "Accept": "application/json"
        },
        credentials: "same-origin"
      });

      if (!res.ok) throw new Error("Network response was not ok");
      const data = await res.json();

      if (data.success) {
        // Lấy trang hiện tại
        let currentPage = parseInt(new URLSearchParams(window.location.search).get("page") || "1", 10);
        if (currentPage < 1) currentPage = 1;

        // Fetch lại table + pagination
        const tableRes = await fetch(`/borrow_request?page=${currentPage}`, { headers: { "Accept": "text/html" } });
        const html = await tableRes.text();
        const parser = new DOMParser();
        const doc = parser.parseFromString(html, "text/html");

        const newTable = doc.querySelector("table.table");
        const oldTable = form.querySelector("table.table");

        const rows = newTable?.querySelectorAll("tbody tr") || [];

        if (rows.length === 0) {
          // Nếu xóa hết sách hoặc chỉ còn 1 và xóa → reload page
          window.location.reload();
          return;
        }

        // Update table
        if (newTable && oldTable) oldTable.replaceWith(newTable);

        // Update pagination
        const newPagination = doc.querySelector(".pagination");
        const oldPagination = document.querySelector(".pagination");
        if (newPagination && oldPagination) oldPagination.replaceWith(newPagination);

        showFlash("success", data.message || I18n.t("borrow_request.remove_success"));
      } else {
        showFlash("danger", data.message || I18n.t("borrow_request.remove_failed"));
      }
    } catch (err) {
      console.error("Remove error:", err);
      showFlash("danger", I18n.t("borrow_request.remove_failed"));
    }
  });
}

function showFlash(type, message) {
  const flashBox = document.getElementById("flash");
  if (!flashBox) return;
  flashBox.innerHTML = `<div class="alert alert-${type}">${message}</div>`;
  setTimeout(() => { flashBox.innerHTML = ""; }, 3000);
}

document.addEventListener("turbo:load", initBorrowCart);

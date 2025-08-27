document.addEventListener("DOMContentLoaded", () => {
  document.querySelectorAll(".rating-input").forEach(input => {
    input.addEventListener("input", e => {
      let value = e.target.value;

      // Xóa ký tự không hợp lệ (chữ, dấu - ...)
      value = value.replace(/[^0-9.]/g, "");

      // Giữ tối đa 1 dấu chấm
      let parts = value.split(".");
      if (parts.length > 2) {
        value = parts[0] + "." + parts[1];
      }

      // Giới hạn 1 chữ số thập phân
      if (parts[1]) {
        parts[1] = parts[1].slice(0, 1);
        value = parts[0] + "." + parts[1];
      }

      // Ép max = 5
      let num = parseFloat(value);
      if (!isNaN(num) && num > 5) {
        value = "5";
      }

      e.target.value = value;
    });
  });
});

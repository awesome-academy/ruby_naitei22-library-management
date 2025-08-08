document.addEventListener('turbo:load', function () {
  document.querySelectorAll('.dropdown-toggle').forEach(function (toggle) {
    toggle.addEventListener('click', function (event) {
      event.preventDefault();

      let menu = this.nextElementSibling;

      document.querySelectorAll('.dropdown-menu').forEach(function (otherMenu) {
        if (otherMenu !== menu) {
          otherMenu.classList.remove('active');
        }
      });

      menu.classList.toggle('active');
    });
  });

  document.addEventListener('click', function (event) {
    if (!event.target.closest('.dropdown')) {
      document.querySelectorAll('.dropdown-menu').forEach(function (menu) {
        menu.classList.remove('active');
      });
    }
  });
});

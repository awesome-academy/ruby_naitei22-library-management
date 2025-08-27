# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/custom", under: "custom"
pin "utils/time_display", to: "utils/time_display.js"
pin "modals/login_modal", to: "modals/login_modal.js"
pin "custom/hide_modal", to: "custom/hide_modal.js"
pin "custom/cart", to: "custom/cart.js"
pin "custom/write_review", to: "custom/write_review.js"
pin "custom/rating_custom_filter", to: "custom/rating_custom_filter.js"
pin "chartkick", to: "chartkick.js"
pin "Chart.bundle", to: "Chart.bundle.js"

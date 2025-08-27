// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import '@hotwired/turbo-rails';
import "Chart.bundle";
import "chartkick";
import 'controllers';
import "custom/cart";
import { hideModal } from "custom/hide_modal";
import 'custom/menu';
import "custom/rating_custom_filter";
import "custom/write_review";
import "modals/login_modal";
import "utils/time_display";
window.hideModal = hideModal

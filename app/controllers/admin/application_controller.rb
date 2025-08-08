class Admin::ApplicationController < ::ApplicationController
  before_action :logged_in_user
  before_action :admin_user

  private

  def logged_in_user
    return if logged_in?

    flash[:danger] = t("admin.books.flash.please_log_in")
    redirect_to login_url
  end

  def admin_user
    return if current_user&.admin?

    redirect_to root_url, alert: t("admin.books.flash.access_denied")
  end
end

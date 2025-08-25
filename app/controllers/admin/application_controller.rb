class Admin::ApplicationController < ::ApplicationController
  before_action :authenticate_user!
  before_action :admin_user

  private

  def admin_user
    return if current_user&.admin?

    redirect_to root_url, alert: t("admin.books.flash.access_denied")
  end
end

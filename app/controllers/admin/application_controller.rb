class Admin::ApplicationController < ::ApplicationController
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, alert: exception.message
  end

  load_and_authorize_resource
  before_action :logged_in_user

  private

  def logged_in_user
    return if logged_in?

    flash[:danger] = t("admin.books.flash.please_log_in")
    redirect_to root_path
  end
end

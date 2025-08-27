class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include SessionsHelper
  include Pagy::Backend
  before_action :set_locale

  private

  def set_locale
    allowed = I18n.available_locales.map(&:to_s)

    I18n.locale =
      if allowed.include?(params[:locale])
        params[:locale]
      else
        I18n.default_locale
      end
  end

  def default_url_options
    {locale: I18n.locale}
  end

  def logged_in_user
    return if logged_in?

    store_location
    flash[:danger] = t("auth.please_login")
    redirect_to new_user_session_path
  end
end

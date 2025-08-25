class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include Pagy::Backend
  before_action :set_locale
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i(name phone_number))
    devise_parameter_sanitizer.permit(
      :account_update,
      keys: %i(name phone_number)
    )
  end

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

  def after_sign_in_path_for resource
    if resource.admin?
      admin_report_path
    else
      stored_location_for(resource) || user_path(resource)
    end
  end
end

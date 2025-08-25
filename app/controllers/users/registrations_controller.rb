class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_permitted_parameters, only: %i(create)

  def self.controller_path
    "users"
  end

  # POST /users
  def create
    super do |resource|
      if resource.persisted? && !resource.confirmed?
        flash[:info] = t(".success")
      end
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up,
                                      keys: %i(name date_of_birth gender))
    devise_parameter_sanitizer.permit(:account_update,
                                      keys: %i(name date_of_birth gender))
  end
end

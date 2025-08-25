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

  # GET /users/sign_up/omniauth
  def new_with_omniauth
    omniauth_data = session[:omniauth_data] || {}
    @user = User.new(
      name: omniauth_data["name"],
      email: omniauth_data["email"]
    )
  end

  # POST /users/sign_up/omniauth
  def create_with_omniauth
    omniauth_data = session[:omniauth_data] || {}
    @user = User.new(
      user_params.merge(
        provider: omniauth_data["provider"],
        uid:      omniauth_data["uid"],
        email:    omniauth_data["email"]
      )
    )

    if @user.save
      session.delete(:omniauth_data)
      sign_in_and_redirect @user, event: :authentication
    else
      render :new_with_omniauth, status: :unprocessable_entity
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up,
                                      keys: %i(name date_of_birth gender))
    devise_parameter_sanitizer.permit(:account_update,
                                      keys: %i(name date_of_birth gender))
  end

  def user_params
    params.fetch(:user, {}).permit(:name, :password, :password_confirmation,
                                   :gender, :date_of_birth)
  end
end

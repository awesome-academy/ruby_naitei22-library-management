class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2 # rubocop:disable Metrics/AbcSize
    auth = request.env["omniauth.auth"]
    user = User.find_by(email: auth.info.email)

    if user.present?
      sign_in_and_redirect user, event: :authentication
    else
      session[:omniauth_data] = {
        provider: auth.provider,
        uid: auth.uid,
        email: auth.info.email,
        name: auth.info.name,
        image: auth.info.image
      }
      redirect_to new_user_registration_with_omniauth_path
    end
  end
end

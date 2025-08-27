module SessionsHelper
  def logged_in?
    user_signed_in?
  end

  def admin_user?
    current_user&.admin?
  end

  def current_user? user
    user == current_user
  end

  def redirect_back_or(default, **options)
    redirect_to(session[:forwarding_url] || default, **options)
    session.delete(:forwarding_url)
  end

  def store_location
    session[:forwarding_url] = request.original_url if request.get?
  end
end

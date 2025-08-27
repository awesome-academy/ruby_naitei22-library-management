class SessionsController < Devise::SessionsController
  def create
    borrow_cart = session[:borrow_cart]
    super
    session[:borrow_cart] = borrow_cart
  end

  def destroy
    borrow_cart = session[:borrow_cart]
    super
    session[:borrow_cart] = borrow_cart if borrow_cart.present?
  end

  def after_sign_in_path_for resource
    stored_location_for(resource) || super || session[:forwarding_url]
  end
end

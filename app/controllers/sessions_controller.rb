class SessionsController < Devise::SessionsController
  # POST /login
  def create
    super do |_user|
      flash[:success] = t("sessions.create.success") if user_signed_in?
    end
  end

  # DELETE /logout
  def destroy
    super do
      flash[:success] = t("sessions.destroy.success")
    end
  end

  protected

  def set_flash_message!(*args); end
end

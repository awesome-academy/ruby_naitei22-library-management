class Users::RegistrationsController < Devise::RegistrationsController
  # GET /users/sign_up
  def new
    @user = User.new
    render "users/new"
  end

  # POST /users
  def create
    @user = User.new(sign_up_params)
    if @user.save
      flash[:success] = t("users.create.confirmation_sent")
      redirect_to root_path
    else
      render "users/new"
    end
  end

  private

  def sign_up_params
    params.require(:user).permit(
      :name,
      :email,
      :password,
      :password_confirmation,
      :date_of_birth,
      :gender
    )
  end
end

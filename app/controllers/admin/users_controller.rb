# app/controllers/admin/users_controller.rb
class Admin::UsersController < Admin::ApplicationController
  before_action :set_user, only: [:show]

  # GET /admin/users
  def index
    @pagy, @users = pagy(User.where(role: :user).order_by_created)
  end

  # GET /admin/users/:id
  def show; end

  private

  def set_user
    @user = User.find_by(id: params[:id])
    return if @user

    flash[:alert] = t("admin.users.flash.not_found")
    redirect_to users_path
  end

  def user_params
    params.require(:user).permit(:name, :email, :role)
  end
end

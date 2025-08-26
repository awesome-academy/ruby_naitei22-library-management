class Admin::ApplicationController < ::ApplicationController
  before_action :authenticate_user!
  before_action :admin_user

  private

  def admin_user
    authorize! :access, :admin_panel
  end
end

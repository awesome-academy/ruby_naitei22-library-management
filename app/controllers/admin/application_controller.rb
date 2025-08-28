class Admin::ApplicationController < ::ApplicationController
  include Pagy::Backend

  before_action :authenticate_user!
  before_action :authorize_admin

  private

  def authorize_admin
    authorize! :access, :admin_panel
  end
end

require "rails_helper"

RSpec.describe Admin::UsersController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:admin) { create(:user, :admin) }
  let(:user) { create(:user) }

  before do
    sign_in admin
  end

  describe "GET #index" do
    it "renders index template" do
      get :index
      expect(response).to render_template(:index)
    end
  end

  describe "GET #show" do
    it "renders show template" do
      get :show, params: { id: user.id }
      expect(response).to render_template(:show)
    end
  end

  describe "PATCH #toggle_status" do
    it "toggles user status and redirects" do
      patch :toggle_status, params: { id: user.id }
      expect(response).to redirect_to(root_path)
    end
  end
end

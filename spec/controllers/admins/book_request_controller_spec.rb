require "rails_helper"

RSpec.describe Admin::BorrowRequestsController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:admin) { create(:user, :admin) }
  let(:user) { create(:user) }
  let(:book) { create(:book) }
  let(:borrow_request) { create(:borrow_request, user: user) }

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
      get :show, params: { id: borrow_request.id }
      expect(response).to render_template(:show)
    end
  end

  describe "GET #edit_status" do
    it "renders status_form partial" do
      get :edit_status, params: { id: borrow_request.id }
      expect(response).to render_template(partial: "_status_form")
    end
  end

  describe "PATCH #change_status" do
    it "changes status and redirects on success" do
      patch :change_status, params: { id: borrow_request.id, borrow_request: { status: "approved" } }
      expect(response).to redirect_to(admin_borrow_request_path(borrow_request))
    end
  end
end

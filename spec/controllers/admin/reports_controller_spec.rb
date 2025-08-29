require "rails_helper"

RSpec.describe Admin::ReportsController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:admin_user) { create(:user, :admin) }

  before { sign_in admin_user }

  describe "GET #show" do
    let!(:borrowed_requests) { create_list(:borrow_request, 3, :borrowed) }
    let!(:returned_requests) { create_list(:borrow_request, 2, :returned) }
    let!(:most_borrowed_books) { create_list(:book, 2) }

    before do
      allow(Book).to receive(:most_borrowed).and_return(Book.all)
    end

    it "assigns @borrow_vs_return_percent borrowed value" do
      get :show
      total = borrowed_requests.size + returned_requests.size
      expected_borrowed = (borrowed_requests.size.to_f / total * 100).round(2)
      expect(assigns(:borrow_vs_return_percent)[I18n.t("admin.reports.show.borrowed")]).to eq(expected_borrowed)
    end

    it "assigns @borrow_vs_return_percent returned value" do
      get :show
      total = borrowed_requests.size + returned_requests.size
      expected_returned = (returned_requests.size.to_f / total * 100).round(2)
      expect(assigns(:borrow_vs_return_percent)[I18n.t("admin.reports.show.returned")]).to eq(expected_returned)
    end

    it "paginates @most_borrowed_books" do
      pagy_double = double("pagy")
      allow(controller).to receive(:pagy).and_return([pagy_double, Book.all])
      get :show
      expect(assigns(:most_borrowed_books)).to eq(Book.all)
    end

    it "responds with success status" do
      get :show
      expect(response).to have_http_status(:success)
    end

    it "renders the show template" do
      get :show
      expect(response).to render_template(:show)
    end
  end

  describe "#percent" do
    it "returns 0 if total is zero" do
      expect(controller.send(:percent, 5, 0)).to eq(0)
    end

    it "calculates percent correctly" do
      expect(controller.send(:percent, 2, 5)).to eq(40.0)
    end
  end

  describe "#borrow_vs_return_percent" do
    it "calculates borrowed percent correctly" do
      create_list(:borrow_request, 2, :borrowed)
      create_list(:borrow_request, 3, :returned)
      result = controller.send(:borrow_vs_return_percent)
      expect(result[I18n.t("admin.reports.show.borrowed")]).to eq(40.0)
    end

    it "calculates returned percent correctly" do
      create_list(:borrow_request, 2, :borrowed)
      create_list(:borrow_request, 3, :returned)
      result = controller.send(:borrow_vs_return_percent)
      expect(result[I18n.t("admin.reports.show.returned")]).to eq(60.0)
    end
  end

  describe "#most_borrowed_books_scope" do
    it "calls Book.most_borrowed with params" do
      expect(Book).to receive(:most_borrowed).with(month: "8", year: "2025").and_return(Book.all)
      get :show, params: { month: "8", year: "2025" }
    end
  end
end

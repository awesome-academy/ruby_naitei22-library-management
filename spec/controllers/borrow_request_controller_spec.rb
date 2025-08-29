require "rails_helper"

RSpec.describe BorrowRequestController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }
  let(:book) { create(:book, available_quantity: 5) }

  before do
    sign_in user
    allow(controller).to receive(:logged_in_user).and_return(true)
    session[:user_id] = user.id
    session[:borrow_cart] = [{ "book_id" => book.id, "quantity" => 1, "selected" => true }]
    session[:start_date] = Date.today + 1
    session[:end_date] = Date.today + 2
  end

  describe "GET #index" do
    it "renders index template" do
      get :index, params: { page: 1 }
      expect(response).to render_template(:index)
    end
  end

  describe "PATCH #update_borrow_cart" do
    it "redirects to index with success flash" do
      patch :update_borrow_cart, params: { cart: { "0" => { quantity: 1, selected: "1" } } }
      expect(response).to redirect_to(borrow_request_index_path)
    end
  end

  describe "DELETE #remove_from_borrow_cart" do
    it "removes book and redirects" do
      delete :remove_from_borrow_cart, params: { book_id: book.id }
      expect(response).to redirect_to(borrow_request_index_path)
    end
  end

  describe "POST #checkout" do
    it "redirects to index with success flash" do
      post :checkout
      expect(response).to redirect_to(borrow_request_index_path)
    end
  end
end

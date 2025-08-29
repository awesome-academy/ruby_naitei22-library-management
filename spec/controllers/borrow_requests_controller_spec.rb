require "rails_helper"

RSpec.describe BorrowRequestController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }
  let(:book) { create(:book, available_quantity: 5) }

  before { sign_in user }

  describe "GET #index" do
    before do
      session[:borrow_cart] = [
        { "book_id" => book.id, "quantity" => 2, "selected" => true }
      ]
    end

    it "assigns cart item book" do
      get :index
      expect(assigns(:cart_items).first[:book]).to eq(book)
    end

    it "assigns a pagy object" do
      get :index, params: { page: 1 }
      expect(assigns(:pagy)).to be_a(Pagy)
    end

    it "redirects if page < 1" do
      get :index, params: { page: 0 }
      expect(response).to redirect_to(borrow_request_index_path(page: 1))
    end

    it "redirects if page > total_pages" do
      get :index, params: { page: 99 }
      expect(response).to redirect_to(borrow_request_index_path(page: 1))
    end
  end

  describe "PATCH #update_borrow_cart" do
    before do
      session[:borrow_cart] = [
        { "book_id" => book.id, "quantity" => 1, "selected" => false }
      ]
    end

    it "updates quantity in session" do
      patch :update_borrow_cart, params: { cart: { "0" => { "quantity" => 3, "selected" => "1" } } }
      expect(session[:borrow_cart].first["quantity"]).to eq(3)
    end

    it "updates selected in session" do
      patch :update_borrow_cart, params: { cart: { "0" => { "quantity" => 3, "selected" => "1" } } }
      expect(session[:borrow_cart].first["selected"]).to eq(true)
    end

    it "updates start_date in session" do
      patch :update_borrow_cart, params: { start_date: Date.today.to_s }
      expect(session[:start_date]).to eq(Date.today)
    end

    it "updates end_date in session" do
      patch :update_borrow_cart, params: { end_date: (Date.today + 5).to_s }
      expect(session[:end_date]).to eq(Date.today + 5)
    end

    it "handles invalid start_date format" do
      patch :update_borrow_cart, params: { start_date: "bad" }
      expect(flash[:danger]).to eq(I18n.t("borrow_request.update_borrow_cart.invalid_start_date_format"))
    end

    it "redirects on invalid start_date" do
      patch :update_borrow_cart, params: { start_date: "bad" }
      expect(response).to redirect_to(borrow_request_index_path)
    end

    it "handles invalid end_date format" do
      patch :update_borrow_cart, params: { end_date: "bad" }
      expect(flash[:danger]).to eq(I18n.t("borrow_request.update_borrow_cart.invalid_end_date_format"))
    end

    it "redirects on invalid end_date" do
      patch :update_borrow_cart, params: { end_date: "bad" }
      expect(response).to redirect_to(borrow_request_index_path)
    end
  end

  describe "DELETE #remove_from_borrow_cart" do
    before do
      session[:borrow_cart] = [
        { "book_id" => book.id, "quantity" => 1, "selected" => true }
      ]
    end

    it "removes item from cart (HTML)" do
      delete :remove_from_borrow_cart, params: { book_id: book.id }
      expect(session[:borrow_cart]).to be_empty
    end

    it "sets success flash (HTML)" do
      delete :remove_from_borrow_cart, params: { book_id: book.id }
      expect(flash[:success]).to eq(I18n.t("borrow_request.remove_from_borrow_cart.remove_success"))
    end

    it "returns JSON success" do
      delete :remove_from_borrow_cart, params: { book_id: book.id }, format: :json
      body = JSON.parse(response.body)
      expect(body["success"]).to eq(true)
    end

    it "returns book_id in JSON response" do
      delete :remove_from_borrow_cart, params: { book_id: book.id }, format: :json
      body = JSON.parse(response.body)
      expect(body["book_id"]).to eq(book.id)
    end

    it "handles book not in cart (HTML) flash" do
      delete :remove_from_borrow_cart, params: { book_id: 999 }
      expect(flash[:danger]).to eq(I18n.t("borrow_request.remove_from_borrow_cart.book_not_in_cart"))
    end

    it "handles book not in cart (HTML) redirect" do
      delete :remove_from_borrow_cart, params: { book_id: 999 }
      expect(response).to redirect_to(borrow_request_index_path)
    end

    it "handles book not in cart (JSON) success false" do
      delete :remove_from_borrow_cart, params: { book_id: 999 }, format: :json
      body = JSON.parse(response.body)
      expect(body["success"]).to eq(false)
    end

    it "handles book not in cart (JSON) message" do
      delete :remove_from_borrow_cart, params: { book_id: 999 }, format: :json
      body = JSON.parse(response.body)
      expect(body["message"]).to eq(I18n.t("borrow_request.remove_from_borrow_cart.book_not_in_cart"))
    end
  end

  describe "POST #checkout" do
    before do
      session[:borrow_cart] = [
        { "book_id" => book.id, "quantity" => 2, "selected" => true }
      ]
      session[:start_date] = Date.today + 1
      session[:end_date] = Date.today + 3
    end

    it "creates BorrowRequest" do
      expect { post :checkout }.to change(BorrowRequest, :count).by(1)
    end

    it "creates BorrowRequestItem" do
      expect { post :checkout }.to change(BorrowRequestItem, :count).by(1)
    end

    it "clears borrow_cart after checkout" do
      post :checkout
      expect(session[:borrow_cart]).to be_empty
    end

    it "clears start_date after checkout" do
      post :checkout
      expect(session[:start_date]).to be_nil
    end

    it "clears end_date after checkout" do
      post :checkout
      expect(session[:end_date]).to be_nil
    end

    it "sets success flash after checkout" do
      post :checkout
      expect(flash[:success]).to eq(I18n.t("borrow_request.checkout.checkout_success"))
    end

    it "fails when no book selected" do
      session[:borrow_cart].first["selected"] = false
      post :checkout
      expect(flash[:danger]).to eq(I18n.t("borrow_request.checkout.no_books_selected"))
    end

    it "fails with nil start_date" do
      session[:start_date] = nil
      post :checkout
      expect(flash[:danger]).to eq(I18n.t("borrow_request.checkout.invalid_start_date_format"))
    end

    it "fails with nil end_date" do
      session[:end_date] = nil
      post :checkout
      expect(flash[:danger]).to eq(I18n.t("borrow_request.checkout.invalid_end_date_format"))
    end

    it "fails when start_date < today" do
      session[:start_date] = Date.today - 1
      post :checkout
      expect(flash[:danger]).to eq(I18n.t("borrow_request.checkout.invalid_start_date"))
    end

    it "fails when end_date <= start_date" do
      session[:end_date] = session[:start_date]
      post :checkout
      expect(flash[:danger]).to eq(I18n.t("borrow_request.checkout.invalid_end_date"))
    end

    it "fails when quantity exceeds available_quantity" do
      book.update!(available_quantity: 1)
      post :checkout
      expect(flash[:error]).to include(book.title)
    end

    it "handles ActiveRecord::RecordInvalid" do
      allow(BorrowRequest).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(BorrowRequest.new))
      post :checkout
      expect(flash[:danger]).to match(I18n.t("borrow_request.checkout.checkout_failed"))
    end
  end
end

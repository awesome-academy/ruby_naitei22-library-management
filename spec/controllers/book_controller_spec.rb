require "rails_helper"

RSpec.describe BooksController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:author) { create(:author) }
  let(:publisher) { create(:publisher) }
  let(:book) { create(:book, author: author, publisher: publisher) }
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe "GET #show" do
    it "renders show template" do
      get :show, params: { id: book.id }
      expect(response).to render_template(:show)
    end
  end

  describe "GET #search" do
    it "renders search template" do
      get :search, params: { q: "Test" }
      expect(response).to render_template(:search)
    end
  end

  it "redirects to book path" do
    post :borrow, params: { id: book.id, quantity: 1 }
    expect(response).to redirect_to(/\/books\/#{book.id}/)
  end

  describe "POST #add_to_favorite" do
    it "redirects to book path" do
      post :add_to_favorite, params: { id: book.id }
      expect(response).to redirect_to(book_path(book))
    end
  end

  describe "DELETE #remove_from_favorite" do
    it "redirects to book path" do
      delete :remove_from_favorite, params: { id: book.id }
      expect(response).to redirect_to(book_path(book))
    end
  end

  describe "POST #write_a_review" do
    it "redirects to book path" do
      post :write_a_review, params: { id: book.id, review: { score: 5, comment: "Great!" } }
      expect(response).to redirect_to(book_path(book))
    end
  end

  describe "DELETE #destroy_review" do
    it "redirects to book path" do
      review = create(:review, book: book, user: user)
      delete :destroy_review, params: { id: book.id }
      expect(response).to redirect_to(book_path(book))
    end
  end
end

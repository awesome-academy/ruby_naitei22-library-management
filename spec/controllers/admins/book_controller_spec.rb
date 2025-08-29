require "rails_helper"

RSpec.describe Admin::BooksController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:admin) { create(:user, :admin) }
  let(:author) { create(:author) }
  let(:publisher) { create(:publisher) }
  let(:book) { create(:book, author: author, publisher: publisher) }
  let(:valid_attributes) do
    {
      title: "Test Book",
      description: "A book for testing.",
      publication_year: 2001,
      total_quantity: 10,
      available_quantity: 5,
      author_id: author.id,
      publisher_id: publisher.id
    }
  end

  let(:invalid_attributes) do
    {
      title: "",
      author_id: nil,
      publisher_id: nil
    }
  end

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
      get :show, params: { id: book.id }
      expect(response).to render_template(:show)
    end
  end

  describe "GET #new" do
    it "renders new template" do
      get :new
      expect(response).to render_template(:new)
    end
  end

  describe "POST #create" do
    it "creates book and redirects on success" do
      post :create, params: { book: valid_attributes }
      expect(response).to redirect_to(admin_books_path)
    end

    it "renders new on failure" do
      post :create, params: { book: invalid_attributes }
      expect(response).to render_template(:new)
    end
  end

  describe "GET #edit" do
    it "renders edit template" do
      get :edit, params: { id: book.id }
      expect(response).to render_template(:edit)
    end
  end

  describe "PATCH #update" do
    it "updates book and redirects on success" do
      patch :update, params: { id: book.id, book: valid_attributes }
      expect(response).to redirect_to(admin_book_path(book))
    end

    it "renders edit on failure" do
      patch :update, params: { id: book.id, book: invalid_attributes }
      expect(response).to render_template(:edit)
    end
  end

  describe "DELETE #destroy" do
    it "destroys book and redirects" do
      book_to_destroy = create(:book, author: author, publisher: publisher)
      delete :destroy, params: { id: book_to_destroy.id }
      expect(response).to redirect_to(admin_books_path)
    end
  end
end

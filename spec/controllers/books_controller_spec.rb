require "rails_helper"

RSpec.describe BooksController, type: :controller do
  let!(:publisher) { Publisher.where(name: "Publisher").first_or_create! }
  let!(:author)    { Author.where(name: "Author").first_or_create! }

  let!(:book) do
    Book.create!(
      title: "Book",
      total_quantity: 1,
      available_quantity: 1,
      author: author,
      publisher: publisher,
      borrow_count: 0,
      created_at: 2.days.ago,
      publication_year: 2000
    )
  end

  let!(:another_book) do
    Book.create!(
      title: "Another Book",
      total_quantity: 1,
      available_quantity: 1,
      author: author,
      publisher: publisher,
      borrow_count: 0,
      created_at: 2.days.ago,
      publication_year: 2000
    )
  end

  let!(:user) do
    User.create!(
      name: "Test User",
      email: "user@test.com",
      password: "123456",
      gender: "male",
      date_of_birth: "2000-01-01"
    )
  end

  before { allow(controller).to receive(:current_user).and_return(user) }

  describe "GET #show" do
    context "when book exists (HTML)" do
      it "assigns @book" do
        get :show, params: { id: book.id }
        expect(assigns(:book)).to eq(book)
      end

      it "renders :show" do
        get :show, params: { id: book.id }
        expect(response).to render_template(:show)
      end
    end

    context "when book does not exist (HTML)" do
      before { get :show, params: { id: -1 } }

      it "redirects to root_path" do
        expect(response).to redirect_to(root_path)
      end

      it "sets flash alert" do
        expect(flash[:alert]).to eq(I18n.t("books.show.book_not_found"))
      end
    end

    context "Turbo Stream format" do
      it "renders partial reviews" do
        get :show, params: { id: book.id }, format: :turbo_stream
        expect(response.body).to include("reviews")
      end

      it "returns http ok" do
        get :show, params: { id: book.id }, format: :turbo_stream
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET #search" do
    it "finds books by title" do
      get :search, params: { q: "Book", search_type: "title" }
      expect(assigns(:books)).to include(book, another_book)
    end

    it "returns all books if query is empty" do
      get :search, params: { q: "", search_type: "all" }
      expect(assigns(:books)).to include(book, another_book)
    end

    it "normalizes invalid search_type to all" do
      get :search, params: { q: "Book", search_type: "invalid_type" }
      expect(assigns(:books)).to include(book, another_book)
    end
  end

  describe "POST #borrow" do
    context "HTML format" do
      it "stores correct book_id in borrow_cart" do
        post :borrow, params: { id: book.id, quantity: 2 }
        expect(session[:borrow_cart].first["book_id"]).to eq(book.id)
      end

      it "stores correct quantity in borrow_cart" do
        post :borrow, params: { id: book.id, quantity: 2 }
        expect(session[:borrow_cart].first["quantity"]).to eq(2)
      end

      it "sets flash success" do
        post :borrow, params: { id: book.id, quantity: 2 }
        expect(flash[:success]).to eq(I18n.t("books.borrow.added_to_borrow_cart"))
      end

      it "redirects to book show" do
        post :borrow, params: { id: book.id, quantity: 2 }
        expect(response).to redirect_to(book_path(book))
      end

      it "increments quantity if book already in cart" do
        session[:borrow_cart] = [{ "book_id" => book.id, "quantity" => 1 }]
        post :borrow, params: { id: book.id, quantity: 3 }
        expect(session[:borrow_cart].first["quantity"]).to eq(4)
      end
    end

    context "Turbo Stream format" do
      it "stores correct book_id in borrow_cart" do
        post :borrow, params: { id: book.id, quantity: 2 }, format: :turbo_stream
        expect(session[:borrow_cart].first["book_id"]).to eq(book.id)
      end

      it "stores correct quantity in borrow_cart" do
        post :borrow, params: { id: book.id, quantity: 2 }, format: :turbo_stream
        expect(session[:borrow_cart].first["quantity"]).to eq(2)
      end

      it "returns http ok" do
        post :borrow, params: { id: book.id, quantity: 2 }, format: :turbo_stream
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST #add_to_favorite" do
    context "HTML format" do
      it "creates favorite with correct user" do
        post :add_to_favorite, params: { id: book.id }
        expect(Favorite.last.user).to eq(user)
      end

      it "creates favorite with correct book" do
        post :add_to_favorite, params: { id: book.id }
        expect(Favorite.last.favorable).to eq(book)
      end

      it "redirects to book show" do
        post :add_to_favorite, params: { id: book.id }
        expect(response).to redirect_to(book_path(book))
      end

      it "sets flash alert if save fails" do
        allow_any_instance_of(Favorite).to receive(:save).and_return(false)
        post :add_to_favorite, params: { id: book.id }
        expect(flash[:alert]).to eq(I18n.t("books.add_to_favorite.favorite_failed"))
      end
    end

    context "Turbo Stream format" do
      it "renders turbo_stream with favorite_button" do
        post :add_to_favorite, params: { id: book.id }, format: :turbo_stream
        expect(response.body).to include("favorite_button")
      end
    end
  end

  describe "DELETE #remove_from_favorite" do
    before { @favorite = Favorite.create!(user: user, favorable: book) }

    context "HTML format" do
      it "removes favorite from DB" do
        expect {
          delete :remove_from_favorite, params: { id: book.id }
        }.to change(Favorite, :count).by(-1)
      end

      it "redirects to book show" do
        delete :remove_from_favorite, params: { id: book.id }
        expect(response).to redirect_to(book_path(book))
      end

      it "sets flash alert if favorite not found" do
        @favorite.destroy
        delete :remove_from_favorite, params: { id: book.id }
        expect(flash[:alert]).to eq(I18n.t("books.remove_from_favorite.favorite_not_found"))
      end

      it "sets flash alert if destroy fails" do
        allow_any_instance_of(Favorite).to receive(:destroy).and_return(false)
        delete :remove_from_favorite, params: { id: book.id }
        expect(flash[:alert]).to eq(I18n.t("books.remove_from_favorite.unfavorite_failed"))
      end
    end

    context "Turbo Stream format" do
      it "renders turbo_stream with favorite_button" do
        delete :remove_from_favorite, params: { id: book.id }, format: :turbo_stream
        expect(response.body).to include("favorite_button")
      end
    end
  end

  describe "POST #write_a_review" do
    it "creates review with correct user" do
      post :write_a_review, params: { id: book.id, review: { score: 5, comment: "Great!" } }
      expect(Review.last.user).to eq(user)
    end

    it "creates review with correct book" do
      post :write_a_review, params: { id: book.id, review: { score: 5, comment: "Great!" } }
      expect(Review.last.book).to eq(book)
    end

    it "creates review with correct score" do
      post :write_a_review, params: { id: book.id, review: { score: 5, comment: "Great!" } }
      expect(Review.last.score).to eq(5)
    end

    it "creates review with correct comment" do
      post :write_a_review, params: { id: book.id, review: { score: 5, comment: "Great!" } }
      expect(Review.last.comment).to eq("Great!")
    end

    it "renders review_section on invalid review (Turbo Stream)" do
      post :write_a_review, params: { id: book.id, review: { score: 10, comment: "" } }, format: :turbo_stream
      expect(response.body).to include("review_section")
    end

    it "renders show on invalid review (HTML)" do
      post :write_a_review, params: { id: book.id, review: { score: 10, comment: "" } }, format: :html
      expect(response).to render_template(:show)
    end
  end

  describe "DELETE #destroy_review" do
    before { @review = Review.create!(book: book, user: user, score: 4, comment: "Good") }

    it "destroys review from DB" do
      expect {
        delete :destroy_review, params: { id: book.id }
      }.to change(Review, :count).by(-1)
    end

    it "returns 422 if destroy fails (Turbo Stream)" do
      allow_any_instance_of(Review).to receive(:destroy).and_return(false)
      delete :destroy_review, params: { id: book.id }, format: :turbo_stream
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "sets flash alert if destroy fails (HTML)" do
      allow_any_instance_of(Review).to receive(:destroy).and_return(false)
      delete :destroy_review, params: { id: book.id }, format: :html
      expect(flash[:alert]).to eq(I18n.t("books.destroy_review.delete_failed"))
    end
  end

  describe "private methods" do
    it "normalize_search_type returns valid type" do
      expect(controller.send(:normalize_search_type, "title")).to eq(:title)
    end

    it "normalize_search_type defaults invalid type to :all" do
      expect(controller.send(:normalize_search_type, "invalid")).to eq(:all)
    end

    it "review_params permits score and comment" do
      allow(controller).to receive(:params).and_return(
        ActionController::Parameters.new(review: { score: 5, comment: "Good" })
      )
      expect(controller.send(:review_params)).to eq({ "score" => 5, "comment" => "Good" })
    end
  end
end

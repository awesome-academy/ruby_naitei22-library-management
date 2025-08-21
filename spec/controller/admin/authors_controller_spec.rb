require "rails_helper"

RSpec.describe Admin::AuthorsController, type: :controller do
  routes { Rails.application.routes }

  let!(:author) { Author.create!(name: "Nam Cao") }
  let(:admin) do
    User.create!(
      name: "Admin",
      email: "admin@example.com",
      password: "123456",
      role: "admin",
      gender: "male",
      date_of_birth: Date.new(1990,1,1)
    )
  end
  let(:publisher) { Publisher.create!(name: "NXB ABC") }

  before do
    session[:user_id] = admin.id
  end

  describe "GET #index" do
    before { get :index }

    it "assigns authors including the created author" do
      expect(assigns(:authors)).to include(author)
    end

    it "renders the index template" do
      expect(response).to render_template(:index)
    end

    it "returns HTTP status ok" do
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET #show" do
    context "when author exists" do
      before { get :show, params: { id: author.id } }

      it "assigns the requested author" do
        expect(assigns(:author)).to eq(author)
      end

      it "renders the show template" do
        expect(response).to render_template(:show)
      end
    end

    context "when author does not exist" do
      before { get :show, params: { id: -1 } }

      it "redirects to authors index" do
        expect(response).to redirect_to(admin_authors_path)
      end

      it "sets flash alert" do
        expect(flash[:alert]).to eq(I18n.t("admin.authors.flash.not_found"))
      end
    end
  end

  describe "GET #new" do
    before { get :new }

    it "assigns a new Author instance" do
      expect(assigns(:author)).to be_a_new(Author)
    end

    it "renders the new template" do
      expect(response).to render_template(:new)
    end
  end


  describe "POST #create" do
    context "with valid params" do
      let(:valid_params) { { author: { name: "Nguyễn Du" } } }

      it "creates a new author" do
        expect {
          post :create, params: valid_params
        }.to change(Author, :count).by(1)
      end

      it "persists the author with correct data" do
        post :create, params: valid_params
        created_author = Author.last
        expect(created_author.name).to eq("Nguyễn Du")
      end

      it "redirects to authors index" do
        post :create, params: valid_params
        expect(response).to redirect_to(admin_authors_path)
      end

      it "sets flash success" do
        post :create, params: valid_params
        expect(flash[:success]).to eq(I18n.t("admin.authors.flash.create.success"))
      end
    end

    context "with invalid params" do
      it "does not create a new author" do
        expect {
          post :create, params: { author: { name: "" } }
        }.not_to change(Author, :count)
      end

      it "re-renders the new template" do
        post :create, params: { author: { name: "" } }
        expect(response).to render_template(:new)
      end

      it "returns HTTP status unprocessable entity" do
        post :create, params: { author: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "sets flash alert" do
        post :create, params: { author: { name: "" } }
        expect(flash[:alert]).to eq(I18n.t("admin.authors.flash.create.failure"))
      end
    end
  end

  describe "GET #edit" do
    before { get :edit, params: { id: author.id } }

    it "assigns the requested author" do
      expect(assigns(:author)).to eq(author)
    end

    it "renders the edit template" do
      expect(response).to render_template(:edit)
    end
  end

  describe "PATCH #update" do
    context "with valid params" do
      let(:update_params) { { id: author.id, author: { name: "Tô Hoài" } } }

      before { patch :update, params: update_params }

      it "updates the author name" do
        expect(author.reload.name).to eq("Tô Hoài")
      end
      
      it "updates the author with correct data" do
        updated_author = author.reload
        expect(updated_author.name).to eq("Tô Hoài")
      end

      it "redirects to the author show page" do
        expect(response).to redirect_to(admin_author_path(author))
      end

      it "sets flash success" do
        expect(flash[:success]).to eq(I18n.t("admin.authors.flash.update.success"))
      end
    end

    context "with invalid params" do
      before { patch :update, params: { id: author.id, author: { name: "" } } }

      it "re-renders the edit template" do
        expect(response).to render_template(:edit)
      end

      it "returns HTTP status unprocessable entity" do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "sets flash alert" do
        expect(flash[:alert]).to eq(I18n.t("admin.authors.flash.update.failure"))
      end
    end
  end


  describe "DELETE #destroy" do
    context "when author has no books" do
      let!(:author_without_books) { Author.create!(name: "Solo Author") }

      it "deletes the author" do
        expect {
          delete :destroy, params: { id: author_without_books.id }
        }.to change(Author, :count).by(-1)
      end

      it "redirects to authors index" do
        delete :destroy, params: { id: author_without_books.id }
        expect(response).to redirect_to(admin_authors_path)
      end

      it "sets flash success" do
        delete :destroy, params: { id: author_without_books.id }
        expect(flash[:success]).to eq(I18n.t("admin.authors.flash.destroy.success"))
      end
    end

    context "when author has associated books" do
      let!(:author_with_books) { Author.create!(name: "Linked Author") }
      let!(:book) do
        Book.create!(
          title: "Linked Book",
          author: author_with_books,
          publisher: publisher,
          total_quantity: 5
        )
      end

      it "does not delete the author" do
        expect {
          delete :destroy, params: { id: author_with_books.id }
        }.not_to change(Author, :count)
      end

      it "redirects to authors index" do
        delete :destroy, params: { id: author_with_books.id }
        expect(response).to redirect_to(admin_authors_path)
      end

      it "sets flash alert to has_books" do
        delete :destroy, params: { id: author_with_books.id }
        expect(flash[:alert]).to eq(I18n.t("admin.authors.flash.destroy.has_books"))
      end
    end

    context "when destroy fails due to other reasons" do
      let!(:author_invalid) { Author.create!(name: "Buggy Author") }

      before do
        allow_any_instance_of(Author).to receive(:destroy).and_return(false)
        allow_any_instance_of(Author).to receive(:errors).and_return(ActiveModel::Errors.new(Author.new))
      end

      it "redirects to authors index" do
        delete :destroy, params: { id: author_invalid.id }
        expect(response).to redirect_to(admin_authors_path)
      end

      it "sets flash alert to failure" do
        delete :destroy, params: { id: author_invalid.id }
        expect(flash[:alert]).to eq(I18n.t("admin.authors.flash.destroy.failure"))
      end
    end
  end
end

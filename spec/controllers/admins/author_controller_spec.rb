require "rails_helper"

RSpec.describe Admin::AuthorsController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:admin) { create(:user, :admin) }
  let(:author) { create(:author) }
  let(:valid_attributes) do
    {
      name: "Test Author",
      bio: "Bio",
      birth_date: 50.years.ago.to_date,
      nationality: "Testland"
    }
  end

  let(:invalid_attributes) do
    {
      name: "",
      birth_date: Date.current + 1.day
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
      get :show, params: { id: author.id }
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
    it "creates author and redirects on success" do
      post :create, params: { author: valid_attributes }
      expect(response).to redirect_to(admin_authors_path)
    end

    it "renders new on failure" do
      post :create, params: { author: invalid_attributes }
      expect(response).to render_template(:new)
    end
  end

  describe "GET #edit" do
    it "renders edit template" do
      get :edit, params: { id: author.id }
      expect(response).to render_template(:edit)
    end
  end

  describe "PATCH #update" do
    it "updates author and redirects on success" do
      patch :update, params: { id: author.id, author: valid_attributes }
      expect(response).to redirect_to(admin_author_path(author))
    end

    it "renders edit on failure" do
      patch :update, params: { id: author.id, author: invalid_attributes }
      expect(response).to render_template(:edit)
    end
  end

  describe "DELETE #destroy" do
    it "destroys author and redirects" do
      author_to_destroy = create(:author)
      delete :destroy, params: { id: author_to_destroy.id }
      expect(response).to redirect_to(admin_authors_path)
    end
  end
end

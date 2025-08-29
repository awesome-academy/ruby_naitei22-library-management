require "rails_helper"

RSpec.describe UsersController, type: :controller do
  include Devise::Test::ControllerHelpers
  include SessionsHelper

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:oauth_user) { create(:user, :oauth_user) }
  let(:valid_attributes) do
    {
      name: "John Doe",
      email: "john@example.com",
      password: "password123",
      password_confirmation: "password123",
      gender: :male,
      date_of_birth: 25.years.ago.to_date
    }
  end


  describe "GET #show" do
    it "renders show template" do
      sign_in user
      get :show, params: { id: user.id }
      expect(response).to render_template(:show)
    end
  end

  describe "GET #edit" do
    it "renders edit template" do
      sign_in user
      get :edit, params: { id: user.id }
      expect(response).to render_template(:edit)
    end
  end

  describe "PATCH #update" do
    it "updates user and redirects on success" do
      sign_in user
      patch :update, params: { id: user.id, user: { name: "Jane Doe" } }
      expect(response).to redirect_to(user)
    end

    it "renders edit on failure" do
      sign_in user
      patch :update, params: { id: user.id, user: { email: "" } }
      expect(response).to render_template(:edit)
    end
  end

  describe "GET #favorites" do
    it "renders favorites template" do
      sign_in user
      get :favorites, params: { id: user.id }
      expect(response).to render_template(:favorites)
    end
  end

  describe "GET #follows" do
    it "renders follows template" do
      sign_in user
      get :follows, params: { id: user.id }
      expect(response).to render_template(:follows)
    end
  end
end

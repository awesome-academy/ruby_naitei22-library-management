require "rails_helper"

RSpec.describe UsersController, type: :controller do
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

  describe "GET #new" do
    it "returns a success response" do
      get :new
      expect(response).to be_successful
    end

    it "assigns a new user" do
      get :new
      expect(assigns(:user)).to be_a_new(User)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a user with correct name" do
        allow_any_instance_of(User).to receive(:send_activation_email).and_return(true)
        post :create, params: { user: valid_attributes }
        created_user = assigns(:user)
        expect(created_user.name).to eq("John Doe")
      end

      it "creates a user with correct email" do
        allow_any_instance_of(User).to receive(:send_activation_email).and_return(true)
        post :create, params: { user: valid_attributes }
        created_user = assigns(:user)
        expect(created_user.email).to eq("john@example.com")
      end

      it "creates a user with correct gender" do
        allow_any_instance_of(User).to receive(:send_activation_email).and_return(true)
        post :create, params: { user: valid_attributes }
        created_user = assigns(:user)
        expect(created_user.gender).to eq("male")
      end

      it "creates a user with correct date_of_birth" do
        allow_any_instance_of(User).to receive(:send_activation_email).and_return(true)
        post :create, params: { user: valid_attributes }
        created_user = assigns(:user)
        expect(created_user.date_of_birth).to eq(25.years.ago.to_date)
      end
      it "assigns the current user" do
        allow_any_instance_of(User).to receive(:send_activation_email).and_return(true)
        post :create, params: { user: valid_attributes }
        expect(assigns(:user)).to be_a(User)
      end
      it "assigns a new user instance" do
        allow_any_instance_of(User).to receive(:send_activation_email).and_return(true)
        post :create, params: { user: valid_attributes }
        expect(assigns(:user)).to be_persisted
      end

      it "creates a new User" do
        allow_any_instance_of(User).to receive(:send_activation_email).and_return(true)

        expect {
          post :create, params: { user: valid_attributes }
        }.to change(User, :count).by(1)
      end

      it "redirects to root path" do
        allow_any_instance_of(User).to receive(:send_activation_email).and_return(true)

        post :create, params: { user: valid_attributes }
        expect(response).to redirect_to(root_path)
      end

      it "sets info flash message" do
        allow_any_instance_of(User).to receive(:send_activation_email).and_return(true)

        post :create, params: { user: valid_attributes }
        expect(flash[:info]).to eq(I18n.t("users.check_email"))
      end

      it "sets danger flash on email sending error" do
        allow_any_instance_of(User).to receive(:send_activation_email).and_raise(StandardError)

        post :create, params: { user: valid_attributes }
        expect(flash.now[:danger]).to eq(I18n.t("users.email_error"))
      end

      it "redirects to root on email sending error" do
        allow_any_instance_of(User).to receive(:send_activation_email).and_raise(StandardError)

        post :create, params: { user: valid_attributes }
        expect(response).to redirect_to(root_path)
      end
    end

    context "with invalid params" do
      it "assigns the current user" do
        post :create, params: { user: { name: "" } }
        expect(assigns(:user)).to be_a(User)
      end
      it "assigns an invalid user instance" do
        post :create, params: { user: { name: "" } }
        expect(assigns(:user)).not_to be_persisted
      end
      it "returns unprocessable entity status" do
        post :create, params: { user: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "sets danger flash message" do
        post :create, params: { user: { name: "" } }
        expect(flash.now[:danger]).to eq(I18n.t("users.create.error"))
      end
    end
  end

  describe "GET #show" do
    context "when logged in" do
      before { log_in_as(user) }

      it "assigns the requested user" do
        get :show, params: { id: user.id }
        expect(assigns(:user)).to eq(user)
      end
      it "returns a success response" do
        get :show, params: { id: user.id }
        expect(response).to be_successful
      end

      it "redirects when user not found" do
        get :show, params: { id: 999999 }
        expect(response).to redirect_to(root_path)
      end

      it "sets warning flash when user not found" do
        get :show, params: { id: -1 }
        expect(flash[:warning]).to eq(I18n.t("users.show.not_found"))
      end
    end

    context "when not logged in" do
      it "redirects to login" do
        get :show, params: { id: user.id }
        expect(response).to redirect_to(login_url)
      end
    end

    context "when accessing other user's profile" do
      before { log_in_as(other_user) }

      it "redirects to root" do
        get :show, params: { id: user.id }
        expect(response).to redirect_to(root_url)
      end

      it "sets error flash message" do
        get :show, params: { id: user.id }
        expect(flash[:error]).to eq(I18n.t("users.not_correct_user"))
      end
    end
  end

  describe "GET #edit" do
    before { log_in_as(user) }

    it "returns a success response" do
      get :edit, params: { id: user.id }
      expect(response).to be_successful
    end

    it "assigns the correct user" do
      get :edit, params: { id: user.id }
      expect(assigns(:user)).to eq(user)
    end
  end

  describe "PATCH #update" do
    before { log_in_as(user) }

    context "with valid params" do
      let(:new_attributes) { { name: "Updated Name" } }

      it "updates user name correctly" do
        patch :update, params: { id: user.id, user: { name: "New Name" } }
        updated_user = assigns(:user)
        expect(updated_user.name).to eq("New Name")
      end

      it "updates user email correctly" do
        patch :update, params: { id: user.id, user: { email: "new@example.com" } }
        updated_user = assigns(:user)
        expect(updated_user.email).to eq("new@example.com")
      end

      it "updates user gender correctly" do
        patch :update, params: { id: user.id, user: { gender: "female" } }
        updated_user = assigns(:user)
        expect(updated_user.gender).to eq("female")
      end

      it "assigns the current user" do
        patch :update, params: { id: user.id, user: { name: "Updated Name" } }
        expect(assigns(:user)).to eq(user)
      end

      it "updates the user name" do
        patch :update, params: { id: user.id, user: new_attributes }
        user.reload
        expect(user.name).to eq("Updated Name")
      end

      it "redirects to user page" do
        patch :update, params: { id: user.id, user: new_attributes }
        expect(response).to redirect_to(user)
      end

      it "sets success flash message" do
        patch :update, params: { id: user.id, user: new_attributes }
        expect(flash[:success]).to eq(I18n.t("users.update.profile_updated_successfully"))
      end

      it "removes blank password fields and redirects" do
        update_params = {
          name: "Updated Name",
          password: "",
          password_confirmation: ""
        }

        patch :update, params: { id: user.id, user: update_params }
        expect(response).to redirect_to(user)
      end
    end

    context "with invalid params" do
      it "assigns the current user" do
        patch :update, params: { id: user.id, user: { name: "" } }
        expect(assigns(:user)).to eq(user)
      end

      it "assigns the current user with errors" do
        patch :update, params: { id: user.id, user: { name: "" } }
        expect(assigns(:user).errors).not_to be_empty
      end
      it "returns unprocessable entity status" do
        patch :update, params: { id: user.id, user: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET #favorites" do
    before { log_in_as(user) }

    it "assigns the requested user" do
      get :favorites, params: { id: user.id }
      expect(assigns(:user)).to eq(user)
    end

    it "assigns favorite books" do
      get :favorites, params: { id: user.id }
      expect(assigns(:favorite_books)).to be_a(ActiveRecord::Relation)
    end

    it "returns a success response" do
      get :favorites, params: { id: user.id }
      expect(response).to be_successful
    end

    it "assigns favorite stats" do
      get :favorites, params: { id: user.id }
      expect(assigns(:favorite_stats)).to be_present
    end
  end

  describe "GET #follows" do
    before { log_in_as(user) }

    it "assigns the requested user" do
      get :follows, params: { id: user.id }
      expect(assigns(:user)).to eq(user)
    end

    it "assigns followed authors" do
      get :follows, params: { id: user.id }
      expect(assigns(:favorite_authors)).to be_a(ActiveRecord::Relation)
    end

    it "returns a success response" do
      get :follows, params: { id: user.id }
      expect(response).to be_successful
    end

    it "assigns author stats" do
      get :follows, params: { id: user.id }
      expect(assigns(:author_stats)).to be_present
    end
  end

  describe "GET #setup_password" do
    before { log_in_as(oauth_user) }

    it "returns a success response for oauth users" do
      get :setup_password
      expect(response).to be_successful
    end

    it "assigns the correct user" do
      get :setup_password
      expect(assigns(:user)).to eq(oauth_user)
    end

    context "when not an oauth user" do
      before { log_in_as(user) }

      it "redirects to root" do
        get :setup_password
        expect(response).to redirect_to(root_path)
      end

      it "sets danger flash message" do
        get :setup_password
        expect(flash[:danger]).to eq(I18n.t("users.require_password_setup"))
      end
    end
  end

  describe "PATCH #update_password" do
    before { log_in_as(oauth_user) }

    context "with valid params" do
      let(:password_params) do
        {
          password: "newpassword123",
          password_confirmation: "newpassword123"
        }
      end

      it "updates user password correctly" do
        patch :update_password, params: {
          id: oauth_user.id,
          user: {
            password: "newpassword123",
            password_confirmation: "newpassword123"
          }
        }
        updated_user = assigns(:user)
        expect(updated_user.authenticate("newpassword123")).to be_truthy
      end
      it "redirects to user page" do
        patch :update_password, params: { id: oauth_user.id, user: password_params }
        expect(response).to redirect_to(user_path(oauth_user))
      end

      it "sets success flash message" do
        patch :update_password, params: { id: oauth_user.id, user: password_params }
        expect(flash[:success]).to eq(I18n.t("users.password_setup_success"))
      end
    end

    context "with invalid params" do
      it "renders setup_password template when validation fails" do
        patch :update_password, params: {
          id: oauth_user.id,
          user: {
            password: "short",
            password_confirmation: "different"
          }
        }
        expect(response).to render_template(:setup_password)
      end
    end
  end

  describe "private methods" do
    describe "#calculate_favorite_stats" do
      it "calculates total favorites correctly when user has no favorites" do
        stats = controller.send(:calculate_favorite_stats, user)
        expect(stats[:total_favorites]).to eq(0)
      end
    end

    describe "#calculate_author_stats" do
      it "returns zero total books for empty array" do
        stats = controller.send(:calculate_author_stats, [])
        expect(stats[:total_books]).to eq(0)
      end

      it "returns zero average books for empty array" do
        stats = controller.send(:calculate_author_stats, [])
        expect(stats[:avg_books]).to eq(0)
      end

      it "calculates total books correctly for authors with books" do
        author1 = build_stubbed(:author)
        author2 = build_stubbed(:author)

        books1 = build_stubbed_list(:book, 2)
        books2 = build_stubbed_list(:book, 3)

        allow(author1).to receive(:books).and_return(books1)
        allow(author2).to receive(:books).and_return(books2)

        stats = controller.send(:calculate_author_stats, [author1, author2])
        expect(stats[:total_books]).to eq(5)
      end

      it "calculates average books correctly for authors with books" do
        author1 = build_stubbed(:author)
        author2 = build_stubbed(:author)

        books1 = build_stubbed_list(:book, 2)
        books2 = build_stubbed_list(:book, 3)

        allow(author1).to receive(:books).and_return(books1)
        allow(author2).to receive(:books).and_return(books2)

        stats = controller.send(:calculate_author_stats, [author1, author2])
        expect(stats[:avg_books]).to eq(2.5)
      end
    end
  end
end

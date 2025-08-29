require "rails_helper"

RSpec.describe Admin::PublishersController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:admin_user) { create(:user, :admin) }
  let(:publisher) { create(:publisher) }

  before { sign_in admin_user }

  describe "GET #index" do
    it "assigns @publishers" do
      get :index
      expect(assigns(:publishers)).to include(publisher)
    end

    it "assigns @pagy" do
      get :index
      expect(assigns(:pagy)).to be_present
    end
  end

  describe "GET #show" do
    it "assigns @publisher" do
      get :show, params: { id: publisher.id }
      expect(assigns(:publisher)).to eq(publisher)
    end
  end

  describe "GET #new" do
    it "assigns a new publisher" do
      get :new
      expect(assigns(:publisher)).to be_a_new(Publisher)
    end
  end

  describe "POST #create" do
    context "with valid attributes" do
      let(:valid_params) { { publisher: attributes_for(:publisher) } }

      it "creates a new publisher" do
        expect {
          post :create, params: valid_params
        }.to change(Publisher, :count).by(1)
      end

      it "redirects to index" do
        post :create, params: valid_params
        expect(response).to redirect_to(admin_publishers_path)
      end

      it "sets success flash" do
        post :create, params: valid_params
        expect(flash[:success]).to eq(I18n.t("admin.publishers.flash.create.success"))
      end
    end

    context "with invalid attributes" do
      let(:invalid_params) { { publisher: { name: "" } } }

      it "does not create a publisher" do
        expect {
          post :create, params: invalid_params
        }.not_to change(Publisher, :count)
      end

      it "renders new template" do
        post :create, params: invalid_params
        expect(response).to render_template(:new)
      end

      it "responds with 422 status" do
        post :create, params: invalid_params
        expect(response.status).to eq(422)
      end

      it "sets alert flash" do
        post :create, params: invalid_params
        expect(flash.now[:alert]).to eq(I18n.t("admin.publishers.flash.create.failure"))
      end
    end
  end

  describe "GET #edit" do
    it "assigns @publisher" do
      get :edit, params: { id: publisher.id }
      expect(assigns(:publisher)).to eq(publisher)
    end
  end

  describe "PATCH #update" do
    context "with valid attributes" do
      let(:update_params) { { id: publisher.id, publisher: { name: "New Name" } } }

      it "updates the publisher name" do
        patch :update, params: update_params
        expect(publisher.reload.name).to eq("New Name")
      end

      it "redirects to show" do
        patch :update, params: update_params
        expect(response).to redirect_to(admin_publisher_path(publisher))
      end

      it "sets success flash" do
        patch :update, params: update_params
        expect(flash[:success]).to eq(I18n.t("admin.publishers.flash.update.success"))
      end
    end

    context "with invalid attributes" do
      let(:invalid_update) { { id: publisher.id, publisher: { name: "" } } }

      it "does not update publisher" do
        patch :update, params: invalid_update
        expect(publisher.reload.name).not_to eq("")
      end

      it "renders edit template" do
        patch :update, params: invalid_update
        expect(response).to render_template(:edit)
      end

      it "responds with 422 status" do
        patch :update, params: invalid_update
        expect(response.status).to eq(422)
      end

      it "sets alert flash" do
        patch :update, params: invalid_update
        expect(flash.now[:alert]).to eq(I18n.t("admin.publishers.flash.update.failure"))
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the publisher" do
      publisher_to_delete = create(:publisher)
      expect {
        delete :destroy, params: { id: publisher_to_delete.id }
      }.to change(Publisher, :count).by(-1)
    end

    it "redirects to index after destroy" do
      publisher_to_delete = create(:publisher)
      delete :destroy, params: { id: publisher_to_delete.id }
      expect(response).to redirect_to(admin_publishers_path)
    end

    it "sets success flash after destroy" do
      publisher_to_delete = create(:publisher)
      delete :destroy, params: { id: publisher_to_delete.id }
      expect(flash[:success]).to eq(I18n.t("admin.publishers.flash.destroy.success"))
    end

    it "handles destroy failure gracefully" do
      publisher_to_fail = create(:publisher)
      allow_any_instance_of(Publisher).to receive(:destroy).and_return(false)
      allow_any_instance_of(Publisher).to receive_message_chain(:errors, :full_messages).and_return([I18n.t("admin.publishers.flash.destroy.failure")])
      delete :destroy, params: { id: publisher_to_fail.id }
      expect(flash[:alert]).to eq(I18n.t("admin.publishers.flash.destroy.failure"))
    end

    it "redirects to index on destroy failure" do
      publisher_to_fail = create(:publisher)
      allow_any_instance_of(Publisher).to receive(:destroy).and_return(false)
      allow_any_instance_of(Publisher).to receive_message_chain(:errors, :full_messages).and_return([I18n.t("admin.publishers.flash.destroy.failure")])
      delete :destroy, params: { id: publisher_to_fail.id }
      expect(response).to redirect_to(admin_publishers_path)
    end
  end
end

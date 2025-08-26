require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let!(:user) {create(:user, password: "password", confirmed_at: Time.current)}

  describe "POST /users/sign_in" do
    context "with valid credentials" do
      it "logs in the user and sets success flash" do
        post user_session_path, params: {
          user: {email: user.email, password: "password"}
        }

        follow_redirect!

        expect(controller.current_user).to eq(user)
        expect(flash[:success]).to eq(I18n.t("sessions.create.success"))
      end
    end

    context "with invalid credentials" do
      it "does not log in and shows alert" do
        post user_session_path, params: {
          user: {email: user.email, password: "wrong"}
        }

        expect(controller.current_user).to be_nil
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe "DELETE /users/sign_out" do
    it "logs out the user and sets success flash" do
      sign_in user
      delete destroy_user_session_path

      follow_redirect!

      expect(controller.current_user).to be_nil
      expect(flash[:success]).to eq(I18n.t("sessions.destroy.success"))
    end
  end
end

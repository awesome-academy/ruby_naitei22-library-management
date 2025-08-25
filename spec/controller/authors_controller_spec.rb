require "rails_helper"

RSpec.describe AuthorsController, type: :controller do
  let(:user) do
    User.create!(
      name: "User",
      email: "user@example.com",
      password: "password",
      gender: :male,
      date_of_birth: Date.new(1990,1,1)
    )
  end

  let(:author) { Author.create!(name: "Nam Cao") }
  let(:publisher) { Publisher.create!(name: "NXB Kim Đồng") }
  let!(:book) { Book.create!(title: "Chí Phèo", author: author, publisher: publisher, total_quantity: 5) }

  before do
    session[:user_id] = user.id
  end

  describe "GET #show" do
    context "when author exists" do
      before { get :show, params: { id: author.id } }

      it "assigns the requested author" do
        expect(assigns(:author)).to eq(author)
      end

      it "returns a successful response" do
        expect(response).to be_successful
      end
    end

    context "when author does not exist" do
      before { get :show, params: { id: -1 } }

      it "redirects to root path" do
        expect(response).to redirect_to(root_path)
      end

      it "sets flash alert with author_not_found" do
        expect(flash[:alert]).to eq(I18n.t("authors.show.author_not_found"))
      end
    end
  end

  describe "POST #add_to_favorite" do
    context "when favorite is saved successfully" do
      it "creates a new favorite" do
        expect {
          post :add_to_favorite, params: { id: author.id }
        }.to change(Favorite, :count).by(1)
      end

      it "redirects to author show page" do
        post :add_to_favorite, params: { id: author.id }
        expect(response).to redirect_to(author_path(author))
      end

      it "sets flash notice" do
        post :add_to_favorite, params: { id: author.id }
        expect(flash[:notice]).to eq(I18n.t("authors.show.favorite_success"))
      end

      it "creates a new favorite (Turbo Stream)" do
        expect {
          post :add_to_favorite, params: { id: author.id }, format: :turbo_stream
        }.to change(Favorite, :count).by(1)
      end

      it "returns turbo stream response" do
        post :add_to_favorite, params: { id: author.id }, format: :turbo_stream
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end
    end

    context "when favorite fails to save" do
      before do
        allow_any_instance_of(Favorite).to receive(:save).and_return(false)
      end

      it "does not create a new favorite" do
        expect {
          post :add_to_favorite, params: { id: author.id }
        }.not_to change(Favorite, :count)
      end

      it "redirects to author show page" do
        post :add_to_favorite, params: { id: author.id }
        expect(response).to redirect_to(author_path(author))
      end

      it "sets flash alert with favorite_failed" do
        post :add_to_favorite, params: { id: author.id }
        expect(flash[:alert]).to eq(I18n.t("authors.show.favorite_failed"))
      end
    end
  end

  describe "DELETE #remove_from_favorite" do
    context "when favorite exists" do
      let!(:favorite) { Favorite.create!(favorable: author, user: user) }

      it "removes the favorite (HTML)" do
        expect {
          delete :remove_from_favorite, params: { id: author.id }
        }.to change(Favorite, :count).by(-1)
      end

      it "redirects to author show page (HTML)" do
        delete :remove_from_favorite, params: { id: author.id }
        expect(response).to redirect_to(author_path(author))
      end

      it "sets flash notice (HTML)" do
        delete :remove_from_favorite, params: { id: author.id }
        expect(flash[:notice]).to eq(I18n.t("authors.show.unfavorite_success"))
      end

      it "removes the favorite (Turbo Stream)" do
        favorite
        expect {
          delete :remove_from_favorite, params: { id: author.id }, format: :turbo_stream
        }.to change(Favorite, :count).by(-1)
      end

      it "returns turbo stream response" do
        favorite
        delete :remove_from_favorite, params: { id: author.id }, format: :turbo_stream
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      context "when destroy fails" do
        before do
          allow_any_instance_of(Favorite).to receive(:destroy).and_return(false)
        end

        it "does not remove the favorite" do
          expect {
            delete :remove_from_favorite, params: { id: author.id }
          }.not_to change(Favorite, :count)
        end

        it "redirects to author show page" do
          delete :remove_from_favorite, params: { id: author.id }
          expect(response).to redirect_to(author_path(author))
        end

        it "sets flash alert" do
          delete :remove_from_favorite, params: { id: author.id }
          expect(flash[:alert]).to eq(I18n.t("authors.show.unfavorite_failed"))
        end
      end
    end

    context "when favorite does not exist" do
      before { delete :remove_from_favorite, params: { id: author.id } }

      it "redirects to author show page" do
        expect(response).to redirect_to(author_path(author))
      end

      it "sets flash alert" do
        expect(flash[:alert]).to eq(I18n.t("authors.show.favorite_not_found"))
      end
    end
  end
end

require "rails_helper"

RSpec.describe User, type: :model do
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

  let(:user) { described_class.new(valid_attributes) }

  describe "associations" do
    it { should have_many(:reviews).dependent(:destroy) }
    it { should have_many(:favorites).dependent(:destroy) }
    it { should have_many(:favorite_books).through(:favorites) }
    it { should have_many(:favorite_authors).dependent(:destroy) }
    it { should have_many(:followed_authors).through(:favorite_authors) }
    it { should have_many(:borrow_requests).dependent(:destroy) }
    it { should have_one_attached(:image) }
    it { should have_one_attached(:avatar) }
  end

  describe "enums" do
    it { should define_enum_for(:role).with_values(user: 0, admin: 1, super_admin: 2) }
    it { should define_enum_for(:gender).with_values(male: 0, female: 1, other: 2) }
    it { should define_enum_for(:status).with_values(inactive: 0, active: 1) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(User::NAME_MAX_LENGTH) }
    it { should validate_presence_of(:email) }
    it { should validate_length_of(:email).is_at_most(User::EMAIL_MAX_LENGTH) }
    it { should validate_presence_of(:gender) }
    it { should validate_length_of(:address).is_at_most(500) }
    it "validates email format" do
      user.email = "invalid"
      expect(user).not_to be_valid
      user.email = "valid@example.com"
      expect(user).to be_valid
    end
    it "validates password length" do
      user.password = "short"
      expect(user).not_to be_valid
      user.password = "password123"
      expect(user).to be_valid
    end
    it "validates date_of_birth not in future" do
      user.date_of_birth = 1.day.from_now.to_date
      expect(user).not_to be_valid
    end
    it "validates date_of_birth not more than 100 years ago" do
      user.date_of_birth = 101.years.ago.to_date
      expect(user).not_to be_valid
    end
    it "validates phone number format" do
      user.phone_number = "+1234567890"
      expect(user).to be_valid
      user.phone_number = "invalid"
      expect(user).not_to be_valid
    end
  end

  describe "callbacks" do
    it "downcases email before save" do
      user.email = "JOHN@EXAMPLE.COM"
      user.save!
      expect(user.email).to eq("john@example.com")
    end
  end

  describe "scopes" do
    let!(:old_user) { User.create!(valid_attributes.merge(email: "old@example.com", created_at: 2.days.ago)) }
    let!(:new_user) { User.create!(valid_attributes.merge(email: "new@example.com", created_at: 1.day.ago)) }

    it "orders users by created_at desc" do
      expect(User.recent).to eq([new_user, old_user])
    end

    it "orders users by created_at asc" do
      expect(User.order_by_created).to eq([old_user, new_user])
    end
  end

  describe "instance methods" do
    let!(:saved_user) { User.create!(valid_attributes) }

    it "#favorited? returns false if not favorited" do
      book = create(:book)
      expect(saved_user.favorited?(book)).to be false
    end

    it "#ordered_favorite_books_with_includes returns relation" do
      expect(saved_user.ordered_favorite_books_with_includes).to be_a(ActiveRecord::Relation)
    end

    it "#ordered_favorite_authors_with_includes returns relation" do
      expect(saved_user.ordered_favorite_authors_with_includes).to be_a(ActiveRecord::Relation)
    end

    it "#oauth_user? returns false for regular user" do
      expect(saved_user.oauth_user?).to be false
    end
  end

  describe "class methods" do
    it ".digest returns a hash" do
      digest = User.digest("password")
      expect(digest).to be_present
    end

    it ".new_token returns a random token" do
      token1 = User.new_token
      token2 = User.new_token
      expect(token1).not_to eq(token2)
    end

    it ".from_omniauth creates or updates user" do
      auth = double("auth",
        info: double("info", name: "John Doe", email: "oauth@example.com"),
        provider: "google",
        uid: "12345"
      )
      expect { User.from_omniauth(auth) }.to change(User, :count).by(1)
    end
  end
end

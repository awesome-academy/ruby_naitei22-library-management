require "rails_helper"

RSpec.describe User, type: :model do
  let(:user) do
    described_class.new(
      name: "John Doe",
      email: "john@example.com",
      password: "password123",
      password_confirmation: "password123",
      date_of_birth: 20.years.ago.to_date,
      gender: :male
    )
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(user).to be_valid
    end

    it "is invalid without a name" do
      user.name = nil
      expect(user).not_to be_valid
    end

    it "is invalid when name is too long" do
      user.name = "a" * 51
      expect(user).not_to be_valid
    end

    it "is invalid without an email" do
      user.email = nil
      expect(user).not_to be_valid
    end

    it "is invalid when email is too long" do
      user.email = "a" * 246 + "@example.com"
      expect(user).not_to be_valid
    end

    it "is invalid with wrong email format" do
      user.email = "invalid_email"
      expect(user).not_to be_valid
    end

    it "is invalid with duplicate email" do
      described_class.create!(
        name: "Jane",
        email: "john@example.com",
        password: "password123",
        password_confirmation: "password123",
        date_of_birth: 20.years.ago,
        gender: :female
      )
      expect(user).not_to be_valid
    end

    it "is invalid without gender" do
      user.gender = nil
      expect(user).not_to be_valid
    end

    it "is invalid with invalid phone number" do
      user.phone_number = "123"
      expect(user).not_to be_valid
    end

    it "is invalid with too long address" do
      user.address = "a" * 501
      expect(user).not_to be_valid
    end

    it "is invalid when date_of_birth is more than 100 years ago" do
      user.date_of_birth = 150.years.ago.to_date
      expect(user).not_to be_valid
    end

    it "is invalid when date_of_birth is in the future" do
      user.date_of_birth = 1.day.from_now.to_date
      expect(user).not_to be_valid
    end

    it "is invalid when password_confirmation is present but password is blank" do
      user.password = ""
      user.password_confirmation = "something"
      expect(user).not_to be_valid
    end
  end

  describe "scopes" do
    before do
      @older = described_class.create!(
        name: "Older",
        email: "older@example.com",
        password: "password123",
        password_confirmation: "password123",
        date_of_birth: 30.years.ago,
        gender: :male,
        created_at: 2.days.ago
      )
      @newer = described_class.create!(
        name: "Newer",
        email: "newer@example.com",
        password: "password123",
        password_confirmation: "password123",
        date_of_birth: 25.years.ago,
        gender: :female,
        created_at: 1.day.ago
      )
    end

    it "orders users by most recent" do
      expect(described_class.recent.first).to eq(@newer)
    end

    it "orders users by oldest created first" do
      expect(described_class.order_by_created.first).to eq(@older)
    end
  end

  describe "#favorited?" do
    it "returns true if the user favorited the item" do
      book = Book.create!(
        title: "Book",
        author: Author.create!(name: "Author"),
        publisher: Publisher.create!(name: "Publisher"),
        total_quantity: 10
        )
      user.save!
      user.favorites.create!(favorable: book)
      expect(user.favorited?(book)).to be true
    end

    it "returns false if the user has not favorited the item" do
      book = Book.create!(
        title: "Book",
        author: Author.create!(name: "Author"),
        publisher: Publisher.create!(name: "Publisher"),
        total_quantity: 10
        )
      user.save!
      expect(user.favorited?(book)).to be false
    end
  end

  describe ".from_omniauth" do
    let(:auth) do
      OmniAuth::AuthHash.new(
        provider: "google",
        uid: "12345",
        info: {email: "oauth@example.com", name: "OAuth User"}
      )
    end

    it "returns existing user if email matches" do
      existing = described_class.create!(
        name: "Existing",
        email: "oauth@example.com",
        password: "password123",
        password_confirmation: "password123",
        date_of_birth: 20.years.ago,
        gender: :other
      )
      user_from_auth = described_class.from_omniauth(auth)
      expect(user_from_auth).to eq(existing)
    end

    it "creates new user if email does not exist" do
      user_from_auth = described_class.from_omniauth(auth)
      expect(user_from_auth).to be_persisted
    end
  end

  describe "#oauth_user?" do
    it "returns true if provider is present" do
      user.provider = "google"
      expect(user.oauth_user?).to be true
    end

    it "returns false if provider is nil" do
      user.provider = nil
      expect(user.oauth_user?).to be false
    end
  end

  describe "#needs_password_setup?" do
    it "returns true if user is oauth user and not updated yet" do
      user.provider = "google"
      user.save!
      expect(user.needs_password_setup?).to be true
    end

    it "returns false if user is not oauth user" do
      user.provider = nil
      expect(user.needs_password_setup?).to be false
    end
  end

  describe ".ransackable_attributes" do
    it "includes id, name, email, phone_number, role, status, created_at" do
      expect(described_class.ransackable_attributes).to include("id", "name", "email", "phone_number", "role", "status", "created_at")
    end
  end
end

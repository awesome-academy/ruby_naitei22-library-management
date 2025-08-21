require "rails_helper"

RSpec.describe Author, type: :model do
  subject do
    Author.new(
      name: "Nam Cao",
      bio: "He was a Vietnamese realist writer",
      nationality: "Vietnamese",
      birth_date: Date.new(1802, 2, 26)
    )
  end

  let(:publisher) { Publisher.create!(name: "NXB ABC") }
  let(:user1) do
    User.create!(
      name: "User 1",
      email: "user1@example.com",
      password: "password",
      gender: :male,
      date_of_birth: Date.new(1990, 1, 1)
    )
  end
  let(:user2) do
    User.create!(
      name: "User 2",
      email: "user2@example.com",
      password: "password",
      gender: :female,
      date_of_birth: Date.new(1992, 1, 1)
    )
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "is invalid without a name" do
      subject.name = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:name]).to include(I18n.t("activerecord.errors.messages.blank"))
    end

    it "is invalid if name is too long" do
      subject.name = "a" * (Author::MAX_NAME_LENGTH + 1)
      expect(subject).not_to be_valid
    end

    it "is invalid if bio is too long" do
      subject.bio = "a" * (Author::MAX_BIO_LENGTH + 1)
      expect(subject).not_to be_valid
    end

    it "is invalid if nationality is too long" do
      subject.nationality = "a" * (Author::MAX_NATIONALITY_LENGTH + 1)
      expect(subject).not_to be_valid
    end

    it "is invalid if birth_date is in the future" do
      subject.birth_date = Date.current + 1.day
      expect(subject).not_to be_valid
    end

    it "is valid if death_date is after birth_date" do
      subject.birth_date = Date.new(1900, 1, 1)
      subject.death_date = Date.new(1950, 1, 1)
      expect(subject).to be_valid
    end

    it "is invalid if death_date is before or equal to birth_date" do
      subject.birth_date = Date.new(2000, 1, 1)
      subject.death_date = Date.new(1999, 12, 31)
      expect(subject).not_to be_valid
    end

    it "is invalid if death_date is in the future" do
      subject.birth_date = Date.new(1900, 1, 1)
      subject.death_date = Date.current + 1.day
      expect(subject).not_to be_valid
    end
  end

  describe "associations" do
    let(:author) { Author.create!(name: "Author") }

    it "can have many books" do
      book1 = Book.create!(title: "Book 1", author: author, publisher: publisher, total_quantity: 10)
      book2 = Book.create!(title: "Book 2", author: author, publisher: publisher, total_quantity: 5)

      expect(author.books).to include(book1, book2)
    end

    it "can have many favorites" do
      favorite1 = Favorite.create!(favorable: author, user: user1)
      favorite2 = Favorite.create!(favorable: author, user: user2)

      expect(author.favorites).to include(favorite1, favorite2)
    end
  end

  describe "scopes" do
    it ".alive returns authors with no death_date" do
      alive_author = Author.create!(name: "Alive", birth_date: Date.new(1990, 1, 1))
      deceased_author = Author.create!(name: "Dead", birth_date: Date.new(1890, 1, 1), death_date: Date.new(2000, 1, 1))

      expect(Author.alive).to include(alive_author)
      expect(Author.alive).not_to include(deceased_author)
    end

    it ".deceased returns authors with death_date" do
      alive_author = Author.create!(name: "Alive", birth_date: Date.new(1990, 1, 1))
      deceased_author = Author.create!(name: "Dead", birth_date: Date.new(1890, 1, 1), death_date: Date.new(2000, 1, 1))

      expect(Author.deceased).to include(deceased_author)
      expect(Author.deceased).not_to include(alive_author)
    end

    it ".recent orders authors by created_at desc" do
      author1 = Author.create!(name: "Old", created_at: 1.day.ago)
      author2 = Author.create!(name: "New", created_at: Time.current)

      expect(Author.recent.first).to eq(author2)
    end
  end

  describe ".ransackable_attributes" do
    it "returns only name as ransackable attribute" do
      expect(Author.ransackable_attributes).to eq(["name"])
    end
  end
end

require "rails_helper"

RSpec.describe Book, type: :model do
  let(:author) { create(:author) }
  let(:publisher) { create(:publisher) }
  let(:book) do
    described_class.new(
      title: "Test Book",
      description: "A book for testing.",
      publication_year: 2001,
      total_quantity: 10,
      available_quantity: 5,
      borrow_count: 0,
      author: author,
      publisher: publisher
    )
  end

  describe "associations" do
    it { is_expected.to belong_to(:author) }
    it { is_expected.to belong_to(:publisher) }
    it { is_expected.to have_many(:book_categories).dependent(:destroy) }
    it { is_expected.to have_many(:categories).through(:book_categories) }
    it { is_expected.to have_many(:borrow_request_items).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:borrow_requests).through(:borrow_request_items) }
    it { is_expected.to have_many(:reviews).dependent(:destroy) }
    it { is_expected.to have_many(:favorites).dependent(:destroy) }
    it { is_expected.to have_one_attached(:image) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:title).is_at_most(Book::MAX_TITLE_LENGTH) }
    it { is_expected.to validate_length_of(:description).is_at_most(Book::MAX_DESCRIPTION_LENGTH) }
    it { is_expected.to validate_numericality_of(:total_quantity).is_greater_than(Book::MIN_TOTAL_QUANTITY) }
    it { is_expected.to validate_numericality_of(:available_quantity).is_greater_than_or_equal_to(Book::MIN_AVAILABLE_QUANTITY) }
    it { is_expected.to validate_numericality_of(:borrow_count).is_greater_than_or_equal_to(Book::MIN_BORROW_COUNT) }
    it { is_expected.to validate_presence_of(:author_id) }
    it { is_expected.to validate_presence_of(:publisher_id) }
  end

  describe "scopes" do
    it "by_author returns books by author" do
      book.save!
      expect(Book.by_author(author.id)).to include(book)
    end

    it "exclude_book excludes given book" do
      book.save!
      expect(Book.exclude_book(book.id)).not_to include(book)
    end

    it "recent orders by created_at desc" do
      book.save!
      expect(Book.recent.first).to eq(book)
    end
  end

  describe "#average_rating" do
    it "returns 0 if no reviews" do
      book.save!
      expect(book.average_rating).to eq(Settings.digits.digit_0)
    end
  end

  describe ".search" do
    it "returns none if query blank" do
      expect(Book.search("", :title)).to be_empty
    end
  end
end

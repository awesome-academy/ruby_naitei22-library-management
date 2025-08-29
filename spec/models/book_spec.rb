require "rails_helper"

RSpec.describe Book, type: :model do
  let(:author) { create(:author) }
  let(:publisher) { create(:publisher) }
  let(:user) { create(:user) }

  # Books for scope/filter testing
  let!(:old_book) do
    create(:book,
           title: "Old Book",
           total_quantity: 5,
           available_quantity: 5,
           author: author,
           publisher: publisher,
           borrow_count: 2,
           created_at: 2.days.ago,
           publication_year: 2000)
  end

  let!(:recent_book) do
    create(:book,
           title: "Recent Book",
           total_quantity: 10,
           available_quantity: 10,
           author: author,
           publisher: publisher,
           borrow_count: 5,
           created_at: 1.hour.ago,
           publication_year: 2022)
  end

  # ---------------------------
  # Associations
  # ---------------------------
  describe "associations" do
    it { is_expected.to belong_to(:author) }
    it { is_expected.to belong_to(:publisher) }
    it { is_expected.to have_many(:book_categories).dependent(:destroy) }
    it { is_expected.to have_many(:categories).through(:book_categories) }
    it { is_expected.to have_many(:borrow_request_items).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:borrow_requests).through(:borrow_request_items) }
    it { is_expected.to have_many(:reviews).dependent(:destroy) }
    it { is_expected.to have_many(:favorites).dependent(:destroy) }
  end

  # ---------------------------
  # Validations
  # ---------------------------
  describe "validations" do
    subject { build(:book, author: author, publisher: publisher) }

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:title).is_at_most(Book::MAX_TITLE_LENGTH) }
    it { is_expected.to validate_length_of(:description).is_at_most(Book::MAX_DESCRIPTION_LENGTH) }
    it { is_expected.to validate_numericality_of(:total_quantity).is_greater_than(Book::MIN_TOTAL_QUANTITY) }
    it { is_expected.to validate_numericality_of(:borrow_count).is_greater_than_or_equal_to(Book::MIN_BORROW_COUNT) }
    it { is_expected.to validate_numericality_of(:publication_year).is_greater_than(Book::MIN_PUBLICATION_YEAR).allow_nil }

    it "validates available_quantity <= total_quantity" do
      book = build(:book, total_quantity: 5, available_quantity: 6, author: author, publisher: publisher)
      expect(book).not_to be_valid
      expect(book.errors[:available_quantity]).to include("must be less than or equal to 5")
    end
  end

  # ---------------------------
  # Scopes
  # ---------------------------
  describe "scopes" do
    describe ".recent" do
      it "returns newest created books first" do
        expect(Book.recent.first).to eq(recent_book)
      end
    end

    describe ".by_author" do
      it "returns books of given author" do
        expect(Book.by_author(author.id)).to include(old_book, recent_book)
      end
    end

    describe ".exclude_book" do
      it "excludes a specific book by id" do
        expect(Book.exclude_book(recent_book.id)).to eq([old_book])
      end
    end

    describe ".newest" do
      it "orders books by publication_year descending" do
        expect(Book.newest.first).to eq(recent_book)
      end
    end

    describe ".most_borrow_count" do
      it "orders books by borrow_count descending" do
        expect(Book.most_borrow_count.first).to eq(recent_book)
      end
    end

    describe ".ordered_by_title" do
      it "orders books alphabetically" do
        expect(Book.ordered_by_title).to eq([old_book, recent_book])
      end
    end

    describe ".with_cover / .without_cover" do
      it "detects books with and without attached image" do
        book = create(:book, author: author, publisher: publisher)
        expect(Book.without_cover).to include(book)

        book.image.attach(io: File.open(Rails.root.join("spec/fixtures/files/sample.png")), filename: "sample.png", content_type: "image/png")
        expect(Book.with_cover).to include(book)
      end
    end
  end

  # ---------------------------
  # Instance Methods
  # ---------------------------
  describe "#average_rating" do
    let(:book) { create(:book, author: author, publisher: publisher) }

    it "returns 0 if no reviews" do
      expect(book.average_rating).to eq(0)
    end

    it "returns the average score of reviews rounded to 1 decimal" do
      create(:review, book: book, user: user, score: 4)
      create(:review, book: book, user: create(:user), score: 5)
      expect(book.average_rating).to eq(4.5)
    end
  end

  # ---------------------------
  # Filter / Class Methods
  # ---------------------------
  describe ".filter_by" do
    it "returns newest books for 'newest'" do
      expect(Book.filter_by("newest").first).to eq(recent_book)
    end

    it "returns most_borrow_count books for 'most_borrow_count'" do
      expect(Book.filter_by("most_borrow_count").first).to eq(recent_book)
    end

    it "returns highest_rating books for 'highest_rating'" do
      create(:review, book: old_book, user: user, score: 5)
      expect(Book.filter_by("highest_rating").first).to eq(old_book)
    end

    it "returns user's favorites for 'my_favorites'" do
      create(:favorite, favorable: old_book, user: user)
      expect(Book.filter_by("my_favorites", user)).to include(old_book)
    end

    it "returns empty for 'my_favorites' when user is nil" do
      expect(Book.filter_by("my_favorites", nil)).to be_empty
    end

    it "returns ordered_by_title for unknown filter" do
      expect(Book.filter_by("unknown")).to eq(Book.ordered_by_title)
    end
  end

  # ---------------------------
  # Ransack
  # ---------------------------
  describe ".ransackable_attributes" do
    it "returns title and average_rating" do
      expect(Book.ransackable_attributes).to match_array(%w(title average_rating))
    end
  end

  describe ".ransackable_associations" do
    it "returns correct associations" do
      expect(Book.ransackable_associations).to match_array(%w(author publisher categories favorites))
    end
  end

  describe "ransacker :average_rating" do
    let!(:high_rated_book) { create(:book, author: author, publisher: publisher) }
    let!(:low_rated_book)  { create(:book, author: author, publisher: publisher) }

    before do
      create(:review, book: high_rated_book, user: user, score: 5)
      create(:review, book: high_rated_book, user: create(:user), score: 4)
      create(:review, book: low_rated_book, user: create(:user), score: 2)
      create(:review, book: low_rated_book, user: create(:user), score: 1)
    end

    it "sorts by average_rating desc" do
      result = Book.where(id: [high_rated_book.id, low_rated_book.id]).ransack(s: "average_rating desc").result
      expect(result.first).to eq(high_rated_book)
    end

    it "sorts by average_rating asc" do
      result = Book.where(id: [high_rated_book.id, low_rated_book.id]).ransack(s: "average_rating asc").result
      expect(result.first).to eq(low_rated_book)
    end

    it "includes books above threshold" do
      result = Book.ransack(average_rating_gt: 3).result
      expect(result).to include(high_rated_book)
    end

    it "excludes books below threshold" do
      result = Book.ransack(average_rating_gt: 3).result
      expect(result).not_to include(low_rated_book)
    end
  end
end

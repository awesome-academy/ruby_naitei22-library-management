require "rails_helper"

RSpec.describe Book, type: :model do
  let!(:publisher) { Publisher.where(name: "Publisher").first_or_create! }
  let!(:author) { Author.where(name: "Author").first_or_create! }
  let!(:book) {Book.create!(title: "Book", total_quantity: 1, available_quantity: 1, author: author, publisher: publisher, borrow_count: 0, created_at: 2.days.ago, publication_year: 2000)}
  let!(:recent_book) {Book.create!(title: "Recent Book", total_quantity: 5, available_quantity: 5, author: author, publisher: publisher, borrow_count: 0, created_at: 1.day.ago, publication_year: 2020)}
  let!(:user) { User.create!(name: "Test User", email: "test@example.com", password: "123456", gender: "male", date_of_birth: "2000-01-01") }

  # ---------------------------
  # Associations
  # ---------------------------
  describe "associations" do
    it "belongs to an author" do
      expect(book.author).to eq(author)
    end

    it "belongs to a publisher" do
      expect(book.publisher).to eq(publisher)
    end

    it "has many reviews" do
      user1 = User.create!(name: "A", email: "a@test.com", password: "123456", gender: "male", date_of_birth: "2000-01-01")
      user2 = User.create!(name: "B", email: "b@test.com", password: "123456", gender: "male", date_of_birth: "2000-01-01")
      review1 = Review.create!(book: book, user: user1, score: 5)
      review2 = Review.create!(book: book, user: user2, score: 4)

      expect(book.reviews).to include(review1, review2)
    end
  end

  # ---------------------------
  # Validations
  # ---------------------------
  describe "validations" do
    it "is invalid without a title" do
      book_no_title = Book.new(total_quantity: 1, available_quantity: 1, author: author, publisher: publisher, borrow_count: 0)
      expect(book_no_title).not_to be_valid
    end

    it "returns error when title is missing" do
      book_no_title = Book.new(total_quantity: 1, available_quantity: 1, author: author, publisher: publisher, borrow_count: 0)
      book_no_title.valid?
      expect(book_no_title.errors[:title]).to include(I18n.t("activerecord.errors.models.book.attributes.title.blank"))
    end

    it "is invalid when title is too long" do
      long_title = "a" * (Book::MAX_TITLE_LENGTH + 1)
      book_long_title = Book.new(title: long_title, total_quantity: 1, available_quantity: 1, author: author, publisher: publisher, borrow_count: 0)
      expect(book_long_title).not_to be_valid
    end

    it "returns error when title is too long" do
      long_title = "a" * (Book::MAX_TITLE_LENGTH + 1)
      book_long_title = Book.new(title: long_title, total_quantity: 1, available_quantity: 1, author: author, publisher: publisher, borrow_count: 0)
      book_long_title.valid?
      expect(book_long_title.errors[:title]).to include(
        I18n.t("activerecord.errors.models.book.attributes.title.too_long", count: Book::MAX_TITLE_LENGTH)
      )
    end

    it "is invalid when available_quantity > total_quantity" do
      book_invalid_quantity = Book.new(title: "Invalid", total_quantity: 2, available_quantity: 5, author: author, publisher: publisher, borrow_count: 0)
      expect(book_invalid_quantity).not_to be_valid
    end

    it "returns error when available_quantity > total_quantity" do
      book_invalid_quantity = Book.new(title: "Invalid", total_quantity: 2, available_quantity: 5, author: author, publisher: publisher, borrow_count: 0)
      book_invalid_quantity.valid?
      expect(book_invalid_quantity.errors[:available_quantity]).to include(I18n.t("errors.messages.less_than_or_equal_to", count: 2))
    end

    it "is invalid when description is too long" do
      long_desc = "a" * (Book::MAX_DESCRIPTION_LENGTH + 1)
      book_invalid_description = Book.new(title: "Desc too long", description: long_desc,
                              total_quantity: 1, available_quantity: 1,
                              author: author, publisher: publisher, borrow_count: 0)
      expect(book_invalid_description.valid?).to eq(false)
    end

    it "returns error when description is too long" do
      long_desc = "a" * (Book::MAX_DESCRIPTION_LENGTH + 1)
      book_invalid_description = Book.new(title: "Desc too long", description: long_desc,
                              total_quantity: 1, available_quantity: 1,
                              author: author, publisher: publisher, borrow_count: 0)
      book_invalid_description.valid?
      expect(book_invalid_description.errors[:description]).to include(
        I18n.t("activerecord.errors.models.book.attributes.description.too_long",
              count: Book::MAX_DESCRIPTION_LENGTH)
      )
    end

    it "is valid when description is empty" do
      book_valid = Book.new(title: "No desc", description: "",
                            total_quantity: 1, available_quantity: 1,
                            author: author, publisher: publisher, borrow_count: 0)
      expect(book_valid.valid?).to eq(true)
    end

    it "is invalid when publication_year <= MIN_PUBLICATION_YEAR" do
      book_invalid = Book.new(title: "Old", publication_year: 900,
                              total_quantity: 1, available_quantity: 1,
                              author: author, publisher: publisher, borrow_count: 0)
      expect(book_invalid.valid?).to eq(false)
    end

    it "is valid when publication_year is nil" do
      book_valid = Book.new(title: "Nil year", publication_year: nil,
                            total_quantity: 1, available_quantity: 1,
                            author: author, publisher: publisher, borrow_count: 0)
      expect(book_valid.valid?).to eq(true)
    end

    it "is invalid when borrow_count is negative" do
      book_invalid = Book.new(title: "Negative borrow", total_quantity: 1,
                              available_quantity: 1, author: author,
                              publisher: publisher, borrow_count: -1)
      expect(book_invalid.valid?).to eq(false)
    end

    it "is invalid without an author" do
      book_invalid = Book.new(title: "No author", total_quantity: 1,
                              available_quantity: 1, publisher: publisher, borrow_count: 0)
      expect(book_invalid.valid?).to eq(false)
    end

    it "is invalid without a publisher" do
      book_invalid = Book.new(title: "No publisher", total_quantity: 1,
                              available_quantity: 1, author: author, borrow_count: 0)
      expect(book_invalid.valid?).to eq(false)
    end

    it "is valid with proper data" do
      book_valid = Book.new(title: "Valid", total_quantity: 5, available_quantity: 5, author: author, publisher: publisher, borrow_count: 0)
      expect(book_valid.valid?).to eq(true)
    end
  end

  # ---------------------------
  # Scopes
  # ---------------------------
  describe "scopes" do
    it ".recent returns newest books first" do
      expect(Book.recent).to eq([recent_book, book])
    end

    it ".by_author returns books of given author" do
      expect(Book.by_author(author.id)).to include(book, recent_book)
    end

    it ".exclude_book excludes book by id" do
      expect(Book.exclude_book(recent_book.id)).to eq([book])
    end

    it ".recommended returns ordered by publication_year desc" do
      expect(Book.recommended).to eq([recent_book, book])
    end

    describe ".most_borrowed" do
      before do
        3.times do
          br = BorrowRequest.create!(user: user, request_date: Date.today - 1.day, start_date: Date.today, end_date: Date.today + 7.days)
          BorrowRequestItem.create!(book: book, borrow_request: br, quantity: 1)
        end

        br = BorrowRequest.create!(user: user, request_date: Date.today - 1.day, start_date: Date.today, end_date: Date.today + 7.days)
        BorrowRequestItem.create!(book: recent_book, borrow_request: br, quantity: 1)
      end

      let(:result) { Book.most_borrowed }

      it "first book is book" do
        expect(result.first).to eq(book)
      end

      it "second book is recent_book" do
        expect(result.second).to eq(recent_book)
      end

      it "borrow_count of book = 3" do
        expect(result.first.borrow_count).to eq(3)
      end

      it "borrow_count of recent_book = 1" do
        expect(result.second.borrow_count).to eq(1)
      end
    end

    describe ".most_borrowed filtered by year" do
      before do
        2.times do
          br = BorrowRequest.create!(user: user,
                                    request_date: Date.new(2022, 5, 1),
                                    start_date: Date.new(2022, 5, 2),
                                    end_date: Date.new(2022, 5, 10))
          BorrowRequestItem.create!(book: book, borrow_request: br, quantity: 1)
        end
      end

      context "when filtering by year 2022" do
        let(:result_2022) { Book.most_borrowed(year: 2022) }

        it "returns book as first result" do
          expect(result_2022.first).to eq(book)
        end

        it "book has borrow_count = 2" do
          expect(result_2022.first.borrow_count).to eq(2)
        end
      end

      context "when filtering by year 2023" do
        let(:result_2023) { Book.most_borrowed(year: 2023) }

        it "returns empty" do
          expect(result_2023).to be_empty
        end
      end
    end

    describe ".most_borrowed filtered by month" do
      let!(:other_book) do
        Book.create!(title: "Other Book", total_quantity: 5,
                    available_quantity: 5, author: author, publisher: publisher)
      end

      before do
        br_aug = BorrowRequest.create!(user: user,
                                      request_date: Date.new(2025, 8, 15),
                                      start_date: Date.new(2025, 8, 16),
                                      end_date: Date.new(2025, 8, 20))
        BorrowRequestItem.create!(book: book, borrow_request: br_aug, quantity: 1)

        br_jan = BorrowRequest.create!(user: user,
                                      request_date: Date.new(2025, 1, 5),
                                      start_date: Date.new(2025, 1, 6),
                                      end_date: Date.new(2025, 1, 10))
        BorrowRequestItem.create!(book: other_book, borrow_request: br_jan, quantity: 1)

        book.reload
        other_book.reload
      end

      context "when filtering by August" do
        let(:result_august) { Book.most_borrowed(month: 8) }

        it "includes book" do
          expect(result_august).to include(book)
        end

        it "does not include other_book" do
          expect(result_august).not_to include(other_book)
        end
      end

      context "when filtering by January" do
        let(:result_january) { Book.most_borrowed(month: 1) }

        it "includes other_book" do
          expect(result_january).to include(other_book)
        end

        it "does not include book" do
          expect(result_january).not_to include(book)
        end
      end
    end

    it ".without_cover returns books without image" do
      expect(Book.without_cover).to include(book)
    end

    it ".with_cover returns books with image" do
      book.image.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/sample.png")),
        filename: "sample.png",
        content_type: "image/png"
      )
      book.reload
      expect(Book.with_cover).to include(book)
    end
  end

  # ---------------------------
  # Instance Methods
  # ---------------------------
  describe "#average_rating" do
    it "returns 0 when no reviews" do
      expect(book.average_rating).to eq(0)
    end

    it "calculates average score of reviews" do
      user1 = User.create!(name: "A", email: "a@test.com", password: "123456", gender: "male", date_of_birth: Date.new(1990,1,1))
      user2 = User.create!(name: "B", email: "b@test.com", password: "123456", gender: "female", date_of_birth: Date.new(1992,5,20))

      Review.create!(book: book, score: 4, user: user1)
      Review.create!(book: book, score: 5, user: user2)

      expect(book.average_rating).to eq(4.5)
    end

    it "rounds to 1 decimal place" do
      user1 = User.create!(name: "A", email: "a@test.com", password: "123456", gender: "male", date_of_birth: Date.new(1990,1,1))
      user2 = User.create!(name: "B", email: "b@test.com", password: "123456", gender: "female", date_of_birth: Date.new(1992,5,20))
      user3 = User.create!(name: "C", email: "c@test.com", password: "123456", gender: "female", date_of_birth: Date.new(1992,5,20))

      Review.create!(book: book, score: 4, user: user1)
      Review.create!(book: book, score: 5, user: user2)
      Review.create!(book: book, score: 2, user: user3)

      expect(book.average_rating).to eq(3.7)
    end
  end

  # ---------------------------
  # Class Methods
  # ---------------------------
  describe ".ransackable_attributes" do
    it "only allows searching by title" do
      expect(Book.ransackable_attributes).to eq(%w(title))
    end
  end

  # ---------------------------
  # Search Scope
  # ---------------------------
  describe ".search" do
    it "searches by title" do
      expect(Book.search("Book", :title)).to include(book)
    end

    it "searches by author" do
      expect(Book.search("Author", :author)).to include(book)
    end

    it "searches by publisher" do
      expect(Book.search("Publisher", :publisher)).to include(book)
    end

    it "searches by category" do
      category = Category.create!(name: "Fantasy")
      book.categories << category
      book.reload

      expect(Book.search("Fantasy", :category)).to include(book)
    end

    it "returns none when query is empty" do
      expect(Book.search("", :title)).to be_empty
    end

    it "searches by all fields" do
      expect(Book.search("Book", :all)).to include(book)
    end

    it "returns empty when query does not match" do
      expect(Book.search("xyz", :title)).to be_empty
    end
  end
end

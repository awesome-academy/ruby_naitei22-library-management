class Book < ApplicationRecord
  MAX_TITLE_LENGTH = 255
  MAX_DESCRIPTION_LENGTH = 1500
  MIN_PUBLICATION_YEAR = 1000
  MIN_TOTAL_QUANTITY = 0
  MIN_AVAILABLE_QUANTITY = 0
  MIN_BORROW_COUNT = 0

  has_one_attached :image

  belongs_to :author
  belongs_to :publisher
  has_many :book_categories, dependent: :destroy
  has_many :categories, through: :book_categories
  has_many :borrow_request_items, dependent: :destroy
  has_many :borrow_requests, through: :borrow_request_items
  has_many :reviews, dependent: :destroy
  has_many :favorites, as: :favorable, dependent: :destroy

  validates :title,
            presence: true,
            length: {
              maximum: MAX_TITLE_LENGTH
            }

  validates :description,
            length: {
              maximum: MAX_DESCRIPTION_LENGTH
            },
            allow_blank: true

  validates :publication_year,
            numericality: {
              only_integer: true,
              greater_than: MIN_PUBLICATION_YEAR
            },
            allow_nil: true

  validates :total_quantity,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than: MIN_TOTAL_QUANTITY
            }

  validates :available_quantity,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: MIN_AVAILABLE_QUANTITY,
              less_than_or_equal_to: :total_quantity
            }

  validates :borrow_count,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: MIN_BORROW_COUNT
            }

  validates :author_id,
            presence: true

  validates :publisher_id,
            presence: true

  scope :by_author, ->(author_id) {where(author_id:)}

  scope :exclude_book, ->(book_id) {where.not(id: book_id)}

  scope :recent, -> {order(created_at: :desc)}
  scope :with_cover, -> {joins(:image_attachment)}
  scope :without_cover, (lambda do
    left_joins(:image_attachment)
      .where(active_storage_attachments: {id: nil})
  end)

  scope :recommended, -> {order(publication_year: :desc)}

  def average_rating
    return Settings.digits.digit_0 if reviews.empty?

    reviews.average(:score).round(1)
  end

  scope :search, lambda {|query, search_type = :all|
    return none if query.blank?

    case search_type.to_sym
    when :title
      where("books.title LIKE ?", "%#{query}%")
    when :author
      joins(:author).where("authors.name LIKE ?", "%#{query}%")
    when :publisher
      joins(:publisher).where("publishers.name LIKE ?", "%#{query}%")
    when :category
      joins(:categories).where("categories.name LIKE ?", "%#{query}%")
    else # :all or any other value
      joins(:author, :publisher)
        .left_joins(:categories)
        .where(
          "books.title LIKE :query OR
           authors.name LIKE :query OR
           publishers.name LIKE :query OR
           categories.name LIKE :query",
          query: "%#{query}%"
        )
        .distinct
    end
  }
end

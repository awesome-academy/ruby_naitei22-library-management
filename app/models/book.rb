class Book < ApplicationRecord
  MAX_TITLE_LENGTH = 255
  MAX_DESCRIPTION_LENGTH = 1500
  MIN_PUBLICATION_YEAR = 1000
  MIN_TOTAL_QUANTITY = 0
  MIN_AVAILABLE_QUANTITY = 0
  MIN_BORROW_COUNT = 0

  BORROWED_SELECT_FIELDS = <<~SQL.squish
    books.id,
    books.title,
    books.total_quantity,
    books.available_quantity,
    books.author_id,
    COUNT(borrow_requests.id) AS borrow_count
  SQL

  BORROWED_GROUP_FIELDS = <<~SQL.squish
    books.id,
    books.title,
    books.total_quantity,
    books.available_quantity,
    books.author_id
  SQL

  has_one_attached :image

  belongs_to :author
  belongs_to :publisher
  has_many :book_categories, dependent: :destroy
  has_many :categories, through: :book_categories
  has_many :borrow_request_items, dependent: :restrict_with_error
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

  scope :most_borrowed, lambda {|month: nil, year: nil|
    joins(:borrow_requests)
      .then do |q|
        if year.present?
          q = q.where(
            "EXTRACT(YEAR FROM borrow_requests.request_date) = ?", year
          )
        end

        if month.present?
          q = q.where(
            "EXTRACT(MONTH FROM borrow_requests.request_date) = ?", month
          )
        end

        q
      end
      .select(BORROWED_SELECT_FIELDS)
      .group(BORROWED_GROUP_FIELDS)
      .order("borrow_count DESC")
  }

  scope :newest, -> {order(publication_year: :desc)}

  scope :most_borrow_count, -> {order(borrow_count: :desc)}

  scope :by_highest_rating, lambda { # rubocop:disable Layout/SpaceInsideBlockBraces
    left_joins(:reviews)
      .select("books.*, COALESCE(AVG(reviews.score), 0) AS avg_rating")
      .group("books.id")
      .order(Arel.sql("COALESCE(AVG(reviews.score), 0) DESC"))
  }

  scope :ordered_by_title, -> {order(:title)}

  ransacker :average_rating, type: :decimal do
    Arel.sql <<~SQL.squish
      (
        SELECT COALESCE(AVG(reviews.score), 0)
        FROM reviews
        WHERE reviews.book_id = books.id
      )
    SQL
  end

  # filter dynamic theo params[:filter]
  def self.filter_by filter, current_user = nil
    case filter
    when "newest"
      newest
    when "most_borrow_count"
      most_borrow_count
    when "highest_rating"
      by_highest_rating
    when "my_favorites"
      if current_user
        joins(:favorites)
          .where(favorites: {user_id: current_user.id})
      else
        none
      end
    else
      ordered_by_title
    end
  end

  def average_rating
    return Settings.digits.digit_0 if reviews.empty?

    reviews.average(:score).round(1)
  end

  def self.ransackable_attributes _auth_object = nil
    %w(title average_rating)
  end

  def self.ransackable_associations _auth_object = nil
    %w(author publisher categories favorites)
  end
end

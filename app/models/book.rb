class Book < ApplicationRecord
  MAX_TITLE_LENGTH = 255
  MAX_DESCRIPTION_LENGTH = 1500
  MIN_PUBLICATION_YEAR = 1000
  MIN_TOTAL_QUANTITY = 0
  MIN_AVAILABLE_QUANTITY = 0
  MIN_BORROW_COUNT = 0

  has_one_attached :cover_image

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

  scope :search, (lambda do |keyword|
    where("title LIKE ?", "%#{keyword}%") if keyword.present?
  end)
  scope :recent, -> {order(created_at: :desc)}
  scope :with_cover, -> {joins(:cover_image_attachment)}
  scope :without_cover, lambda birth_death_date_logic
    left_joins(:cover_image_attachment)
      .where(active_storage_attachments: {id: nil})
  end
end

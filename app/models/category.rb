class Category < ApplicationRecord
  MAX_NAME_LENGTH = 100
  MAX_DESCRIPTION_LENGTH = 500

  has_many :book_categories, dependent: :destroy
  has_many :books, through: :book_categories

  validates :name,
            presence: true,
            length: {maximum: MAX_NAME_LENGTH},
            uniqueness: {case_sensitive: false}
  validates :description,
            length: {maximum: MAX_DESCRIPTION_LENGTH},
            allow_blank: true

  scope :with_books, -> {joins(:books).distinct}
  scope :without_books, -> {left_joins(:books).where(books: {id: nil})}

  delegate :count, to: :books, prefix: true

  scope :recent, -> {order(created_at: :desc)}

  def self.ransackable_attributes(*)
    %w(name)
  end
end

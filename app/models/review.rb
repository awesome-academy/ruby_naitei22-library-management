class Review < ApplicationRecord
  belongs_to :user
  belongs_to :book

  validates :score,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 1,
              less_than_or_equal_to: 5
            }
  validates :comment, length: {maximum: 1000}, allow_blank: true

  validates :user_id, uniqueness: {scope: :book_id}

  scope :recent, -> {order(created_at: :desc)}
end

class Author < ApplicationRecord
  MAX_NAME_LENGTH = 255
  MAX_BIO_LENGTH = 2000
  MAX_NATIONALITY_LENGTH = 100

  has_one_attached :image

  has_many :books, dependent: :destroy
  has_many :favorites, as: :favorable, dependent: :destroy

  validates :name, presence: true, length: {maximum: MAX_NAME_LENGTH}
  validates :bio,
            length: {maximum: MAX_BIO_LENGTH},
            allow_blank: true
  validates :nationality,
            length: {maximum: MAX_NATIONALITY_LENGTH},
            allow_blank: true

  validates :birth_date,
            comparison: {less_than: Date.current},
            allow_nil: true

  validates :death_date,
            comparison: {greater_than: :birth_date},
            allow_nil: true

  validate :birth_death_date_logic

  scope :alive, -> {where(death_date: nil)}
  scope :deceased, -> {where.not(death_date: nil)}

  private

  def birth_death_date_logic
    return unless birth_date && death_date

    if death_date <= birth_date
      errors.add(:death_date, :after_birth)
    elsif death_date > Date.current
      errors.add(:death_date, :in_future)
    end
  end
end

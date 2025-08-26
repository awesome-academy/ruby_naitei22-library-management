class User < ApplicationRecord
  USER_PERMIT = %i(
    name email password password_confirmation date_of_birth gender
  ).freeze

  USER_OAUTH_SETUP_PERMIT = %i(
    password password_confirmation date_of_birth gender
  ).freeze
  USER_PERMIT_FOR_PASSWORD_RESET = %i(password password_confirmation).freeze
  FAVORITE_BOOKS_INCLUDES = [
    :author,
    :publisher,
    :categories,
    {image_attachment: :blob}
  ].freeze

  FAVORITE_AUTHORS_INCLUDES = [
    :books,
    :favorites,
    {image_attachment: :blob}
  ].freeze

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable

  has_one_attached :avatar
  has_one_attached :image

  enum role: {user: 0, admin: 1, super_admin: 2}
  enum gender: {male: 0, female: 1, other: 2}
  enum status: {inactive: 0, active: 1}

  has_many :reviews, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorite_books,
           through: :favorites,
           source: :favorable,
           source_type: Book.name
  has_many :favorite_authors, -> {where(favorable_type: Author.name)},
           class_name: Favorite.name, dependent: :destroy
  has_many :followed_authors,
           through: :favorite_authors,
           source: :favorable,
           source_type: Author.name

  has_many :borrow_requests, dependent: :destroy

  scope :recent, -> {order(created_at: :desc)}
  scope :order_by_created, -> {order(created_at: :asc)}

  scope :with_favorite_books_included, (lambda do
    includes(
      favorite_books: [
        :author,
        :publisher,
        :categories,
        {image_attachment: :blob}
      ]
    )
  end)

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  VALID_PHONE_REGEX = /\A\+?\d{10,15}\z/
  NAME_MAX_LENGTH = 50
  EMAIL_MAX_LENGTH = 255
  MAX_YEARS_AGO = 100

  validates :name, presence: true, length: {maximum: NAME_MAX_LENGTH}
  validates :email, presence: true,
                    length: {maximum: EMAIL_MAX_LENGTH},
                    format: {with: VALID_EMAIL_REGEX},
                    uniqueness: {case_sensitive: false}
  validate :date_of_birth_must_be_within_last_100_years
  validates :gender, presence: true
  validates :phone_number,
            format: {with: VALID_PHONE_REGEX, message: :invalid_phone_number},
            allow_blank: true
  validates :address, length: {maximum: 500}, allow_blank: true
  validate :password_presence_if_confirmation_provided

  def favorited? item
    favorites.exists?(favorable: item)
  end

  def ordered_favorite_books_with_includes
    favorite_books.includes(FAVORITE_BOOKS_INCLUDES)
                  .order("favorites.created_at DESC")
  end

  def ordered_favorite_authors_with_includes
    followed_authors.includes(FAVORITE_AUTHORS_INCLUDES)
  end

  def date_of_birth_must_be_within_last_100_years
    return if date_of_birth.blank?

    if date_of_birth < MAX_YEARS_AGO.years.ago.to_date
      errors.add(:date_of_birth, :past_max_year)
    elsif date_of_birth > Time.zone.today
      errors.add(:date_of_birth, :in_future)
    end
  end

  # Cho OmniAuth
  def self.from_omniauth auth
    user = find_by(email: auth.info.email)

    if user
      user.update(provider: auth.provider, uid: auth.uid)
      user
    else
      create(
        name: auth.info.name,
        email: auth.info.email,
        provider: auth.provider,
        uid: auth.uid,
        gender: :other,
        date_of_birth: 18.years.ago.to_date,
        status: :active,
        password: SecureRandom.hex(16)
      )
    end
  end

  def oauth_user?
    provider.present?
  end

  def needs_password_setup?
    oauth_user? && created_at == updated_at
  end

  def self.ransackable_attributes _auth_object = nil
    %w(
      id
      name
      email
      phone_number
      role
      status
      created_at
    )
  end

  private

  def downcase_email
    email.downcase!
  end

  def password_presence_if_confirmation_provided
    return unless password.blank? && password_confirmation.present?

    errors.add(:password, :password_blank)
  end
end

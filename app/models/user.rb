class User < ApplicationRecord
  USER_PERMIT = %i(name email password password_confirmation date_of_birth
gender).freeze
  USER_OAUTH_SETUP_PERMIT = %i(password password_confirmation date_of_birth
gender).freeze
  USER_PERMIT_FOR_PASSWORD_RESET = %i(password password_confirmation).freeze
  FAVORITE_BOOKS_INCLUDES = [:author, :publisher, :categories,
{image_attachment: :blob}].freeze
  FAVORITE_AUTHORS_INCLUDES = [:books, :favorites,
{image_attachment: :blob}].freeze

  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :confirmable,
         :omniauthable,
         omniauth_providers: [:google_oauth2] #
  # has_secure_password
  # has_secure_password cung cấp: # rubocop:disable Style/AsciiComments
  # - Các thuộc tính ảo: password, password_confirmation # rubocop:disable Style/AsciiComments
  # - Trường password_digest để lưu hash # rubocop:disable Style/AsciiComments
  # - Phương thức authenticate(password) để xác thực # rubocop:disable Style/AsciiComments

  enum role: {user: 0, admin: 1, super_admin: 2}
  enum gender: {male: 0, female: 1, other: 2}
  enum status: {inactive: 0, active: 1}

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  VALID_PHONE_REGEX = /\A\+?\d{10,15}\z/
  NAME_MAX_LENGTH = 50
  EMAIL_MAX_LENGTH = 255
  MAX_YEARS_AGO = 100

  has_many :reviews, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorite_books, through: :favorites, source: :favorable,
            source_type: Book.name
  has_many :favorite_authors, -> {where(favorable_type: Author.name)},
           class_name: Favorite.name, dependent: :destroy
  has_many :followed_authors, through: :favorite_authors, source: :favorable,
           source_type: Author.name
  has_many :borrow_requests, dependent: :destroy
  has_one_attached :avatar
  has_one_attached :image

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

  validates :name, presence: true, length: {maximum: NAME_MAX_LENGTH}
  validates :email,
            presence: true,
            length: {maximum: EMAIL_MAX_LENGTH},
            format: {with: VALID_EMAIL_REGEX},
            uniqueness: {case_sensitive: false}
  validate :date_of_birth_must_be_within_last_100_years
  validates :gender, presence: true
  validates :password, presence: true,
                     length: {minimum: Settings.digits.digit_6},
                     allow_nil: true,
                     if: :password_required?
  validates :phone_number,
            format: {with: VALID_PHONE_REGEX, message: :invalid_phone_number},
            allow_blank: true

  validates :address,
            length: {maximum: 500},
            allow_blank: true

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

  def active_for_authentication?
    super && active?
  end

  def inactive_message
    active? ? super : :account_inactive
  end

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

  def self.from_omniauth auth
    user = find_existing_user(auth)
    return update_user_provider(user, auth) if user

    create_user_from_omniauth(auth)
  end

  def self.find_existing_user auth
    find_by(provider: auth.provider,
            uid: auth.uid) || find_by(email: auth.info.email)
  end

  def self.update_user_provider user, auth
    unless user.provider && user.uid
      user.update(provider: auth.provider, uid: auth.uid)
    end
    user
  end

  def self.create_user_from_omniauth auth
    create!(
      name: auth.info.name,
      email: auth.info.email,
      provider: auth.provider,
      uid: auth.uid,
      gender: :other,
      date_of_birth: 18.years.ago.to_date,
      status: :active,
      password: Devise.friendly_token[0, 20],
      confirmed_at: Time.current
    )
  end
end

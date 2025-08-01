class User < ApplicationRecord
  USER_PERMIT = %i(name email password password_confirmation date_of_birth
gender).freeze

  USER_PERMIT_FOR_PASSWORD_RESET = %i(password password_confirmation).freeze

  has_secure_password
  # has_secure_password cung cấp: # rubocop:disable Style/AsciiComments
  # - Các thuộc tính ảo: password, password_confirmation # rubocop:disable Style/AsciiComments
  # - Trường password_digest để lưu hash # rubocop:disable Style/AsciiComments
  # - Phương thức authenticate(password) để xác thực # rubocop:disable Style/AsciiComments

  enum gender: {male: 0, female: 1, other: 2}

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  NAME_MAX_LENGTH = 50
  EMAIL_MAX_LENGTH = 255
  MAX_YEARS_AGO = 100

  attr_accessor :remember_token, :activation_token, :reset_token

  before_save :downcase_email
  before_create :create_activation_digest

  scope :recent, -> {order(created_at: :desc)}

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
  validate :password_presence_if_confirmation_provided

  def date_of_birth_must_be_within_last_100_years
    return if date_of_birth.blank?

    if date_of_birth < MAX_YEARS_AGO.years.ago.to_date
      errors.add(:date_of_birth, :past_max_year)
    elsif date_of_birth > Time.zone.today
      errors.add(:date_of_birth, :in_future)
    end
  end

  def remember
    self.remember_token = User.new_token
    update_column :remember_digest, User.digest(remember_token)
  end

  def forget
    update_column :remember_digest, nil
  end

  def authenticated? attribute, token
    digest = send "#{attribute}_digest"
    return false unless digest

    BCrypt::Password.new(digest).is_password? token
  end

  def activate
    update_columns(activated: true, activated_at: Time.zone.now)
  end

  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  def create_reset_digest
    self.reset_token = User.new_token
    update_columns reset_digest: User.digest(reset_token),
                   reset_sent_at: Time.zone.now
  end

  def password_reset_expired?
    reset_sent_at < Settings.mailer.expire_hour.hours.ago
  end

  class << self
    def digest string
      cost = if ActiveModel::SecurePassword.min_cost
               BCrypt::Engine::MIN_COST
             else
               BCrypt::Engine.cost
             end
      BCrypt::Password.create(string, cost:)
    end

    def new_token
      SecureRandom.urlsafe_base64
    end
  end

  private

  def downcase_email
    email.downcase!
  end

  def password_required?
    password_digest.blank? || !password.nil?
  end

  def password_presence_if_confirmation_provided
    if password.blank? && password_confirmation.present? # rubocop:disable Style/GuardClause
      errors.add(:password, :password_blank)
    end
  end

  def create_activation_digest
    self.activation_token = User.new_token
    self.activation_digest = User.digest(activation_token)
  end
end

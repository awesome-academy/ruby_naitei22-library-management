class Publisher < ApplicationRecord
  MAX_NAME_LENGTH = 255
  MAX_ADDRESS_LENGTH = 500
  MAX_PHONE_NUMBER_LENGTH = 20
  MAX_EMAIL_LENGTH = 255
  MAX_WEBSITE_LENGTH = 255

  PHONE_FORMAT = /\A[\d\-+()\s]+\z/
  EMAIL_FORMAT = URI::MailTo::EMAIL_REGEXP
  WEBSITE_FORMAT = %r{\Ahttps?://.+\z}

  has_many :books, dependent: :destroy

  validates :name,
            presence: true,
            length: {maximum: MAX_NAME_LENGTH},
            uniqueness: true
  validates :address,
            length: {maximum: MAX_ADDRESS_LENGTH},
            allow_blank: true
  validates :phone_number,
            length: {maximum: MAX_PHONE_NUMBER_LENGTH},
            format: {with: PHONE_FORMAT},
            allow_blank: true
  validates :email,
            length: {maximum: MAX_EMAIL_LENGTH},
            format: {with: EMAIL_FORMAT},
            allow_blank: true
  validates :website,
            length: {maximum: MAX_WEBSITE_LENGTH},
            format: {with: WEBSITE_FORMAT},
            allow_blank: true
end

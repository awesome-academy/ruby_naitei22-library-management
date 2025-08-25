# frozen_string_literal: true

Devise.setup do |config|
  # Mailer
  config.mailer_sender = 'please-change-me-at-config-initializers-devise@example.com'

  # ORM
  require 'devise/orm/active_record'

  # Case-insensitive & strip whitespace for email
  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]

  # Skip session storage for http_auth
  config.skip_session_storage = [:http_auth]

  # Password config
  config.stretches = Rails.env.test? ? 1 : 12
  config.password_length = 6..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/

  # Confirmable
  config.reconfirmable = true

  # Rememberable
  config.expire_all_remember_me_on_sign_out = true

  # Lockable
  config.lock_strategy = :failed_attempts
  config.unlock_strategy = :both
  config.maximum_attempts = 5
  config.unlock_in = 10.minutes
  config.last_attempt_warning = true

  # Recoverable (reset password)
  config.reset_password_within = 6.hours

  # Sign out
  config.sign_out_via = :delete

  # ==> OmniAuth
  # Đăng nhập bằng Google
  config.omniauth :google_oauth2,
                  ENV["GOOGLE_CLIENT_ID"],
                  ENV["GOOGLE_CLIENT_SECRET"],
                  {
                    scope: "email,profile",
                    prompt: "select_account",
                    path_prefix: "/auth"
                  }

  # Turbo / Hotwire responder
  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other
end

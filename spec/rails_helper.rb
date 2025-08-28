require 'simplecov'
SimpleCov.start 'rails' do
  add_filter '/bin/'
  add_filter '/db/'
  add_filter '/spec/'
end

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
abort("The Rails environment is running in production mode!") if Rails.env.production?

require 'rspec/rails'
require 'rails-controller-testing'

require 'spec_helper'

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    # Sử dụng cho RSpec
    with.test_framework :rspec
    # Tích hợp với Rails
    with.library :rails
  end
end

# Tự động load file trong spec/support nếu bạn có tạo helper riêng
# Dir[Rails.root.join('spec/support/**/*.rb')].sort.each { |f| require f }

Rails::Controller::Testing.install

RSpec.configure do |config|
  # FactoryBot syntax methods (allow dùng create, build trực tiếp)
  config.include FactoryBot::Syntax::Methods
  # Tắt transactional fixtures của Rails
  config.use_transactional_fixtures = false

  # DatabaseCleaner setup
  config.before(:suite) do
    ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS = 0;")
    DatabaseCleaner.clean_with(:truncation, reset_ids: true)
    ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS = 1;")
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  # Nếu dùng Capybara JS
  config.before(:each, type: :system) do
    DatabaseCleaner.strategy = :truncation
  end
end

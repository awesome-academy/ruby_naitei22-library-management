FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "User #{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    gender { :male }
    date_of_birth { 25.years.ago.to_date }
    status { :active }

    trait :oauth_user do
      provider { "google" }
      uid { "12345" }
    end

    trait :remembered do
      remember_created_at { 1.hour.ago }
    end
  end
end

FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "User #{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "123456" }
    password_confirmation { "123456" }
    date_of_birth { Faker::Date.between(from: "1980-01-01", to: "2005-12-31") }
    gender { %w[male female].sample }
    activated_at { Time.zone.now }

    trait :admin do
      role { "admin" }
    end

    trait :regular do
      role { "user" }
    end
  end
end

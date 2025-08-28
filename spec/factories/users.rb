FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "User #{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "123456" }
    gender { "male" }
    date_of_birth { "1990-01-01" }
    confirmed_at { Time.current }

    trait :admin do
      role { "admin" }
    end

    trait :regular do
      role { "user" }
    end
  end
end

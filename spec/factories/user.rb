FactoryBot.define do
  factory :user do
    name {"Test User"}
    email {Faker::Internet.email}
    password {"password"}
    confirmed_at {Time.current}
    gender {:male}
    date_of_birth {Faker::Date.birthday(min_age: 18, max_age: 65)}
  end
end

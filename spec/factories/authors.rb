FactoryBot.define do
  factory :author do
    sequence(:name) { |n| "Tác giả #{n}" }
    nationality { ["Việt Nam", "Mỹ", "Anh", "Nhật Bản", "Pháp", "Israel"].sample }
    birth_date { Faker::Date.birthday(min_age: 30, max_age: 90) }
    death_date { nil }
  end
end

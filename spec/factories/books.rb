FactoryBot.define do
  factory :book do
    sequence(:title) { |n| "Sách #{n}" }
    description { "Mô tả cho sách #{title}" }
    publication_year { Faker::Number.between(from: 1950, to: 2025) }
    total_quantity { Faker::Number.between(from: 10, to: 50) }
    available_quantity { total_quantity }
    borrow_count { 0 }

    association :author
    association :publisher
  end
end

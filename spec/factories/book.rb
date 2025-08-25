FactoryBot.define do
  factory :book do
    sequence(:title) { |n| "Book #{n}" }
    description { "Sample description" }
    publication_year { 2020 }
    total_quantity { 5 }
    available_quantity { 5 }
    association :author
    association :publisher
  end
end

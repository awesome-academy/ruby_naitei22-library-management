FactoryBot.define do
  factory :author do
    sequence(:name) { |n| "Author #{n}" }
    bio { "Sample bio" }
    nationality { "Sample Nationality" }
  end
end

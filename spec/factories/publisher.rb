FactoryBot.define do
  factory :publisher do
    sequence(:name) { |n| "Publisher #{n}" }
    sequence(:email) { |n| "publisher#{n}@example.com" }
    address { "Sample address" }
  end
end

FactoryBot.define do
  factory :review do
    score { rand(1..5) }
    association :book
    association :user
  end
end

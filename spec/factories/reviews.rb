FactoryBot.define do
  factory :review do
    score { 5 }
    comment { "Great book!" }
    association :book
    association :user
  end
end

FactoryBot.define do
  factory :favorite do
    association :user
    association :favorable, factory: :book
  end
end

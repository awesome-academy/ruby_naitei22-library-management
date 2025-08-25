FactoryBot.define do
  factory :favorite_author do
    association :user
    association :author
  end
end

FactoryBot.define do
  factory :favorite do
    association :user

    association :favorable, factory: :author

    trait :for_book do
      association :favorable, factory: :book
    end

    trait :for_author do
      association :favorable, factory: :author
    end
  end
end

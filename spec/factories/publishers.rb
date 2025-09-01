FactoryBot.define do
  factory :publisher do
    sequence(:name) { |n| "Nhà xuất bản #{n}" }
    address { Faker::Address.full_address }
  end
end

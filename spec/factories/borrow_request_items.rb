FactoryBot.define do
  factory :borrow_request_item do
    association :borrow_request
    association :book
    quantity { 1 }
  end
end

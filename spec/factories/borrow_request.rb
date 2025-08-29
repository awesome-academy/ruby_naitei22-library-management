FactoryBot.define do
  factory :borrow_request do
    association :user
    request_date { Time.zone.now }
    start_date { Date.today + 1 }
    end_date { Date.today + 2 }
    status { :pending }
  end
end

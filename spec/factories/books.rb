FactoryBot.define do
  factory :book do
    sequence(:title) { |n| "Sách #{n}" }
    description { "Mô tả cho sách #{title}" }
    publication_year { Faker::Number.between(from: 1950, to: 2025) }
    total_quantity { Faker::Number.between(from: 10, to: 50) }
    available_quantity { total_quantity }
    borrow_count { 0 }

    association :author
    association :publisher

    after(:create) do |book, _evaluator|
      # Attach image nếu file tồn tại
      cover_path = Rails.root.join("lib", "assets", "book_covers", "book_#{book.id}.jpg")
      if File.exist?(cover_path)
        book.image.attach(
          io: File.open(cover_path),
          filename: "book_#{book.id}.jpg",
          content_type: "image/jpeg"
        )
      end
    end
  end
end

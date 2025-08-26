# encoding: utf-8

attach_image = ->(book) do
  cover_path = Rails.root.join("lib", "assets", "book_covers", "book_#{book.id}.jpg")

  if File.exist?(cover_path)
    book.image.attach(
      io: File.open(cover_path),
      filename: "book_#{book.id}.jpg",
      content_type: 'image/jpeg'
    )
    puts "✅ Đã thêm ảnh bìa cho sách #{book.id}: #{book.title}"
  else
    puts "⚠️  Chưa có ảnh bìa cho sách #{book.id}: #{book.title} (đường dẫn: #{cover_path})"
  end
end

puts "🌱 Đang tạo dữ liệu mẫu cho hệ thống thư viện..."

puts "🧹 Đang xóa dữ liệu cũ..."
[Review, Favorite, BorrowRequestItem, BorrowRequest, BookCategory, Book, Category, Author, Publisher, User].each(&:destroy_all)

puts "📚 Đang tạo thể loại sách..."
categories = [
  { name: "Tiểu thuyết", description: "Tác phẩm văn học dài" },
  { name: "Khoa học", description: "Sách về các chủ đề khoa học" },
  { name: "Lập trình", description: "Sách dạy lập trình" },
  { name: "Kinh tế", description: "Sách về kinh tế, tài chính" },
  { name: "Lịch sử", description: "Sách về lịch sử" },
  { name: "Tâm lý học", description: "Sách về tâm lý con người" },
  { name: "Truyện ngắn", description: "Tập hợp các truyện ngắn" },
  { name: "Trinh thám", description: "Truyện trinh thám, hình sự" },
  { name: "Fantasy", description: "Thể loại giả tưởng" },
  { name: "Thiếu nhi", description: "Sách dành cho trẻ em" },
  { name: "Kỹ năng", description: "Sách phát triển bản thân" },
  { name: "Văn hóa", description: "Sách về văn hóa các nước" }
].map { |cat| Category.create!(cat) }

puts "👨‍💼 Đang tạo tài khoản admin..."
admin = User.create!(
  name: "Quản trị viên",
  email: "admin@thuvien.com",
  password: "123456",
  password_confirmation: "123456",
  date_of_birth: Date.new(1990, 1, 1),
  gender: "male",
  role: "admin",
  confirmed_at: Time.zone.now,
  status: "active"
)

puts "👥 Đang tạo người dùng thường..."
users = [
  { name: "Nguyễn Văn An", email: "nguyenvanan@example.com", gender: "male", dob: "1990-01-12" },
  { name: "Trần Thị Hoa", email: "tranthihoa@example.com", gender: "female", dob: "1992-03-25" },
  { name: "Lê Văn Minh", email: "levanminh@example.com", gender: "male", dob: "1988-07-09" },
  { name: "Phạm Thị Hồng", email: "phamthihong@example.com", gender: "female", dob: "1995-10-14" },
  { name: "Hoàng Văn Quang", email: "hoangvanquang@example.com", gender: "male", dob: "1991-06-18" },
  { name: "Đỗ Thị Lan", email: "dothilan@example.com", gender: "female", dob: "1993-04-02" },
  { name: "Bùi Văn Nam", email: "buivannam@example.com", gender: "male", dob: "1989-08-30" },
  { name: "Vũ Thị Mai", email: "vuthimai@example.com", gender: "female", dob: "1996-12-21" },
  { name: "Ngô Văn Khánh", email: "ngovankhanh@example.com", gender: "male", dob: "1994-05-11" },
  { name: "Đặng Thị Yến", email: "dangthiyen@example.com", gender: "female", dob: "1990-09-27" },
  { name: "Trịnh Văn Hùng", email: "trinhvanhung@example.com", gender: "male", dob: "1992-02-14" },
  { name: "Lương Thị Hạnh", email: "luongthihanh@example.com", gender: "female", dob: "1997-11-08" },
  { name: "Phan Văn Tuấn", email: "phanvantuan@example.com", gender: "male", dob: "1987-03-19" },
  { name: "Tạ Thị Thu", email: "tathithu@example.com", gender: "female", dob: "1995-07-23" },
  { name: "Nguyễn Văn Lâm", email: "nguyenvanlam@example.com", gender: "male", dob: "1991-10-05" },
  { name: "Trần Thị Vân", email: "tranthivan@example.com", gender: "female", dob: "1989-01-28" },
  { name: "Lê Văn Hoàng", email: "levanhoang@example.com", gender: "male", dob: "1993-06-17" },
  { name: "Phạm Thị Thảo", email: "phamthithao@example.com", gender: "female", dob: "1994-08-12" },
  { name: "Hoàng Văn Dũng", email: "hoangvandung@example.com", gender: "male", dob: "1988-05-03" },
  { name: "Đỗ Thị Ngọc", email: "dothingoc@example.com", gender: "female", dob: "1992-12-15" },
  { name: "Bùi Văn Toàn", email: "buivantoan@example.com", gender: "male", dob: "1990-07-19" },
  { name: "Vũ Thị Kim", email: "vuthikim@example.com", gender: "female", dob: "1996-03-07" },
  { name: "Ngô Văn Huy", email: "ngovanhuy@example.com", gender: "male", dob: "1991-09-14" },
  { name: "Đặng Thị Nhung", email: "dangthinhung@example.com", gender: "female", dob: "1987-11-30" },
  { name: "Trịnh Văn Phúc", email: "trinhvanphuc@example.com", gender: "male", dob: "1994-04-28" },
  { name: "Lương Thị Thanh", email: "luongthithanh@example.com", gender: "female", dob: "1993-08-16" },
  { name: "Phan Văn Hòa", email: "phanvanhoa@example.com", gender: "male", dob: "1989-02-09" },
  { name: "Tạ Thị Hương", email: "tatihuong@example.com", gender: "female", dob: "1995-06-22" },
  { name: "Nguyễn Văn Phong", email: "nguyenvanphong@example.com", gender: "male", dob: "1990-10-18" },
  { name: "Trần Thị Tâm", email: "tranthitam@example.com", gender: "female", dob: "1992-01-26" }
].map do |u|
  User.create!(
    name: u[:name],
    email: u[:email],
    password: "123456",
    password_confirmation: "123456",
    gender: u[:gender],
    date_of_birth: Date.parse(u[:dob]),
    confirmed_at: Time.zone.now,
    status: "active"
  )
end

puts "✍️ Đang tạo tác giả..."
authors = [
  { name: "Nguyễn Nhật Ánh", nationality: "Việt Nam", birth_date: "1955-05-07" },
  { name: "J.K. Rowling", nationality: "Anh", birth_date: "1965-07-31" },
  { name: "Stephen King", nationality: "Mỹ", birth_date: "1947-09-21" },
  { name: "Haruki Murakami", nationality: "Nhật Bản", birth_date: "1949-01-12" },
  { name: "Paulo Coelho", nationality: "Brazil", birth_date: "1947-08-24" },
  { name: "Nguyễn Ngọc Tư", nationality: "Việt Nam", birth_date: "1976-03-06" },
  { name: "Tô Hoài", nationality: "Việt Nam", birth_date: "1920-09-27", death_date: "2014-07-06" },
  { name: "Nam Cao", nationality: "Việt Nam", birth_date: "1917-10-29", death_date: "1951-11-30" },
  { name: "George Orwell", nationality: "Anh", birth_date: "1903-06-25", death_date: "1950-01-21" },
  { name: "Ernest Hemingway", nationality: "Mỹ", birth_date: "1899-07-21", death_date: "1961-07-02" }
].map { |a| Author.create!(a) }

puts "🏢 Đang tạo nhà xuất bản..."
publishers = [
  { name: "Nhà xuất bản Trẻ", address: "TP.HCM, Việt Nam" },
  { name: "Nhà xuất bản Kim Đồng", address: "Hà Nội, Việt Nam" },
  { name: "Penguin Random House", address: "New York, Mỹ" },
  { name: "HarperCollins", address: "London, Anh" },
  { name: "Simon & Schuster", address: "New York, Mỹ" },
  { name: "Nhà xuất bản Hội Nhà Văn", address: "Hà Nội, Việt Nam" },
  { name: "Nhà xuất bản Phụ Nữ", address: "Hà Nội, Việt Nam" }
].map { |p| Publisher.create!(p) }

puts "📖 Đang tạo 30 cuốn sách..."
books = [
  {
    title: "Tôi thấy hoa vàng trên cỏ xanh",
    description: "Câu chuyện tuổi thơ ở làng quê Việt Nam",
    publication_year: 2010,
    author: authors[0],
    publisher: publishers[0],
    categories: [categories[9]],
    total_quantity: 15,
    available_quantity: 12
  },
  {
    title: "Harry Potter và Hòn đá Phù thủy",
    description: "Câu chuyện về cậu bé phù thủy Harry Potter",
    publication_year: 1997,
    author: authors[1],
    publisher: publishers[2],
    categories: [categories[8]],
    total_quantity: 20,
    available_quantity: 18
  },
  {
    title: "Đắc nhân tâm",
    description: "Sách về nghệ thuật giao tiếp và đối nhân xử thế",
    publication_year: 1936,
    author: authors[4],
    publisher: publishers[3],
    categories: [categories[10]],
    total_quantity: 25,
    available_quantity: 20
  },
  {
    title: "Nhà giả kim",
    description: "Hành trình đi tìm kho báu và ý nghĩa cuộc sống",
    publication_year: 1988,
    author: authors[4],
    publisher: publishers[3],
    categories: [categories[0]],
    total_quantity: 18,
    available_quantity: 15
  },
  {
    title: "Rừng Na Uy",
    description: "Tiểu thuyết tình yêu và nỗi cô đơn",
    publication_year: 1987,
    author: authors[3],
    publisher: publishers[4],
    categories: [categories[0]],
    total_quantity: 12,
    available_quantity: 10
  },
  {
    title: "1984",
    description: "Tiểu thuyết dystopian về xã hội toàn trị",
    publication_year: 1949,
    author: authors[8],
    publisher: publishers[2],
    categories: [categories[0]],
    total_quantity: 15,
    available_quantity: 13
  },
  {
    title: "Dế Mèn phiêu lưu ký",
    description: "Tác phẩm văn học thiếu nhi kinh điển",
    publication_year: 1941,
    author: authors[6],
    publisher: publishers[1],
    categories: [categories[9]],
    total_quantity: 20,
    available_quantity: 18
  },
  {
    title: "Số đỏ",
    description: "Tiểu thuyết trào phúng về xã hội Việt Nam đầu thế kỷ 20",
    publication_year: 1936,
    author: authors[7],
    publisher: publishers[5],
    categories: [categories[0]],
    total_quantity: 10,
    available_quantity: 8
  },
  {
    title: "Đi tìm lẽ sống",
    description: "Câu chuyện của một người sống sót từ trại tập trung",
    publication_year: 1946,
    author: Author.create!(name: "Viktor Frankl", nationality: "Áo", birth_date: "1905-03-26", death_date: "1997-09-02"),
    publisher: publishers[4],
    categories: [categories[5]],
    total_quantity: 12,
    available_quantity: 10
  },
  {
    title: "Cà phê cùng Tony",
    description: "Tập hợp những bài viết truyền cảm hứng",
    publication_year: 2015,
    author: Author.create!(name: "Tony Buổi Sáng", nationality: "Việt Nam"),
    publisher: publishers[0],
    categories: [categories[10]],
    total_quantity: 30,
    available_quantity: 25
  },
  {
    title: "Clean Code",
    description: "Sách về cách viết code sạch cho lập trình viên",
    publication_year: 2008,
    author: Author.create!(name: "Robert C. Martin", nationality: "Mỹ"),
    publisher: publishers[4],
    categories: [categories[2]],
    total_quantity: 15,
    available_quantity: 12
  },
  {
    title: "Design Patterns",
    description: "Các mẫu thiết kế trong lập trình hướng đối tượng",
    publication_year: 1994,
    author: Author.create!(name: "Gang of Four", nationality: "Mỹ"),
    publisher: publishers[4],
    categories: [categories[2]],
    total_quantity: 10,
    available_quantity: 8
  },
  {
    title: "Bố già",
    description: "Tiểu thuyết về gia đình mafia Corleone",
    publication_year: 1969,
    author: Author.create!(name: "Mario Puzo", nationality: "Mỹ"),
    publisher: publishers[2],
    categories: [categories[0]],
    total_quantity: 18,
    available_quantity: 15
  },
  {
    title: "Những người khốn khổ",
    description: "Kiệt tác văn học của Victor Hugo",
    publication_year: 1862,
    author: Author.create!(name: "Victor Hugo", nationality: "Pháp"),
    publisher: publishers[3],
    categories: [categories[4]],
    total_quantity: 12,
    available_quantity: 10
  },
  {
    title: "Sherlock Holmes",
    description: "Tuyển tập truyện trinh thám kinh điển",
    publication_year: 1887,
    author: Author.create!(name: "Arthur Conan Doyle", nationality: "Anh"),
    publisher: publishers[3],
    categories: [categories[7]],
    total_quantity: 15,
    available_quantity: 12
  },
  {
    title: "Trí tuệ do thái",
    description: "Sách về tư duy và cách sống của người Do Thái",
    publication_year: 2010,
    author: Author.create!(name: "Eran Katz", nationality: "Israel"),
    publisher: Publisher.create!(name: "Nhà xuất bản Thế giới", address: "Hà Nội, Việt Nam"),
    categories: [categories[10]],
    total_quantity: 20,
    available_quantity: 18
  },
  {
    title: "Đọc vị bất kỳ ai",
    description: "Sách về tâm lý và cách đọc suy nghĩ người khác",
    publication_year: 2007,
    author: Author.create!(name: "David J. Lieberman", nationality: "Mỹ"),
    publisher: Publisher.create!(name: "Nhà xuất bản Lao động", address: "Hà Nội, Việt Nam"),
    categories: [categories[5]],
    total_quantity: 25,
    available_quantity: 20
  },
  {
    title: "Nhà lãnh đạo không chức danh",
    description: "Sách về phát triển khả năng lãnh đạo",
    publication_year: 2010,
    author: Author.create!(name: "Robin Sharma", nationality: "Canada"),
    publisher: Publisher.create!(name: "Nhà xuất bản Trí Việt", address: "TP.HCM, Việt Nam"),
    categories: [categories[10]],
    total_quantity: 15,
    available_quantity: 12
  },
  {
    title: "Tuổi trẻ đáng giá bao nhiêu",
    description: "Sách truyền cảm hứng cho giới trẻ",
    publication_year: 2016,
    author: Author.create!(name: "Rosie Nguyễn", nationality: "Việt Nam"),
    publisher: publishers[0],
    categories: [categories[10]],
    total_quantity: 30,
    available_quantity: 25
  },
  {
    title: "Tôi đi code dạo",
    description: "Hành trình trở thành lập trình viên",
    publication_year: 2017,
    author: Author.create!(name: "Phạm Huy Hoàng", nationality: "Việt Nam"),
    publisher: Publisher.create!(name: "Nhà xuất bản Thanh Niên", address: "TP.HCM, Việt Nam"),
    categories: [categories[2]],
    total_quantity: 20,
    available_quantity: 18
  },
  {
    title: "Lược sử thời gian",
    description: "Sách về vũ trụ và vật lý lý thuyết",
    publication_year: 1988,
    author: Author.create!(name: "Stephen Hawking", nationality: "Anh"),
    publisher: publishers[3],
    categories: [categories[1]],
    total_quantity: 15,
    available_quantity: 12
  },
  {
    title: "Sapiens: Lược sử loài người",
    description: "Lịch sử tiến hóa của loài người",
    publication_year: 2011,
    author: Author.create!(name: "Yuval Noah Harari", nationality: "Israel"),
    publisher: publishers[3],
    categories: [categories[1]],
    total_quantity: 18,
    available_quantity: 15
  },
  {
    title: "Chiến tranh và hòa bình",
    description: "Tiểu thuyết sử thi về xã hội Nga thời Napoleon",
    publication_year: 1869,
    author: Author.create!(name: "Leo Tolstoy", nationality: "Nga"),
    publisher: publishers[2],
    categories: [categories[4]],
    total_quantity: 10,
    available_quantity: 8
  },
  {
    title: "Bắt trẻ đồng xanh",
    description: "Tiểu thuyết về tuổi trẻ nổi loạn",
    publication_year: 1951,
    author: Author.create!(name: "J.D. Salinger", nationality: "Mỹ"),
    publisher: publishers[2],
    categories: [categories[0]],
    total_quantity: 15,
    available_quantity: 12
  },
  {
    title: "Ông già và biển cả",
    description: "Câu chuyện về lão ngư dân và con cá kiếm",
    publication_year: 1952,
    author: authors[9],
    publisher: publishers[2],
    categories: [categories[0]],
    total_quantity: 12,
    available_quantity: 10
  },
  {
    title: "Mắt biếc",
    description: "Câu chuyện tình yêu tuổi học trò",
    publication_year: 1990,
    author: authors[0],
    publisher: publishers[0],
    categories: [categories[0]],
    total_quantity: 20,
    available_quantity: 18
  },
  {
    title: "Cho tôi xin một vé đi tuổi thơ",
    description: "Hồi ức về tuổi thơ với những trò chơi và kỷ niệm",
    publication_year: 2008,
    author: authors[0],
    publisher: publishers[0],
    categories: [categories[0]],
    total_quantity: 25,
    available_quantity: 20
  },
  {
    title: "Cánh đồng bất tận",
    description: "Tập truyện ngắn về vùng đất Nam Bộ",
    publication_year: 2005,
    author: authors[5],
    publisher: publishers[6],
    categories: [categories[6]],
    total_quantity: 15,
    available_quantity: 12
  },
  {
    title: "Chí Phèo",
    description: "Kiệt tác văn học hiện thực phê phán",
    publication_year: 1941,
    author: authors[7],
    publisher: publishers[5],
    categories: [categories[0]],
    total_quantity: 20,
    available_quantity: 18
  },
  {
    title: "Lão Hạc",
    description: "Truyện ngắn về số phận người nông dân",
    publication_year: 1943,
    author: authors[7],
    publisher: publishers[5],
    categories: [categories[6]],
    total_quantity: 15,
    available_quantity: 12
  }
].map do |book_data|
  book = Book.create!(
    title: book_data[:title],
    description: book_data[:description],
    publication_year: book_data[:publication_year],
    author: book_data[:author],
    publisher: book_data[:publisher],
    total_quantity: book_data[:total_quantity],
    available_quantity: book_data[:available_quantity],
    borrow_count: book_data[:total_quantity] - book_data[:available_quantity]
  )

  book_data[:categories].each { |cat| book.categories << cat }

  # Attach cover image
  attach_image.call(book)
  book
end

puts "⭐ Đang tạo đánh giá..."
reviews = [
  { user: users[0], book: books[0], score: 5, comment: "Sách rất hay, cảm xúc dạt dào" },
  { user: users[1], book: books[0], score: 4, comment: "Đọc mà nhớ lại tuổi thơ" },
  { user: users[2], book: books[1], score: 5, comment: "Phù thủy Harry Potter thật tuyệt vời" },
  { user: users[0], book: books[2], score: 5, comment: "Sách thay đổi cuộc đời tôi" },
  { user: users[3], book: books[3], score: 4, comment: "Câu chuyện ý nghĩa, đáng đọc" },
  { user: users[4], book: books[4], score: 3, comment: "Hơi buồn nhưng hay" },
  { user: users[1], book: books[5], score: 5, comment: "Đáng sợ nhưng rất thực tế" },
  { user: users[2], book: books[6], score: 5, comment: "Tuổi thơ của tôi với Dế Mèn" },
  { user: users[3], book: books[7], score: 4, comment: "Châm biếm sâu sắc" },
  { user: users[4], book: books[8], score: 5, comment: "Truyền cảm hứng sống mạnh mẽ" },
  { user: users[0], book: books[9], score: 4, comment: "Giọng văn hài hước, dễ đọc" },
  { user: users[1], book: books[10], score: 5, comment: "Lập trình viên nào cũng nên đọc" },
  { user: users[2], book: books[11], score: 5, comment: "Kinh điển về design pattern" },
  { user: users[3], book: books[12], score: 4, comment: "Tiểu thuyết mafia hay nhất" },
  { user: users[4], book: books[13], score: 5, comment: "Kiệt tác văn học thế giới" }
].map { |r| Review.create!(r) }

puts "⭐ Đang tạo yêu thích..."
favorites = []
(1..30).each do |user_id|
  liked_books = [
    ((user_id - 1) % 30) + 1,
    ((user_id + 4) % 30) + 1,
    ((user_id + 9) % 30) + 1
  ]

  liked_books.each do |book_id|
    favorites << {
      user_id: user_id,
      favorable_type: "Book",
      favorable_id: book_id,
      created_at: Time.now,
      updated_at: Time.now
    }
  end
end

Favorite.insert_all(favorites)
puts "📋 Đang tạo yêu cầu mượn sách..."

# Generate 200 borrow requests with various statuses and realistic dates
200.times do |i|
  user_id = users.sample.id
  request_date = rand(60.days).seconds.ago
  start_date = request_date.to_date + rand(1..7).days
  end_date = start_date + rand(7..30).days

  # Determine status based on dates and randomization
  status = if end_date < Date.current && rand < 0.1
             [:overdue, :expired].sample
           elsif start_date < Date.current && rand < 0.3
             [:borrowed, :returned].sample
           elsif request_date.to_date < Date.current && rand < 0.2
             [:approved, :rejected].sample
           else
             :pending
           end

  # Set dates based on status with proper validation
  approved_date = nil
  actual_borrow_date = nil
  actual_return_date = nil

  if status.in?([:approved, :borrowed, :returned, :overdue])
    # Approved date must be after request date and before start date
    approved_date = [request_date.to_date + rand(1..3).days, start_date - 1.day].min
  end

  if status.in?([:borrowed, :returned, :overdue])
    # Actual borrow date must be after start date and after approved date
    min_borrow_date = [start_date, approved_date].compact.max
    actual_borrow_date = min_borrow_date + rand(0..2).days

    # Ensure actual_borrow_date is not after end_date for validation
    actual_borrow_date = [actual_borrow_date, end_date - 1.day].min
  end

  if status == :returned
    # Actual return date must be after actual_borrow_date and not in the future
    min_return_date = actual_borrow_date + 1.day
    max_return_date = [end_date + rand(1..10).days, Date.current - 1.day].min

    # Only set return date if we have a valid range
    if min_return_date <= max_return_date
      actual_return_date = min_return_date + rand(0..(max_return_date - min_return_date).to_i).days
    else
      # If we can't set a valid return date, change status to borrowed
      status = :borrowed
      actual_return_date = nil
    end
  end

  # Admin assignments
  admin_id = status.in?([:approved, :borrowed, :returned, :overdue]) ? admin.id : nil
  rejected_admin_id = status == :rejected ? admin.id : nil

  begin
    borrow_request = BorrowRequest.create!(
      user_id: user_id,
      request_date: request_date,
      status: status,
      start_date: start_date,
      end_date: end_date,
      actual_return_date: actual_return_date,
      admin_note: status == :rejected ? "Không đủ điều kiện mượn sách" : nil,
      approved_by_admin_id: admin_id,
      rejected_by_admin_id: rejected_admin_id,
      returned_by_admin_id: status == :returned ? admin.id : nil,
      borrowed_by_admin_id: status.in?([:borrowed, :returned, :overdue]) ? admin.id : nil,
      approved_date: approved_date,
      actual_borrow_date: actual_borrow_date
    )

    # Create 1-3 borrow request items per request
    num_books = rand(1..3)
    selected_books = books.sample(num_books)

    selected_books.each do |book|
      BorrowRequestItem.create!(
        borrow_request_id: borrow_request.id,
        book_id: book.id,
        quantity: 1
      )
    end

    # Update book quantities for borrowed/overdue books
    if status.in?([:borrowed, :overdue])
      selected_books.each do |book|
        book.update!(
          available_quantity: [book.available_quantity - 1, 0].max,
          borrow_count: book.borrow_count + 1
        )
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    puts "⚠️  Skipping invalid borrow request #{i + 1}: #{e.message}"
    next
  end
end

puts "🎉 Hoàn thành tạo dữ liệu mẫu!"
puts "📊 Thống kê:"
puts "- 📚 Sách: #{Book.count}"
puts "- ✍️ Tác giả: #{Author.count}"
puts "- 🏢 Nhà xuất bản: #{Publisher.count}"
puts "- 🏷️ Thể loại: #{Category.count}"
puts "- 👥 Người dùng: #{User.count}"
puts "- ⭐ Đánh giá: #{Review.count}"
puts "- 📋 Yêu cầu mượn sách: #{BorrowRequest.count}"
puts "- 📖 Chi tiết mượn sách: #{BorrowRequestItem.count}"

# Display borrow request statistics
puts "\n📋 Thống kê yêu cầu mượn sách:"
BorrowRequest.statuses.each do |status, _|
  count = BorrowRequest.where(status: status).count
  puts "- #{status.humanize}: #{count}"
end

puts "\n🔑 Thông tin đăng nhập:"
puts "- Admin: admin@thuvien.com / 123456"
puts "- Người dùng thường: nguyenvana@example.com / 123456, tranthib@example.com / 123456,..."

puts "\n📌 Lưu ý:"
puts "1. Để thêm ảnh bìa, đặt file ảnh vào thư mục lib/assets/book_covers/ với tên book_[id].jpg"
puts "2. Chạy rails db:seed để cập nhật ảnh bìa sau khi thêm file ảnh"

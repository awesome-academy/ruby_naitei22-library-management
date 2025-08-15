# app/helpers/users_helper.rb
require "digest/md5"

module UsersHelper
  AUTHOR_ID = "author_id".freeze
  CATEGORY_ID = "category_id".freeze
  # Returns the Gravatar for the given user.
  def gravatar_for user, options = {size: Settings.sizes.size_80}
    gravatar_id = Digest::MD5.hexdigest(user.email.downcase)
    size = options[:size]
    gravatar_url = "https://secure.gravatar.com/avatar/#{gravatar_id}?s=#{size}"
    image_tag(gravatar_url, alt: user.name, class: "gravatar")
  end

  def favorite_books_stats user
    {
      total_favorites: user.favorite_books.count,
      unique_authors:
      user.favorite_books.joins(:author).distinct.count(AUTHOR_ID),
      unique_categories:
      user.favorite_books.joins(:categories).distinct.count(CATEGORY_ID)
    }
  end

  # Individual stat methods for more granular control
  def total_favorite_books_count user
    user.favorite_books.count
  end

  def unique_authors_count user
    user.favorite_books.joins(:author).distinct.count("authors.id")
  end

  def unique_categories_count user
    user.favorite_books.joins(:categories).distinct.count("categories.id")
  end

  # Helper to render favorite book card
  def favorite_book_availability_class book
    book.available_quantity.positive? ? "text-success" : "text-danger"
  end

  def favorite_book_availability_text book
    "#{book.available_quantity}/#{book.total_quantity}"
  end

  # Helper for book info truncation
  def truncate_book_info text, length
    truncate(text, length:)
  end
end

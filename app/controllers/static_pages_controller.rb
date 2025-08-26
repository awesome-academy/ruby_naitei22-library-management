class StaticPagesController < ApplicationController
  include ApplicationHelper

  def home
    @pagy_books, @books = pagy(filtered_books, items: Settings.digits.digit_14)
  end

  def help; end

  private

  def filtered_books
    case params[:filter].to_s
    when "newest"
      Book.newest
    when "most_borrow_count"
      Book.most_borrow_count
    when "highest_rating"
      Book.by_highest_rating
    else
      Book.newest
    end
  end
end

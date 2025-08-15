class StaticPagesController < ApplicationController
  include ApplicationHelper

  def home
    @pagy_books, @recommended_books = pagy(Book.recommended,
                                           items: Settings.digits.digit_14)
  end

  def help; end
end

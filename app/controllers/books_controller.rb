class BooksController < ApplicationController
  before_action :set_book,
                only: %i(show borrow add_to_favorite remove_from_favorite
write_a_review destroy_review)
  before_action :set_recommended_books, only: :show
  before_action :set_review_stats, only: :show
  before_action :set_reviews, only: :show
  before_action :load_favorite, only: %i(add_to_favorite remove_from_favorite)
  before_action :set_user_review, only: %i(show write_a_review destroy_review)

  BOOK_INCLUDES = %i(author publisher categories).freeze
  BOOK_INCLUDES_WITH_IMAGE = [:author, :publisher, :categories,
{image_attachment: :blob}].freeze

  DEFAULT = "all".freeze

  SEARCH_TYPES = {
    title: :title,
    category: :category,
    author: :author,
    publisher: :publisher,
    all: :all
  }.freeze

  DEFAULT_SEARCH_TYPE = :all

  # GET /books/:id
  def show
    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "reviews",
          partial: "books/reviews",
          locals: {pagy_reviews: @pagy_reviews, reviews: @reviews}
        )
      end
    end
  end

  # GET /books/search
  def search
    @query = params[:q]
    @search_type = normalize_search_type(params[:search_type])

    books_scope = if @query.present?
                    Book.search(@query, @search_type)
                        .includes(BOOK_INCLUDES_WITH_IMAGE)
                  else
                    Book.includes(BOOK_INCLUDES_WITH_IMAGE)
                        .order(:title)
                  end

    @pagy, @books = pagy(books_scope, items: Settings.pagy.books)
    render :search
  end

  # POST /books/:id/borrow
  def borrow # rubocop:disable Metrics/AbcSize
    session[:borrow_cart] ||= []

    book_id = @book.id
    quantity = params[:quantity].to_i

    existing_item = session[:borrow_cart].find do |item|
      item["book_id"] == book_id
    end
    if existing_item
      existing_item["quantity"] += quantity
    else
      session[:borrow_cart] << {
        "book_id" => book_id,
        "quantity" => quantity
      }
    end

    flash[:success] = t(".added_to_borrow_cart")

    respond_to do |format|
      format.turbo_stream
      format.html do
        redirect_to book_path @book
      end
    end
  end

  # POST /books/:id/add_to_favorite
  def add_to_favorite
    @favorite ||= current_user.favorites.new(favorable: @book)

    respond_to do |format|
      if @favorite.save
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "favorite_button_#{@book.model_name.singular}_#{@book.id}",
            partial: "books/favorite_button",
            locals: {item: @book}
          )
        end
        format.html {redirect_to @book, notice: t(".favorite_success")}
      else
        format.html {redirect_to @book, alert: t(".favorite_failed")}
      end
    end
  end

  # DELETE /books/:id/remove_from_favorite
  def remove_from_favorite
    respond_to do |format|
      if @favorite.nil?
        format.html {redirect_to @book, alert: t(".favorite_not_found")}
      elsif @favorite.destroy
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "favorite_button_#{@book.model_name.singular}_#{@book.id}",
            partial: "books/favorite_button",
            locals: {item: @book}
          )
        end
        format.html {redirect_to @book, notice: t(".unfavorite_success")}
      else
        format.html {redirect_to @book, alert: t(".unfavorite_failed")}
      end
    end
  end

  # POST /books/:id/write_a_review
  def write_a_review
    @user_review ||= current_user.reviews.new(book: @book)

    @user_review.assign_attributes(review_params)

    if @user_review.save
      refresh_review_stats
      respond_to do |format|
        format.turbo_stream
        format.html {redirect_to book_path(@book)}
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "review_section",
            partial: "books/review_section",
            locals: {book: @book, review: @user_review}
          )
        end
        format.html {render :show}
      end
    end
  end

  # DELETE /books/:id/destroy_review
  def destroy_review
    if @user_review&.destroy
      refresh_review_stats

      respond_to do |format|
        format.turbo_stream
        format.html do
          redirect_to book_path(@book),
                      notice: t(".deleted_success")
        end
      end
    else
      flash.now[:error] = t(".delete_failed")

      respond_to do |format|
        format.turbo_stream do
          render :destroy_review, status: :unprocessable_entity
        end
        format.html do
          redirect_to book_path(@book),
                      alert: t(".delete_failed")
        end
      end
    end
  end

  private

  def set_book
    @book = Book.find_by(id: params[:id])
    return if @book

    flash[:alert] = t(".book_not_found")
    redirect_to root_path
  end

  def set_recommended_books
    books_by_author = Book.by_author(@book.author_id).exclude_book(@book.id)
    @pagy_books, @recommended_books = pagy(
      books_by_author,
      items: Settings.digits.digit_6,
      page_param: :recommended_page,
      overflow: :last_page
    )
  end

  def set_review_stats
    @review_counts = @book.reviews.group(:score).count
    @total_reviews = @book.reviews.count
  end

  def set_reviews
    reviews_scope = @book.reviews.recent.includes(:user)
    reviews_scope = reviews_scope.excluding_user(current_user) if current_user

    @pagy_reviews, @reviews = pagy(
      reviews_scope,
      items: Settings.digits.digit_5,
      page_param: :reviews_page,
      overflow: :last_page
    )
  end

  def load_favorite
    @favorite = current_user.favorites.find_by(favorable: @book)
  end

  def set_user_review
    return unless current_user

    @user_review = current_user.reviews.find_by(book_id: params[:id])
  end

  def refresh_review_stats
    @review_counts = @book.reviews.group(:score).count
    @total_reviews = @book.reviews.count
  end

  def normalize_search_type search_type
    search_type_sym = search_type&.to_sym
    SEARCH_TYPES.key?(search_type_sym) ? search_type_sym : DEFAULT_SEARCH_TYPE
  end

  def review_params
    params.require(:review).permit(:score, :comment)
  end
end

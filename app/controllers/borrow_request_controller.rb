class BorrowRequestController < ApplicationController
  before_action :authenticate_user!
  before_action :set_selected_books, only: :checkout
  before_action :set_and_validate_dates, only: :checkout
  before_action :check_sufficient_books, only: :checkout

  SELECTED = "1".freeze
  NOT_SELECTED = "0".freeze

  # GET /borrow_request
  def index
    session[:borrow_cart] ||= []
    load_cart_items
    paginate_cart_items
  end

  # PATCH /borrow_request/update_borrow_cart
  def update_borrow_cart
    update_cart_items
    update_start_date
    return if performed?

    update_end_date
    return if performed?

    respond_to do |format|
      format.html do
        redirect_to borrow_request_index_path,
                    flash: {success: t(".update_success")}
      end
      format.json {head :ok}
    end
  end

  # DELETE /borrow_request/remove_from_borrow_cart
  def remove_from_borrow_cart # rubocop:disable Metrics/AbcSize
    session[:borrow_cart] ||= []
    book_id = params[:book_id].to_i

    unless session[:borrow_cart].any? {|i| i["book_id"] == book_id}
      respond_to_cart_not_found(book_id) and return
    end

    session[:borrow_cart].reject! {|i| i["book_id"] == book_id}

    respond_to do |format|
      format.json do
        render json: {success: true, message: t(".remove_success"), book_id:}
      end
      format.html do
        redirect_to borrow_request_index_path,
                    flash: {success: t(".remove_success")}
      end
    end
  end

  # POST /borrow_request/checkout
  def checkout # rubocop:disable Metrics/AbcSize
    authorize! :checkout, BorrowRequest

    if @selected_books.blank?
      return redirect_to borrow_request_index_path,
                         flash: {danger: t(".no_books_selected")}
    end

    if @start_date.nil?
      return redirect_to borrow_request_index_path,
                         flash: {danger: t(".invalid_start_date_format")}
    end

    if @end_date.nil?
      return redirect_to borrow_request_index_path,
                         flash: {danger: t(".invalid_end_date_format")}
    end

    if @start_date < Time.zone.today
      return redirect_to borrow_request_index_path,
                         flash: {danger: t(".invalid_start_date")}
    end

    if @end_date <= @start_date
      return redirect_to borrow_request_index_path,
                         flash: {danger: t(".invalid_end_date")}
    end

    unless sufficient_books?(@selected_books, @books)
      return redirect_to borrow_request_index_path
    end

    create_borrow_request(@selected_books, @start_date, @end_date)
    return if performed?

    clear_checked_out_books(@selected_books)

    redirect_to borrow_request_index_path,
                flash: {success: t(".checkout_success")}
  end

  private

  # ------------------- CART LOADING -------------------
  def load_cart_items
    book_ids = session[:borrow_cart].map {|item| item["book_id"]}
    @books_in_cart = Book.where(id: book_ids).index_by(&:id)

    @cart_items = session[:borrow_cart].each_with_index.map do |item, idx|
      book = @books_in_cart[item["book_id"]]
      next unless book

      {book:, quantity: item["quantity"], selected: item["selected"],
       index: idx}
    end.compact
  end

  def paginate_cart_items # rubocop:disable Metrics/AbcSize
    page = params[:page].to_i
    total_pages = (@cart_items.size.to_f / Settings.digits.digit_5).ceil
    total_pages = Settings.digits.digit_1 if total_pages.zero?

    if page < Settings.digits.digit_1
      return redirect_to borrow_request_index_path(page: Settings.digits.digit_1) # rubocop:disable Layout/LineLength
    elsif page > total_pages
      return redirect_to borrow_request_index_path(page: total_pages)
    end

    @pagy, @cart_items = pagy_array_items(@cart_items,
                                          items: Settings.digits.digit_5,
                                          page:)
  end

  # ------------------- CART UPDATES -------------------
  def update_cart_items
    params[:cart]&.each do |idx, cart_params|
      item = session[:borrow_cart][idx.to_i]
      next unless item

      item["quantity"] = cart_params[:quantity].to_i
      item["selected"] = cart_params[:selected] == SELECTED
    end
  end

  def update_start_date # rubocop:disable Metrics/AbcSize
    return if params[:start_date].blank?

    start_date = parse_date(:start_date)
    if start_date.nil?
      flash[:danger] = t(".invalid_start_date_format")
      redirect_to borrow_request_index_path and return
    end

    session[:start_date] = start_date
    if session[:end_date].blank? || parse_date(:end_date) <= start_date
      session[:end_date] = start_date + Settings.digits.digit_1
    end
  end

  def update_end_date
    return if params[:end_date].blank?

    end_date = parse_date(:end_date)
    if end_date.nil?
      flash[:danger] = t(".invalid_end_date_format")
      redirect_to borrow_request_index_path and return
    end

    session[:end_date] = end_date
  end

  # ------------------- CHECKOUT HELPERS -------------------
  def set_selected_books
    @selected_books = session[:borrow_cart].select {|item| item["selected"]}
  end

  def set_and_validate_dates
    @start_date = parse_date(:start_date)
    @end_date   = parse_date(:end_date)
  end

  def check_sufficient_books
    @books = load_books_in_cart
  end

  def parse_date key
    value = params[key] || session[key]
    return nil if value.blank?

    Date.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end

  def load_books_in_cart
    book_ids = session[:borrow_cart].map {|item| item["book_id"]}
    Book.where(id: book_ids).index_by(&:id)
  end

  def sufficient_books? selected_books, books
    insufficient_books = []

    selected_books.each do |item|
      book_id = item["book_id"].to_i
      quantity = item["quantity"].to_i
      book = books[book_id]

      if book.nil? || quantity > book.available_quantity
        insufficient_books << (book&.title || t(".book_not_found"))
      end
    end

    if insufficient_books.any?
      flash[:error] =
        t(".insufficient_books", books: insufficient_books.join(", "))
      return false
    end

    true
  end

  def create_borrow_request selected_books, start_date, end_date
    ActiveRecord::Base.transaction do
      borrow_request = BorrowRequest.create!(
        user: current_user,
        request_date: Time.current,
        start_date:,
        end_date:,
        status: :pending
      )

      selected_books.each do |item|
        BorrowRequestItem.create!(
          borrow_request:,
          book_id: item["book_id"],
          quantity: item["quantity"]
        )
      end
    end
  rescue ActiveRecord::RecordInvalid => _e
    flash[:danger] = t(".checkout_failed")
    redirect_to borrow_request_index_path and return
  end

  def clear_checked_out_books selected_books
    borrowed_ids = selected_books.map {|b| b["book_id"].to_i}
    session[:borrow_cart].reject! do |item|
      borrowed_ids.include?(item["book_id"])
    end
    session[:start_date] = nil
    session[:end_date] = nil
  end

  # ------------------- CART NOT FOUND -------------------
  def respond_to_cart_not_found _book_id
    respond_to do |format|
      format.json do
        render json: {success: false, message: t(".book_not_in_cart")}
      end
      format.html do
        redirect_to borrow_request_index_path,
                    flash: {danger: t(".book_not_in_cart")}
      end
    end
  end

  # ------------------- PAGINATION HELPER -------------------
  def pagy_array_items array, vars = {}
    pagy = Pagy.new(count: array.size, **vars)
    paginated_array = array[pagy.offset, pagy.items] || []
    [pagy, paginated_array]
  end
end

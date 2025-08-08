class Admin::BooksController < Admin::ApplicationController
  PERMITTED_BOOK_PARAMS = %i(
    title
    description
    publication_year
    total_quantity
    available_quantity
    author_id
    publisher_id
    cover_image
  ).freeze

  PRELOAD = [:author, :publisher].freeze

  before_action :set_book, only: %i(show edit update destroy)

  # GET /admin/books
  def index
    books = Book.search(params[:q]).recent
    @pagy, @books = pagy(books)
  end

  # GET /admin/books/:id
  def show; end

  # GET /admin/books/new
  def new
    @book = Book.new
  end

  # POST /admin/books
  def create
    @book = Book.new(book_params)
    if @book.save
      flash[:success] = t("admin.books.flash.create.success")
      redirect_to admin_books_path
    else
      flash.now[:alert] = t("admin.books.flash.create.failure")
      render :new, status: :unprocessable_entity
    end
  end

  # GET /admin/books/:id/edit
  def edit; end

  # PATCH/PUT /admin/books/:id
  def update
    if @book.update(book_params)
      flash[:success] = t("admin.books.flash.update.success")
      redirect_to admin_book_path(@book)
    else
      flash.now[:alert] = t("admin.books.flash.update.failure")
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/books/:id
  def destroy
    if @book.destroy
      flash[:success] = t("admin.books.flash.destroy.success")
    else
      flash[:alert] = t("admin.books.flash.destroy.failure")
    end
    redirect_to admin_books_path
  end

  private

  def set_book
    @book =
      case action_name.to_sym
      when :show
        Book.includes(PRELOAD).find_by(id: params[:id])
      else
        Book.find_by(id: params[:id])
      end

    return if @book

    redirect_to admin_books_path, alert: t("admin.books.flash.not_found")
  end

  def book_params
    params.require(:book).permit(*PERMITTED_BOOK_PARAMS)
  end
end

class Admin::AuthorsController < Admin::ApplicationController
  PERMITTED_AUTHOR_PARAMS = %i(
    name
    bio
    birth_date
    death_date
    nationality
  ).freeze

  before_action :set_author, only: %i(show edit update destroy)

  # GET /admin/authors
  def index
    @q = Author.ransack(params[:q])
    @pagy, @authors = pagy(@q.result.recent)
  end

  # GET /admin/authors/:id
  def show; end

  # GET /admin/authors/new
  def new
    @author = Author.new
  end

  # POST /admin/authors
  def create
    @author = Author.new(author_params)
    if @author.save
      flash[:success] = t("admin.authors.flash.create.success")
      redirect_to admin_authors_path
    else
      flash.now[:alert] = t("admin.authors.flash.create.failure")
      render :new, status: :unprocessable_entity
    end
  end

  # GET /admin/authors/:id/edit
  def edit; end

  # PATCH/PUT /admin/authors/:id
  def update
    if @author.update(author_params)
      flash[:success] = t("admin.authors.flash.update.success")
      redirect_to admin_author_path(@author)
    else
      flash.now[:alert] = t("admin.authors.flash.update.failure")
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/authors/:id
  def destroy
    if @author.books.exists?
      flash[:alert] = t("admin.authors.flash.destroy.has_books")
    elsif @author.destroy
      flash[:success] = t("admin.authors.flash.destroy.success")
    else
      flash[:alert] = t("admin.authors.flash.destroy.failure")
    end
    redirect_to admin_authors_path
  end

  private

  def set_author
    @author = Author.find_by(id: params[:id])
    return unless @author.nil?

    flash[:alert] = t("admin.authors.flash.not_found")
    redirect_to admin_authors_path
  end

  def author_params
    params.require(:author).permit(*PERMITTED_AUTHOR_PARAMS)
  end
end

class Admin::CategoriesController < Admin::ApplicationController
  PERMITTED_CATEGORY_PARAMS = %i(
    name
    description
  ).freeze

  before_action :set_category, only: %i(show edit update destroy)

  # GET /admin/categories
  def index
    @q = Category.ransack(params[:q])
    @pagy, @categories = pagy(@q.result.recent)
  end

  # GET /admin/categories/:id
  def show; end

  # GET /admin/categories/new
  def new
    @category = Category.new
  end

  # POST /admin/categories
  def create
    @category = Category.new(category_params)
    if @category.save
      flash[:success] = t("admin.categories.flash.create.success")
      redirect_to admin_categories_path
    else
      flash.now[:alert] = t("admin.categories.flash.create.failure")
      render :new, status: :unprocessable_entity
    end
  end

  # GET /admin/categories/:id/edit
  def edit; end

  # PATCH/PUT /admin/categories/:id
  def update
    if @category.update(category_params)
      flash[:success] = t("admin.categories.flash.update.success")
      redirect_to admin_category_path(@category)
    else
      flash.now[:alert] = t("admin.categories.flash.update.failure")
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/categories/:id
  def destroy
    if @category.destroy
      flash[:success] = t("admin.categories.flash.destroy.success")
    else
      flash[:alert] = t("admin.categories.flash.destroy.failure")
    end
    redirect_to admin_categories_path
  end

  private

  def set_category
    @category = Category.find_by(id: params[:id])
    return unless @category.nil?

    flash[:alert] = t("admin.categories.flash.not_found")
    redirect_to admin_categories_path
  end

  def category_params
    params.require(:category).permit(*PERMITTED_CATEGORY_PARAMS)
  end
end

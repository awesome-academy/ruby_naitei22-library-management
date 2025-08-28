class Admin::PublishersController < Admin::ApplicationController
  load_and_authorize_resource

  PERMITTED_PUBLISHER_PARAMS = %i(
    name
    address
    phone_number
    email
    website
  ).freeze

  # GET /admin/publishers
  def index
    @q = Publisher.ransack(params[:q])
    @pagy, @publishers = pagy(@q.result.recent)
  end

  # GET /admin/publishers/:id
  def show; end

  # GET /admin/publishers/new
  def new
    @publisher = Publisher.new
  end

  # POST /admin/publishers
  def create
    @publisher = Publisher.new(publisher_params)
    if @publisher.save
      flash[:success] = t("admin.publishers.flash.create.success")
      redirect_to admin_publishers_path
    else
      flash.now[:alert] = t("admin.publishers.flash.create.failure")
      render :new, status: :unprocessable_entity
    end
  end

  # GET /admin/publishers/:id/edit
  def edit; end

  # PATCH/PUT /admin/publishers/:id
  def update
    if @publisher.update(publisher_params)
      flash[:success] = t("admin.publishers.flash.update.success")
      redirect_to admin_publisher_path(@publisher)
    else
      flash.now[:alert] = t("admin.publishers.flash.update.failure")
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/publishers/:id
  def destroy
    if @publisher.destroy
      flash[:success] = t("admin.publishers.flash.destroy.success")
    else
      flash[:alert] = @publisher.errors.full_messages.to_sentence ||
                      t("admin.publishers.flash.destroy.failure")
    end
    redirect_to admin_publishers_path
  end

  private

  def publisher_params
    params.require(:publisher).permit(*PERMITTED_PUBLISHER_PARAMS)
  end
end

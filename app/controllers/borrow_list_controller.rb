class BorrowListController < ApplicationController
  load_and_authorize_resource :borrow_request, class: "BorrowRequest"

  before_action :logged_in_user
  before_action :set_borrow_request, only: %i(show cancel)
  before_action :ensure_pending_request, only: :cancel

  rescue_from Pagy::OverflowError, with: :redirect_to_last_page

  # GET /borrow_list
  def index
    @status = params[:status]
    @request_date_from = params[:request_date_from]
    @request_date_to   = params[:request_date_to]

    requests = current_user.borrow_requests
                           .includes(:user)
                           .by_status(@status)
                           .by_request_date_from(@request_date_from)
                           .by_request_date_to(@request_date_to)

    @pagy, @borrow_requests = pagy(
      requests.order(created_at: :desc),
      items: Settings.digits.digit_10
    )
  end

  # GET /borrow_list/:id
  def show
    @pagy, @borrowed_items = pagy(
      @borrow_request.borrow_request_items.includes(:book).order(:id),
      items: Settings.digits.digit_5
    )
  end

  # PATCH /borrow_list/:id/cancel
  def cancel
    if @borrow_request.update(status: :cancelled)
      flash[:success] = t(".success")
    else
      flash[:danger] = t(".update_failed")
    end
    redirect_to borrow_list_index_path
  end

  private

  def ensure_pending_request
    return if @borrow_request&.pending?

    flash[:alert] = t(".failure")
    redirect_to borrow_list_index_path
  end

  def set_borrow_request
    @borrow_request =
      case action_name.to_sym
      when :show
        BorrowRequest.includes(borrow_request_items: :book)
                     .find_by(id: params[:id])
      when :cancel
        current_user.borrow_requests.find_by(id: params[:id])
      else
        current_user.borrow_requests.find_by(id: params[:id])
      end
    authorize! :read, @borrow_request if @borrow_request

    redirect_not_found unless @borrow_request
  end

  def redirect_not_found
    flash[:danger] = t(".not_found")
    redirect_to borrow_list_index_path
  end

  def redirect_to_last_page
    flash[:warning] = t(".page_not_found")
    redirect_to request.path
  end
end

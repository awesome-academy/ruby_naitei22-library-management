# app/controllers/admin/borrow_requests_controller.rb
class Admin::BorrowRequestsController < ApplicationController
  include Pagy::Backend
  include Admin::BorrowRequestsHelper

  PERMIT = %i(
    status
    admin_note
    actual_return_date
    actual_borrow_date
    approved_date
    need_update_reason
  ).freeze

  before_action :require_admin
  before_action :set_borrow_request,
                only: %i(show edit_status change_status)

  # GET /admin/borrow_requests
  def index
    @q = BorrowRequest.includes(:user).ransack(params[:q])

    @pagy, @borrow_requests = pagy(
      @q.result(distinct: true).sorted
    )
  end

  # GET /admin/borrow_requests/:id
  def show; end

  # GET /admin/borrow_requests/:id/edit_status
  def edit_status
    render partial: "status_form", formats: [:html],
           locals: {borrow_request: @borrow_request}
  end

  # PATCH /admin/borrow_requests/:id/change_status
  def change_status
    prev_status = @borrow_request.status.to_sym
    new_status = borrow_request_params[:status].to_sym

    return handle_no_change if new_status == prev_status

    update_borrow_request_status(prev_status, new_status)
    respond_to_success
  rescue ActiveRecord::RecordInvalid => e
    handle_update_error(e)
  end

  private

  def borrow_request_params
    params.fetch(:borrow_request, {}).permit(*PERMIT)
  end

  def handle_no_change
    @borrow_request.errors.add(:status, t(".no_change"))
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "status_form_#{@borrow_request.id}",
          partial: "status_form",
          formats: [:html],
          locals: {borrow_request: @borrow_request}
        ), status: :unprocessable_entity
      end
      format.html do
        redirect_to admin_borrow_request_path(@borrow_request),
                    alert: t(".no_change")
      end
    end
  end

  def status_extra_attributes prev_status, new_status
    case new_status
    when :approved
      approved_attributes(prev_status)
    when :borrowed
      borrowed_attributes
    when :rejected
      rejected_attributes
    when :returned
      returned_attributes
    else
      {}
    end
  end

  def approved_attributes prev_status
    attrs = {
      rejected_by_admin_id: nil
    }
    if prev_status != :approved
      attrs[:approved_by_admin_id] = current_user.id
      attrs[:approved_date] =
        borrow_request_params[:approved_date].presence || Time.current
    end
    attrs
  end

  def borrowed_attributes
    {
      actual_borrow_date:
        borrow_request_params[:actual_borrow_date].presence || Time.current,
      borrowed_by_admin_id: current_user.id
    }
  end

  def rejected_attributes
    {
      rejected_by_admin_id: current_user.id,
      approved_by_admin_id: nil
    }
  end

  def returned_attributes
    {
      returned_by_admin_id: current_user.id,
      actual_return_date:
        borrow_request_params[:actual_return_date].presence || Time.current
    }
  end

  def respond_to_success
    respond_to do |format|
      format.turbo_stream
      format.html do
        redirect_to admin_borrow_request_path(@borrow_request),
                    success: t(".status_updated")
      end
    end
  end

  def handle_update_error _exception
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "status_form_#{@borrow_request.id}",
          partial: "status_form",
          formats: [:html],
          locals: {borrow_request: @borrow_request}
        ), status: :unprocessable_entity
      end
      format.html do
        render partial: "status_form",
               locals: {borrow_request: @borrow_request},
               status: :unprocessable_entity
      end
    end
  end

  # === STOCK METHODS ===
  def decrement_book_stock
    @borrow_request.borrow_request_items.each do |item|
      item.book.decrement!(:available_quantity, item.quantity)
      item.book.increment!(:borrow_count, item.quantity)
    end
  end

  def increment_book_stock
    @borrow_request.borrow_request_items.each do |item|
      item.book.increment!(:available_quantity, item.quantity)
    end
  end

  def set_borrow_request
    @borrow_request = BorrowRequest.find_by(id: params[:id])
  end

  def require_admin
    return if current_user&.admin?

    flash[:alert] = t(".flash.no_access")
    redirect_to root_path
  end

  def update_borrow_request_status prev_status, new_status
    BorrowRequest.transaction do
      case new_status
      when :approved
        if stock_enough?
          update_request_attributes(prev_status, :approved)
          handle_approved_status(prev_status)
        else
          handle_need_update_status
        end
      else
        update_request_attributes(prev_status, new_status)
        handle_status_side_effects(prev_status, new_status)
      end
    end

    flash.now[:notice] = t(".status_updated")
    @borrow_request.reload
  end

  def update_request_attributes prev_status, new_status
    @borrow_request.update!(
      borrow_request_params.merge(
        status_extra_attributes(prev_status, new_status)
      ).merge(status: new_status)
    )
  end

  def handle_status_side_effects prev_status, new_status
    case new_status
    when :rejected
      send_status_notification_email(new_status)
    when :returned
      increment_book_stock if prev_status != :returned
    end
  end

  def handle_need_update_status
    @borrow_request.update!(
      status: :need_update,
      need_update_reason: @borrow_request.stock_error_messages
    )
  end

  def stock_enough?
    @borrow_request.borrow_request_items.all? do |item|
      item.book.available_quantity >= item.quantity
    end
  end

  def handle_approved_status prev_status
    decrement_book_stock if prev_status != :approved
    send_status_notification_email(:approved)
  end

  def send_status_notification_email status
    case status
    when :approved
      UserMailer.borrow_request_approved(@borrow_request).deliver_later
    when :rejected
      UserMailer.borrow_request_rejected(@borrow_request).deliver_later
    end
  rescue StandardError => e
    Rails.logger.error(
      t(
        ".errors.mailer_failed",
        status:,
        error: e.message
      )
    )
  end
end

require 'rails_helper'

RSpec.describe Admin::BorrowRequestsController, type: :controller do
  include ActiveSupport::Testing::TimeHelpers
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let(:book) { create(:book, available_quantity: 5, borrow_count: 0) }
  let(:borrow_request) { create(:borrow_request, status: :pending) }
  let!(:borrow_request_item) { create(:borrow_request_item, borrow_request: borrow_request, book: book, quantity: 2) }

  before do
    allow(controller).to receive(:current_user).and_return(admin_user)
  end

  describe "before_actions" do
    it "requires admin and redirects if not admin" do
      allow(controller).to receive(:current_user).and_return(regular_user)
      get :index
      expect(flash[:alert]).to eq(I18n.t("admin.borrow_requests.flash.no_access"))
      expect(response).to redirect_to(root_path)
    end

    it "sets borrow_request for specific actions" do
      get :show, params: { id: borrow_request.id }
      expect(assigns(:borrow_request)).to eq(borrow_request)
    end

    it "sets borrow_request to nil if not found" do
      get :show, params: { id: 999 }
      expect(assigns(:borrow_request)).to be_nil
    end
  end

  describe "GET #index" do
    it "assigns @borrow_requests and @pagy" do
      get :index
      expect(assigns(:borrow_requests)).to include(borrow_request)
      expect(assigns(:pagy)).to be_present
      expect(response).to render_template(:index)
    end
  end

  describe "GET #show" do
    it "assigns @borrow_request" do
      get :show, params: { id: borrow_request.id }
      expect(assigns(:borrow_request)).to eq(borrow_request)
      expect(response).to render_template(:show)
    end
  end

  describe "GET #edit_status" do
    it "renders status_form partial" do
      get :edit_status, params: { id: borrow_request.id }
      expect(response).to render_template(partial: "admin/borrow_requests/_status_form")
      expect(assigns(:borrow_request)).to eq(borrow_request)
    end
  end

  describe "PATCH #change_status" do
    context "when status does not change" do
      before do
        borrow_request.update!(status: :approved, approved_date: borrow_request.start_date - 1.day)
      end

      it "adds error and responds correctly for html" do
        patch :change_status, params: {
          id: borrow_request.id,
          borrow_request: {
            status: :approved,
            approved_date: borrow_request.start_date - 1.day
          }
        }, format: :html

        expect(flash[:alert]).to eq(I18n.t("admin.borrow_requests.change_status.no_change"))
        expect(response).to redirect_to(admin_borrow_request_path(borrow_request))
      end

      it "renders status_form partial with turbo_stream" do
        patch :change_status, params: {
          id: borrow_request.id,
          borrow_request: {
            status: :approved,
            approved_date: borrow_request.start_date - 1.day
          }
        }, format: :turbo_stream

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("turbo-stream")
        expect(response).to render_template(partial: "admin/borrow_requests/_status_form")
        expect(assigns(:borrow_request).errors[:status]).to include(
          I18n.t("admin.borrow_requests.change_status.no_change")
        )
      end
    end

    context "when status changes to approved and stock is enough" do
      before do
        book.update!(available_quantity: 3)
      end

      it "updates status, decrements stock, sends email, and sets flash" do
        expect(UserMailer).to receive(:borrow_request_approved).with(borrow_request).and_return(double(deliver_later: true))

        patch :change_status, params: {
          id: borrow_request.id,
          borrow_request: { status: :approved, approved_date: borrow_request.start_date - 1.day }
        }, format: :html

        borrow_request.reload
        expect(borrow_request.status).to eq("approved")
        expect(borrow_request.approved_by_admin_id).to eq(admin_user.id)
        expect(book.reload.available_quantity).to eq(1)
        expect(book.borrow_count).to eq(2)
        expect(flash[:notice]).to eq(I18n.t("admin.borrow_requests.change_status.status_updated"))
        expect(response).to redirect_to(admin_borrow_request_path(borrow_request))
      end
    end

    context "when status changes to approved but stock is insufficient" do
      before do
        book.update!(available_quantity: 1)
      end

      it "updates status to need_update with reason and sets flash" do
        patch :change_status, params: {
          id: borrow_request.id,
          borrow_request: { status: :approved, approved_date: borrow_request.start_date - 1.day }
        }, format: :html

        borrow_request.reload
        expect(borrow_request.status).to eq("need_update")
        expect(borrow_request.need_update_reason).not_to be_blank
        expect(flash[:notice]).to eq(I18n.t("admin.borrow_requests.change_status.status_updated"))
        expect(response).to redirect_to(admin_borrow_request_path(borrow_request))
      end
    end

    context "when status changes to borrowed" do
      before { borrow_request.update!(status: :approved) }

      it "updates status and sets borrowed attributes" do
        travel_to Time.zone.local(2025, 8, 25, 12, 0, 0) do
          patch :change_status, params: {
            id: borrow_request.id,
            borrow_request: { status: :borrowed }
          }, format: :html

          borrow_request.reload
          expect(borrow_request.status).to eq("borrowed")
          expect(borrow_request.actual_borrow_date.to_date).to eq(Time.current.to_date)
          expect(borrow_request.borrowed_by_admin_id).to eq(admin_user.id)
          expect(flash[:notice]).to eq(I18n.t("admin.borrow_requests.change_status.status_updated"))
          expect(response).to redirect_to(admin_borrow_request_path(borrow_request))
        end
      end
    end

    context "when status changes to rejected" do
      it "does not update status, returns unprocessable entity, and renders status_form" do
        patch :change_status, params: {
          id: borrow_request.id,
          borrow_request: { status: :rejected }
        }, format: :html

        borrow_request.reload
        puts "Errors: #{borrow_request.errors.full_messages}" if borrow_request.status != "pending" # Debug
        expect(borrow_request.status).to eq("pending")
        expect(borrow_request.rejected_by_admin_id).to be_nil
        expect(borrow_request.approved_by_admin_id).to be_nil
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(partial: "admin/borrow_requests/_status_form")
      end
    end

    context "when status is invalid" do
      it "raises ArgumentError for invalid status" do
        expect {
          patch :change_status, params: {
            id: borrow_request.id,
            borrow_request: { status: "invalid_status" }
          }
        }.to raise_error(ArgumentError, /is not a valid status/)
      end
    end

    context "when status changes to returned and prev_status not returned" do
      before do
        borrow_request.update!(status: :borrowed)
        book.update!(available_quantity: 0)
      end

      it "updates status, increments stock, and sets returned attributes" do
        travel_to Time.zone.local(2025, 8, 25, 13, 0, 0) do
          patch :change_status, params: {
            id: borrow_request.id,
            borrow_request: { status: :returned }
          }, format: :html

          borrow_request.reload
          expect(borrow_request.status).to eq("returned")
          expect(borrow_request.actual_return_date.to_date).to eq(Time.current.to_date)
          expect(borrow_request.returned_by_admin_id).to eq(admin_user.id)
          expect(book.reload.available_quantity).to eq(2)
          expect(flash[:notice]).to eq(I18n.t("admin.borrow_requests.change_status.status_updated"))
          expect(response).to redirect_to(admin_borrow_request_path(borrow_request))
        end
      end
    end

    context "when changing status raises ActiveRecord::RecordInvalid" do
      before do
        allow_any_instance_of(BorrowRequest).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(borrow_request))
      end

      it "renders turbo_stream with unprocessable_entity" do
        patch :change_status, params: { id: borrow_request.id, borrow_request: { status: :approved } }, format: :turbo_stream
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("turbo-stream")
        expect(response).to render_template(partial: "admin/borrow_requests/_status_form")
      end

      it "renders html with unprocessable_entity" do
        patch :change_status, params: { id: borrow_request.id, borrow_request: { status: :approved } }, format: :html
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(partial: "admin/borrow_requests/_status_form")
      end
    end

    context "when transaction fails" do
      before do
        allow_any_instance_of(BorrowRequest).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(borrow_request))
      end

      it "does not update status and renders error" do
        patch :change_status, params: { id: borrow_request.id, borrow_request: { status: :approved } }, format: :html
        expect(borrow_request.reload.status).to eq("pending")
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "#approved_attributes" do
    before do
      allow(controller).to receive(:current_user).and_return(admin_user)
    end

    context "when prev_status is not approved and approved_date present" do
      before { allow(controller).to receive(:borrow_request_params).and_return({ approved_date: Date.yesterday }) }

      it "returns approved attributes and clears rejected" do
        expect(controller.send(:approved_attributes, :pending)).to eq(
          approved_by_admin_id: admin_user.id,
          approved_date: Date.yesterday,
          rejected_by_admin_id: nil
        )
      end
    end

    context "when prev_status is not approved and approved_date blank" do
      before { allow(controller).to receive(:borrow_request_params).and_return({ approved_date: "" }) }

      it "defaults approved_date to Time.current" do
        travel_to Time.zone.local(2025, 8, 25, 12, 0, 0) do
          expect(controller.send(:approved_attributes, :pending)).to eq(
            approved_by_admin_id: admin_user.id,
            approved_date: Time.current,
            rejected_by_admin_id: nil
          )
        end
      end
    end

    context "when prev_status is approved" do
      before { allow(controller).to receive(:borrow_request_params).and_return({}) }

      it "only clears rejected_by_admin_id" do
        expect(controller.send(:approved_attributes, :approved)).to eq(
          rejected_by_admin_id: nil
        )
      end
    end
  end

  describe "#borrowed_attributes" do
    context "when actual_borrow_date is present in params" do
      before { allow(controller).to receive(:borrow_request_params).and_return({ actual_borrow_date: Date.yesterday }) }

      it "returns the given actual_borrow_date and current_user.id" do
        expect(controller.send(:borrowed_attributes)).to eq(
          actual_borrow_date: Date.yesterday,
          borrowed_by_admin_id: admin_user.id
        )
      end
    end

    context "when actual_borrow_date is blank" do
      before { allow(controller).to receive(:borrow_request_params).and_return({ actual_borrow_date: "" }) }

      it "defaults actual_borrow_date to Time.current" do
        travel_to Time.zone.local(2025, 8, 25, 12, 0, 0) do
          expect(controller.send(:borrowed_attributes)).to eq(
            actual_borrow_date: Time.current,
            borrowed_by_admin_id: admin_user.id
          )
        end
      end
    end
  end

  describe "#rejected_attributes" do
    before { allow(controller).to receive(:borrow_request_params).and_return({}) }

    it "returns rejected_by_admin_id and resets approved_by_admin_id to nil" do
      expect(controller.send(:rejected_attributes)).to eq(
        rejected_by_admin_id: admin_user.id,
        approved_by_admin_id: nil
      )
    end
  end

  describe "#returned_attributes" do
    context "when actual_return_date is present in params" do
      before { allow(controller).to receive(:borrow_request_params).and_return({ actual_return_date: Date.today }) }

      it "returns the given actual_return_date and current_user.id" do
        expect(controller.send(:returned_attributes)).to eq(
          actual_return_date: Date.today,
          returned_by_admin_id: admin_user.id
        )
      end
    end

    context "when actual_return_date is blank" do
      before { allow(controller).to receive(:borrow_request_params).and_return({ actual_return_date: "" }) }

      it "defaults actual_return_date to Time.current" do
        travel_to Time.zone.local(2025, 8, 25, 13, 0, 0) do
          expect(controller.send(:returned_attributes)).to eq(
            actual_return_date: Time.current,
            returned_by_admin_id: admin_user.id
          )
        end
      end
    end
  end

  describe "#decrement_book_stock" do
    it "decrements available_quantity and increments borrow_count for each item" do
      controller.instance_variable_set(:@borrow_request, borrow_request)
      controller.send(:decrement_book_stock)
      book.reload
      expect(book.available_quantity).to eq(3)
      expect(book.borrow_count).to eq(2)
    end
  end

  describe "#increment_book_stock" do
    before { book.update!(available_quantity: 3) }

    it "increments available_quantity for each item" do
      controller.instance_variable_set(:@borrow_request, borrow_request)
      controller.send(:increment_book_stock)
      book.reload
      expect(book.available_quantity).to eq(5)
    end
  end

  describe "#stock_enough?" do
    context "when all items have enough stock" do
      before { book.update!(available_quantity: 3) }

      it "returns true" do
        controller.instance_variable_set(:@borrow_request, borrow_request)
        expect(controller.send(:stock_enough?)).to be true
      end
    end

    context "when at least one item does not have enough stock" do
      before { book.update!(available_quantity: 1) }

      it "returns false" do
        controller.instance_variable_set(:@borrow_request, borrow_request)
        expect(controller.send(:stock_enough?)).to be false
      end
    end
  end

  describe "#handle_need_update_status" do
    before do
      allow(borrow_request).to receive(:stock_error_messages).and_return(["Stock insufficient"])
    end

    it "updates status to need_update with reason" do
      controller.instance_variable_set(:@borrow_request, borrow_request)
      controller.send(:handle_need_update_status)
      borrow_request.reload
      expect(borrow_request.status).to eq("need_update")
      expect(borrow_request.need_update_reason).to eq(["Stock insufficient"])
    end
  end

  describe "#update_request_attributes" do
    it "updates borrow_request with merged params and status" do
      controller.instance_variable_set(:@borrow_request, borrow_request)
      allow(controller).to receive(:borrow_request_params).and_return({ admin_note: "note" })
      allow(controller).to receive(:status_extra_attributes).with(:pending, :approved).and_return({ approved_by_admin_id: admin_user.id })

      controller.send(:update_request_attributes, :pending, :approved)
      borrow_request.reload
      expect(borrow_request.status).to eq("approved")
      expect(borrow_request.admin_note).to eq("note")
      expect(borrow_request.approved_by_admin_id).to eq(admin_user.id)
    end
  end

  describe "#handle_approved_status" do
    context "when prev_status not approved" do
      it "decrements stock and sends email" do
        expect(controller).to receive(:decrement_book_stock)
        expect(controller).to receive(:send_status_notification_email).with(:approved)
        controller.instance_variable_set(:@borrow_request, borrow_request)
        controller.send(:handle_approved_status, :pending)
      end
    end

    context "when prev_status approved" do
      it "does not decrement stock but sends email" do
        expect(controller).not_to receive(:decrement_book_stock)
        expect(controller).to receive(:send_status_notification_email).with(:approved)
        controller.instance_variable_set(:@borrow_request, borrow_request)
        controller.send(:handle_approved_status, :approved)
      end
    end
  end

  describe "#handle_status_side_effects" do
    it "sends email for rejected" do
      expect(controller).to receive(:send_status_notification_email).with(:rejected)
      controller.instance_variable_set(:@borrow_request, borrow_request)
      controller.send(:handle_status_side_effects, :pending, :rejected)
    end

    context "for returned when prev not returned" do
      it "increments stock" do
        expect(controller).to receive(:increment_book_stock)
        controller.instance_variable_set(:@borrow_request, borrow_request)
        controller.send(:handle_status_side_effects, :borrowed, :returned)
      end
    end

    context "for returned when prev returned" do
      it "does not increment stock" do
        expect(controller).not_to receive(:increment_book_stock)
        controller.instance_variable_set(:@borrow_request, borrow_request)
        controller.send(:handle_status_side_effects, :returned, :returned)
      end
    end
  end

  describe "#update_borrow_request_status" do
    it "wraps updates in transaction and sets flash" do
      expect(BorrowRequest).to receive(:transaction).and_yield
      expect(controller).to receive(:stock_enough?).and_return(true)
      expect(controller).to receive(:update_request_attributes)
      expect(controller).to receive(:handle_approved_status)
      controller.instance_variable_set(:@borrow_request, borrow_request)
      controller.send(:update_borrow_request_status, :pending, :approved)
      expect(flash.now[:notice]).to eq("Translation missing. Options considered were:\n- en.admin.borrow_requests.status_updated\n- en.admin.borrow_requests.status_updated")
      expect(borrow_request.reload).to eq(borrow_request)
    end
  end

  describe "#send_status_notification_email" do
    context "for approved status" do
      it "sends approved email" do
        expect(UserMailer).to receive(:borrow_request_approved).with(borrow_request).and_return(double(deliver_later: true))
        controller.instance_variable_set(:@borrow_request, borrow_request)
        controller.send(:send_status_notification_email, :approved)
      end
    end

    context "for rejected status" do
      it "sends rejected email" do
        expect(UserMailer).to receive(:borrow_request_rejected).with(borrow_request).and_return(double(deliver_later: true))
        controller.instance_variable_set(:@borrow_request, borrow_request)
        controller.send(:send_status_notification_email, :rejected)
      end
    end

    context "when email sending fails" do
      it "logs error" do
        allow(UserMailer).to receive(:borrow_request_approved).and_raise(StandardError.new("Email error"))
        expect(Rails.logger).to receive(:error).with(/Failed to send.*email: Email error/)
        controller.instance_variable_set(:@borrow_request, borrow_request)
        controller.send(:send_status_notification_email, :approved)
      end
    end
  end

  describe "#borrow_request_params" do
    it "permits only preload attributes" do
      controller.params = ActionController::Parameters.new(borrow_request: { status: "approved", unknown: "ignored", admin_note: "note" })
      expect(controller.send(:borrow_request_params)).to eq({ "status" => "approved", "admin_note" => "note" })
    end
  end
end

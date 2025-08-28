require 'rails_helper'

RSpec.describe Admin::BorrowRequestsController, type: :controller do
  include Devise::Test::ControllerHelpers
  include ActiveSupport::Testing::TimeHelpers

  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let(:book) { create(:book, available_quantity: 5, borrow_count: 0) }
  let(:borrow_request) { create(:borrow_request, status: :pending) }
  let!(:borrow_request_item) { create(:borrow_request_item, borrow_request: borrow_request, book: book, quantity: 2) }

  before do
    sign_in admin_user
  end

  describe "before_actions" do
    it "sets borrow_request for show" do
      get :show, params: { id: borrow_request.id }
      expect(assigns(:borrow_request)).to eq(borrow_request)
    end

    it "raises RecordNotFound if borrow_request not found" do
      expect { get :show, params: { id: 999 } }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "GET #index" do
    it "assigns @borrow_requests" do
      get :index
      expect(assigns(:borrow_requests)).to include(borrow_request)
    end

    it "assigns @pagy" do
      get :index
      expect(assigns(:pagy)).to be_present
    end

    it "renders index template" do
      get :index
      expect(response).to render_template(:index)
    end
  end

  describe "GET #show" do
    it "assigns @borrow_request" do
      get :show, params: { id: borrow_request.id }
      expect(assigns(:borrow_request)).to eq(borrow_request)
    end

    it "renders show template" do
      get :show, params: { id: borrow_request.id }
      expect(response).to render_template(:show)
    end
  end

  describe "GET #edit_status" do
    it "renders status_form partial" do
      get :edit_status, params: { id: borrow_request.id }
      expect(response).to render_template(partial: "admin/borrow_requests/_status_form")
    end

    it "assigns @borrow_request" do
      get :edit_status, params: { id: borrow_request.id }
      expect(assigns(:borrow_request)).to eq(borrow_request)
    end
  end

  describe "PATCH #change_status" do
    context "when status does not change" do
      before { borrow_request.update!(status: :approved, approved_date: borrow_request.start_date - 1.day) }

      it "sets flash alert for html format" do
        patch :change_status, params: {
          id: borrow_request.id,
          borrow_request: { status: :approved, approved_date: borrow_request.start_date - 1.day }
        }, format: :html
        expect(flash[:alert]).to eq(I18n.t("admin.borrow_requests.change_status.no_change"))
      end

      it "redirects to borrow_request path for html format" do
        patch :change_status, params: {
          id: borrow_request.id,
          borrow_request: { status: :approved, approved_date: borrow_request.start_date - 1.day }
        }, format: :html
        expect(response).to redirect_to(admin_borrow_request_path(borrow_request))
      end

      it "renders status_form partial with turbo_stream" do
        patch :change_status, params: {
          id: borrow_request.id,
          borrow_request: { status: :approved, approved_date: borrow_request.start_date - 1.day }
        }, format: :turbo_stream
        expect(response).to render_template(partial: "admin/borrow_requests/_status_form")
      end

      it "returns unprocessable_entity with turbo_stream" do
        patch :change_status, params: {
          id: borrow_request.id,
          borrow_request: { status: :approved, approved_date: borrow_request.start_date - 1.day }
        }, format: :turbo_stream
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "adds error message to borrow_request" do
        patch :change_status, params: {
          id: borrow_request.id,
          borrow_request: { status: :approved, approved_date: borrow_request.start_date - 1.day }
        }, format: :turbo_stream
        expect(assigns(:borrow_request).errors[:status]).to include(I18n.t("admin.borrow_requests.change_status.no_change"))
      end
    end

    context "when status changes to approved and stock is enough" do
      before { book.update!(available_quantity: 3) }

      it "sends approved email" do
        expect(UserMailer).to receive(:borrow_request_approved).with(borrow_request).and_return(double(deliver_later: true))
        patch :change_status, params: { id: borrow_request.id, borrow_request: { status: :approved, approved_date: borrow_request.start_date - 1.day } }, format: :html
      end

      it "updates status to approved" do
        patch :change_status, params: { id: borrow_request.id, borrow_request: { status: :approved, approved_date: borrow_request.start_date - 1.day } }, format: :html
        expect(borrow_request.reload.status).to eq("approved")
      end

      it "sets approved_by_admin_id" do
        patch :change_status, params: { id: borrow_request.id, borrow_request: { status: :approved, approved_date: borrow_request.start_date - 1.day } }, format: :html
        expect(borrow_request.reload.approved_by_admin_id).to eq(admin_user.id)
      end

      it "decrements book stock" do
        patch :change_status, params: { id: borrow_request.id, borrow_request: { status: :approved, approved_date: borrow_request.start_date - 1.day } }, format: :html
        expect(book.reload.available_quantity).to eq(1)
      end

      it "increments book borrow_count" do
        patch :change_status, params: { id: borrow_request.id, borrow_request: { status: :approved, approved_date: borrow_request.start_date - 1.day } }, format: :html
        expect(book.reload.borrow_count).to eq(2)
      end

      it "sets flash notice" do
        patch :change_status, params: { id: borrow_request.id, borrow_request: { status: :approved, approved_date: borrow_request.start_date - 1.day } }, format: :html
        expect(flash[:notice]).to eq(I18n.t("admin.borrow_requests.change_status.status_updated"))
      end

      it "redirects to borrow_request path" do
        patch :change_status, params: { id: borrow_request.id, borrow_request: { status: :approved, approved_date: borrow_request.start_date - 1.day } }, format: :html
        expect(response).to redirect_to(admin_borrow_request_path(borrow_request))
      end
    end

    context "when status changes to approved but stock is insufficient" do
      before { book.update!(available_quantity: 1) }

      it "sets flash notice" do
        patch :change_status, params: { id: borrow_request.id, borrow_request: { status: :approved, approved_date: borrow_request.start_date - 1.day } }, format: :html
        expect(flash[:notice]).to eq(I18n.t("admin.borrow_requests.change_status.status_updated"))
      end

      it "redirects to borrow_request path" do
        patch :change_status, params: { id: borrow_request.id, borrow_request: { status: :approved, approved_date: borrow_request.start_date - 1.day } }, format: :html
        expect(response).to redirect_to(admin_borrow_request_path(borrow_request))
      end
    end

    context "when status changes to rejected" do
      it "does not set approved_by_admin_id" do
        patch :change_status, params: { id: borrow_request.id, borrow_request: { status: :rejected } }, format: :html
        expect(borrow_request.reload.approved_by_admin_id).to be_nil
      end
    end

    context "when status is invalid" do
      it "raises ArgumentError" do
        expect {
          patch :change_status, params: { id: borrow_request.id, borrow_request: { status: "invalid_status" } }
        }.to raise_error(ArgumentError, /is not a valid status/)
      end
    end

    context "when status changes to returned" do
      before do
        borrow_request.update!(status: :borrowed)
        book.update!(available_quantity: 0)
      end

      it "updates status to returned" do
        travel_to Time.zone.local(2025, 8, 25, 13, 0, 0) do
          patch :change_status, params: { id: borrow_request.id, borrow_request: { status: :returned } }, format: :html
          expect(borrow_request.reload.status).to eq("returned")
        end
      end

      it "sets actual_return_date" do
        travel_to Time.zone.local(2025, 8, 25, 13, 0, 0) do
          patch :change_status, params: { id: borrow_request.id, borrow_request: { status: :returned } }, format: :html
          expect(borrow_request.reload.actual_return_date.to_date).to eq(Time.current.to_date)
        end
      end

      it "sets returned_by_admin_id" do
        travel_to Time.zone.local(2025, 8, 25, 13, 0, 0) do
          patch :change_status, params: { id: borrow_request.id, borrow_request: { status: :returned } }, format: :html
          expect(borrow_request.reload.returned_by_admin_id).to eq(admin_user.id)
        end
      end

      it "increments book stock" do
        travel_to Time.zone.local(2025, 8, 25, 13, 0, 0) do
          patch :change_status, params: { id: borrow_request.id, borrow_request: { status: :returned } }, format: :html
          expect(book.reload.available_quantity).to eq(2)
        end
      end

      it "sets flash notice" do
        travel_to Time.zone.local(2025, 8, 25, 13, 0, 0) do
          patch :change_status, params: { id: borrow_request.id, borrow_request: { status: :returned } }, format: :html
          expect(flash[:notice]).to eq(I18n.t("admin.borrow_requests.change_status.status_updated"))
        end
      end

      it "redirects to borrow_request path" do
        travel_to Time.zone.local(2025, 8, 25, 13, 0, 0) do
          patch :change_status, params: { id: borrow_request.id, borrow_request: { status: :returned } }, format: :html
          expect(response).to redirect_to(admin_borrow_request_path(borrow_request))
        end
      end
    end
  end

  describe "#approved_attributes" do
    before { allow(controller).to receive(:current_user).and_return(admin_user) }

    context "when prev_status is not approved and approved_date present" do
      before { allow(controller).to receive(:borrow_request_params).and_return({ approved_date: Date.yesterday }) }

      it "sets approved_by_admin_id" do
        result = controller.send(:approved_attributes, :pending)
        expect(result[:approved_by_admin_id]).to eq(admin_user.id)
      end

      it "sets approved_date" do
        result = controller.send(:approved_attributes, :pending)
        expect(result[:approved_date]).to eq(Date.yesterday)
      end

      it "sets rejected_by_admin_id as nil" do
        result = controller.send(:approved_attributes, :pending)
        expect(result[:rejected_by_admin_id]).to be_nil
      end
    end

    context "when prev_status is not approved and approved_date blank" do
      before { allow(controller).to receive(:borrow_request_params).and_return({ approved_date: "" }) }

      it "defaults approved_date to Time.current" do
        travel_to Time.zone.local(2025, 8, 25, 12, 0, 0) do
          result = controller.send(:approved_attributes, :pending)
          expect(result[:approved_date]).to eq(Time.current)
        end
      end
    end

    context "when prev_status is approved" do
      before { allow(controller).to receive(:borrow_request_params).and_return({}) }

      it "only clears rejected_by_admin_id" do
        result = controller.send(:approved_attributes, :approved)
        expect(result).to eq(rejected_by_admin_id: nil)
      end
    end
  end

  describe "#borrowed_attributes" do
    context "when actual_borrow_date is present" do
      before { allow(controller).to receive(:borrow_request_params).and_return({ actual_borrow_date: Date.yesterday }) }

      it "returns actual_borrow_date" do
        expect(controller.send(:borrowed_attributes)[:actual_borrow_date]).to eq(Date.yesterday)
      end

      it "returns borrowed_by_admin_id" do
        expect(controller.send(:borrowed_attributes)[:borrowed_by_admin_id]).to eq(admin_user.id)
      end
    end

    context "when actual_borrow_date is blank" do
      before { allow(controller).to receive(:borrow_request_params).and_return({ actual_borrow_date: "" }) }

      it "defaults actual_borrow_date to Time.current" do
        travel_to Time.zone.local(2025, 8, 25, 12, 0, 0) do
          expect(controller.send(:borrowed_attributes)[:actual_borrow_date]).to eq(Time.current)
        end
      end
    end
  end

  describe "#rejected_attributes" do
    before { allow(controller).to receive(:borrow_request_params).and_return({}) }

    it "returns rejected_by_admin_id" do
      expect(controller.send(:rejected_attributes)[:rejected_by_admin_id]).to eq(admin_user.id)
    end

    it "resets approved_by_admin_id to nil" do
      expect(controller.send(:rejected_attributes)[:approved_by_admin_id]).to be_nil
    end
  end

  describe "#returned_attributes" do
    context "when actual_return_date is present" do
      before { allow(controller).to receive(:borrow_request_params).and_return({ actual_return_date: Date.today }) }

      it "returns actual_return_date" do
        expect(controller.send(:returned_attributes)[:actual_return_date]).to eq(Date.today)
      end

      it "returns returned_by_admin_id" do
        expect(controller.send(:returned_attributes)[:returned_by_admin_id]).to eq(admin_user.id)
      end
    end

    context "when actual_return_date is blank" do
      before { allow(controller).to receive(:borrow_request_params).and_return({ actual_return_date: "" }) }

      it "defaults actual_return_date to Time.current" do
        travel_to Time.zone.local(2025, 8, 25, 13, 0, 0) do
          expect(controller.send(:returned_attributes)[:actual_return_date]).to eq(Time.current)
        end
      end
    end
  end

  describe "#decrement_book_stock" do
    it "decreases available_quantity" do
      controller.instance_variable_set(:@borrow_request, borrow_request)
      controller.send(:decrement_book_stock)
      expect(book.reload.available_quantity).to eq(3)
    end

    it "increases borrow_count" do
      controller.instance_variable_set(:@borrow_request, borrow_request)
      controller.send(:decrement_book_stock)
      expect(book.reload.borrow_count).to eq(2)
    end
  end

  describe "#increment_book_stock" do
    before { book.update!(available_quantity: 3) }

    it "increases available_quantity" do
      controller.instance_variable_set(:@borrow_request, borrow_request)
      controller.send(:increment_book_stock)
      expect(book.reload.available_quantity).to eq(5)
    end
  end

  describe "#update_request_attributes" do
    it "updates admin_note" do
      controller.instance_variable_set(:@borrow_request, borrow_request)
      allow(controller).to receive(:borrow_request_params).and_return({ admin_note: "note" })
      allow(controller).to receive(:status_extra_attributes).with(:pending, :approved).and_return({ approved_by_admin_id: admin_user.id })
      controller.send(:update_request_attributes, :pending, :approved)
      expect(borrow_request.reload.admin_note).to eq("note")
    end

    it "updates approved_by_admin_id" do
      controller.instance_variable_set(:@borrow_request, borrow_request)
      allow(controller).to receive(:borrow_request_params).and_return({ admin_note: "note" })
      allow(controller).to receive(:status_extra_attributes).with(:pending, :approved).and_return({ approved_by_admin_id: admin_user.id })
      controller.send(:update_request_attributes, :pending, :approved)
      expect(borrow_request.reload.approved_by_admin_id).to eq(admin_user.id)
    end
  end

  describe "#handle_approved_status" do
    context "prev_status not approved" do
      it "decrements stock" do
        expect(controller).to receive(:decrement_book_stock)
        controller.instance_variable_set(:@borrow_request, borrow_request)
        controller.send(:handle_approved_status, :pending)
      end

      it "sends email" do
        expect(controller).to receive(:send_status_notification_email).with(:approved)
        controller.instance_variable_set(:@borrow_request, borrow_request)
        controller.send(:handle_approved_status, :pending)
      end
    end

    context "prev_status approved" do
      it "does not decrement stock" do
        expect(controller).not_to receive(:decrement_book_stock)
        controller.instance_variable_set(:@borrow_request, borrow_request)
        controller.send(:handle_approved_status, :approved)
      end

      it "sends email" do
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

    it "increments stock for returned when prev not returned" do
      expect(controller).to receive(:increment_book_stock)
      controller.instance_variable_set(:@borrow_request, borrow_request)
      controller.send(:handle_status_side_effects, :borrowed, :returned)
    end

    it "does not increment stock for returned when prev returned" do
      expect(controller).not_to receive(:increment_book_stock)
      controller.instance_variable_set(:@borrow_request, borrow_request)
      controller.send(:handle_status_side_effects, :returned, :returned)
    end
  end
  
  # === send_status_notification_email ===
  describe "#send_status_notification_email" do
    it "sends approved email" do
      expect(UserMailer).to receive_message_chain(:borrow_request_approved,
                                                  :deliver_later)
      controller.instance_variable_set(:@borrow_request, borrow_request)
      controller.send(:send_status_notification_email, :approved)
    end

    it "sends rejected email" do
      expect(UserMailer).to receive_message_chain(:borrow_request_rejected,
                                                  :deliver_later)
      controller.instance_variable_set(:@borrow_request, borrow_request)
      controller.send(:send_status_notification_email, :rejected)
    end

    it "rescues StandardError and logs error" do
      controller.instance_variable_set(:@borrow_request, borrow_request)
      allow(UserMailer).to receive_message_chain(:borrow_request_approved,
                                                 :deliver_later)
        .and_raise(StandardError.new("Boom"))

      expect(Rails.logger).to receive(:error)
      result = controller.send(:send_status_notification_email, :approved)
      expect(result).to include("Failed to send borrow request approved email")
    end
  end

  # === handle_update_error ===
  describe "#handle_update_error" do
    before { controller.instance_variable_set(:@borrow_request, borrow_request) }

    it "renders turbo_stream with unprocessable_entity" do
      fake_format = double("format")
      allow(fake_format).to receive(:turbo_stream) { |&block| block.call }
      allow(fake_format).to receive(:html)
      allow(controller).to receive(:respond_to).and_yield(fake_format)
      allow(controller).to receive(:render)
      
      expect { controller.send(:handle_update_error, StandardError.new) }.not_to raise_error
    end

    it "renders html edit_status with unprocessable_entity" do
      fake_format = double("format")
      allow(fake_format).to receive(:turbo_stream)
      allow(fake_format).to receive(:html) { |&block| block.call }
      allow(controller).to receive(:respond_to).and_yield(fake_format)
      allow(controller).to receive(:render)
      
      expect { controller.send(:handle_update_error, StandardError.new) }.not_to raise_error
    end
  end

  # === status_extra_attributes ===
  describe "#status_extra_attributes" do
    it "returns approved_attributes for approved status" do
      expect(controller).to receive(:approved_attributes).with(:pending)
      controller.send(:status_extra_attributes, :pending, :approved)
    end

    it "returns borrowed_attributes for borrowed status" do
      expect(controller).to receive(:borrowed_attributes)
      controller.send(:status_extra_attributes, :pending, :borrowed)
    end

    it "returns rejected_attributes for rejected status" do
      expect(controller).to receive(:rejected_attributes)
      controller.send(:status_extra_attributes, :pending, :rejected)
    end

    it "returns returned_attributes for returned status" do
      expect(controller).to receive(:returned_attributes)
      controller.send(:status_extra_attributes, :pending, :returned)
    end

    it "returns empty hash for unknown status" do
      expect(controller.send(:status_extra_attributes, :pending,
                             :unknown)).to eq({})
    end
  end

  # === change_status ===
  describe "#change_status" do
    before do
      controller.instance_variable_set(:@borrow_request, borrow_request)
      allow(controller).to receive(:borrow_request_params).and_return({status: "approved"}) # rubocop:disable Layout/LineLength
    end

    it "calls update_borrow_request_status when status changed" do
      expect(controller).to receive(:update_borrow_request_status).with(
        :pending, :approved
      )
      allow(controller).to receive(:respond_to_success)
      controller.send(:change_status)
    end

    it "calls handle_no_change when status not changed" do
      allow(controller).to receive(:borrow_request_params).and_return({status: "pending"}) # rubocop:disable Layout/LineLength
      expect(controller).to receive(:handle_no_change)
      controller.send(:change_status)
    end

    it "rescues ActiveRecord::RecordInvalid and calls handle_update_error" do
      allow(controller).to receive(:update_borrow_request_status)
        .and_raise(ActiveRecord::RecordInvalid.new(borrow_request))
      expect(controller).to receive(:handle_update_error)
      controller.send(:change_status)
    end
  end
end

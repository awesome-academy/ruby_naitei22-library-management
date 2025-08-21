require 'rails_helper'

RSpec.describe BorrowRequest, type: :model do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :admin) }
  let(:borrow_request) { build(:borrow_request, user: user) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:approved_by_admin).class_name('User').optional }
    it { is_expected.to belong_to(:rejected_by_admin).class_name('User').optional }
    it { is_expected.to belong_to(:returned_by_admin).class_name('User').optional }
    it { is_expected.to belong_to(:borrowed_by_admin).class_name('User').optional }
    it { is_expected.to have_many(:borrow_request_items).dependent(:destroy) }
    it { is_expected.to have_many(:books).through(:borrow_request_items) }

    it "destroys associated borrow_request_items when deleted" do
      borrow_request = create(:borrow_request)
      expect { borrow_request.destroy }.to change(BorrowRequestItem, :count).by(-borrow_request.borrow_request_items.count)
    end

    it "can access associated books through borrow_request_items" do
      borrow_request_item = create(:borrow_request_item)
      borrow_request = borrow_request_item.borrow_request
      expect(borrow_request.books).to include(borrow_request_item.book)
    end
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(
      expired: -1, pending: 0, approved: 1, rejected: 2, returned: 3,
      overdue: 4, cancelled: 5, borrowed: 6, need_update: 7
    ) }

    it "returns the correct status string and predicate for all enum values" do
      statuses = {
        expired: -1,
        pending: 0,
        approved: 1,
        rejected: 2,
        returned: 3,
        overdue: 4,
        cancelled: 5,
        borrowed: 6,
        need_update: 7
      }

      statuses.each do |status, value|
        attributes = { status: status }
        attributes[:admin_note] = "Rejected for testing" if status == :rejected

        if %i[returned borrowed].include?(status)
          attributes[:approved_date] = Date.current - 3.days
          attributes[:start_date] = attributes[:approved_date] + 1.day
          attributes[:actual_borrow_date] = attributes[:start_date] + 1.day
          attributes[:end_date] = attributes[:start_date] + 5.days

          # actual_return_date <= today
          attributes[:actual_return_date] = [attributes[:actual_borrow_date] + 1.day, Date.current].min if status == :returned
        end

        br = create(:borrow_request, attributes)
        expect(br.status).to eq(status.to_s), "Expected status to be '#{status}' for value #{value}"
        expect(br.send("#{status}?")).to eq(true), "Expected #{status}? to be true for status '#{status}'"
      end
    end

    it "sets correct predicate to false for non-matching statuses" do
      br = create(:borrow_request, status: :approved)
      expect(br.approved?).to eq(true)
      %i[expired pending rejected returned overdue cancelled borrowed need_update].each do |status|
        next if status == :approved
        expect(br.send("#{status}?")).to eq(false), "Expected #{status}? to be false when status is 'approved'"
      end
    end

    it "raises an error for invalid status values" do
      expect {
        create(:borrow_request, status: :invalid_status)
      }.to raise_error(ArgumentError, /is not a valid status/)
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:request_date) }
    it { is_expected.to validate_presence_of(:start_date) }
    it { is_expected.to validate_presence_of(:end_date) }

    context "custom validations" do
      it "requires end_date after start_date" do
        borrow_request.start_date = 2.days.from_now
        borrow_request.end_date = 1.day.from_now
        expect(borrow_request).not_to be_valid
        expect(borrow_request.errors.details[:end_date]).to include(error: :after_start_date)
      end

      it "requires actual_return_date if returned" do
        borrow_request.status = :returned
        borrow_request.actual_borrow_date ||= Date.current
        borrow_request.actual_return_date = nil
        expect(borrow_request).not_to be_valid
        expect(borrow_request.errors.details[:actual_return_date]).to include(error: :blank_if_returned)
      end

      it "adds error if status is returned but actual_return_date is blank" do
        borrow_request.status = :returned
        borrow_request.actual_return_date = nil
        borrow_request.validate
        expect(borrow_request.errors.details[:actual_return_date]).to include(error: :blank_if_returned)
      end

      it "requires admin_note if rejected" do
        borrow_request.status = :rejected
        borrow_request.admin_note = nil
        expect(borrow_request).not_to be_valid
        expect(borrow_request.errors.details[:admin_note]).to include(error: :blank_if_rejected)
      end

      it "does not allow actual_return_date in the future" do
        borrow_request.status = :returned
        borrow_request.actual_borrow_date ||= Date.current
        borrow_request.actual_return_date = 1.day.from_now
        expect(borrow_request).not_to be_valid
        expect(borrow_request.errors.details[:actual_return_date]).to include(error: :cannot_be_future)
      end

      it "requires actual_return_date after actual_borrow_date" do
        borrow_request.status = :returned
        borrow_request.actual_borrow_date = Date.current
        borrow_request.actual_return_date = Date.current - 1.day
        expect(borrow_request).not_to be_valid
        expect(borrow_request.errors.details[:actual_return_date]).to include(error: :after_borrowed_date)
      end
      

      it "requires approved_date before start_date" do
        borrow_request.status = :approved
        borrow_request.approved_date = Date.current + 6.days
        borrow_request.start_date = Date.current + 5.days
        expect(borrow_request).not_to be_valid
        expect(borrow_request.errors.details[:approved_date]).to include(error: :before_start_date)
      end

      it "requires approved_date after request_date" do
        borrow_request.status = :approved
        borrow_request.request_date = Date.current
        borrow_request.approved_date = Date.current - 1.day
        expect(borrow_request).not_to be_valid
        expect(borrow_request.errors.details[:approved_date]).to include(error: :after_request_date)
      end

      it "requires actual_borrow_date after start_date" do
        borrow_request.status = :borrowed
        borrow_request.start_date = Date.current
        borrow_request.approved_date = Date.current - 1.day
        borrow_request.actual_borrow_date = Date.current - 1.day
        expect(borrow_request).not_to be_valid
        expect(borrow_request.errors.details[:actual_borrow_date]).to include(error: :after_start_date)
      end

      it "requires actual_borrow_date before end_date" do
        borrow_request.status = :borrowed
        borrow_request.end_date = Date.current + 5.days
        borrow_request.approved_date = Date.current
        borrow_request.actual_borrow_date = Date.current + 6.days
        expect(borrow_request).not_to be_valid
        expect(borrow_request.errors.details[:actual_borrow_date]).to include(error: :before_end_date)
      end

      it "requires actual_borrow_date after approved_date" do
        borrow_request.status = :borrowed
        borrow_request.approved_date = Date.current
        borrow_request.actual_borrow_date = Date.current - 1.day
        expect(borrow_request).not_to be_valid
        expect(borrow_request.errors.details[:actual_borrow_date]).to include(error: :after_approved_date)
      end
    end
  end

  describe "delegates" do
    it { is_expected.to delegate_method(:name).to(:user).with_prefix }
    it { is_expected.to delegate_method(:email).to(:user).with_prefix }
    it { is_expected.to delegate_method(:avatar).to(:user).with_prefix }
    it { is_expected.to delegate_method(:name).to(:approved_by_admin).with_prefix.allow_nil }
    it { is_expected.to delegate_method(:name).to(:rejected_by_admin).with_prefix.allow_nil }
    it { is_expected.to delegate_method(:name).to(:returned_by_admin).with_prefix.allow_nil }
    it { is_expected.to delegate_method(:name).to(:borrowed_by_admin).with_prefix.allow_nil }

    it "handles nil admin delegation gracefully" do
      br = build(:borrow_request, approved_by_admin: nil, rejected_by_admin: nil, returned_by_admin: nil, borrowed_by_admin: nil)
      expect(br.approved_by_admin_name).to be_nil
      expect(br.rejected_by_admin_name).to be_nil
      expect(br.returned_by_admin_name).to be_nil
      expect(br.borrowed_by_admin_name).to be_nil
    end
  end

  describe "scopes" do
    let!(:pending_request) { create(:borrow_request, status: :pending, user: user, start_date: 1.day.ago, end_date: 5.days.from_now) }
    let!(:borrowed_request) { create(:borrow_request, :borrowed,
                                     user: user,
                                     request_date: 3.days.ago,
                                     start_date: 2.days.ago,
                                     end_date: 1.day.from_now,
                                     approved_date: 3.days.ago,
                                     actual_borrow_date: 2.days.ago) }

    describe "by_status" do
      it "filters by specified status" do
        expect(BorrowRequest.by_status("pending")).to include(pending_request)
        expect(BorrowRequest.by_status("pending")).not_to include(borrowed_request)
      end

      it "returns all requests when status is blank" do
        expect(BorrowRequest.by_status(nil)).to include(pending_request, borrowed_request)
      end
    end

    describe "by_request_date_from" do
      it "returns requests with request_date on or after the given date" do
        recent_request = create(:borrow_request, request_date: Date.current)
        old_request = create(:borrow_request, request_date: Date.current - 10.days)
        expect(BorrowRequest.by_request_date_from(Date.current - 5.days)).to include(recent_request)
        expect(BorrowRequest.by_request_date_from(Date.current - 5.days)).not_to include(old_request)
      end

      it "returns all requests when date is blank" do
        recent_request = create(:borrow_request, request_date: Date.current)
        old_request = create(:borrow_request, request_date: Date.current - 10.days)
        expect(BorrowRequest.by_request_date_from(nil)).to include(recent_request, old_request)
      end
    end

    describe "by_request_date_to" do
      it "returns requests with request_date on or before the given date" do
        recent_request = create(:borrow_request, request_date: Date.current)
        old_request = create(:borrow_request, request_date: Date.current - 10.days)
        expect(BorrowRequest.by_request_date_to(Date.current - 5.days)).to include(old_request)
        expect(BorrowRequest.by_request_date_to(Date.current - 5.days)).not_to include(recent_request)
      end

      it "returns all requests when date is blank" do
        recent_request = create(:borrow_request, request_date: Date.current)
        old_request = create(:borrow_request, request_date: Date.current - 10.days)
        expect(BorrowRequest.by_request_date_to(nil)).to include(recent_request, old_request)
      end
    end

    describe "overdue_requests" do
      it "returns borrowed requests with end_date in the past" do
        overdue_request = create(:borrow_request, :borrowed, 
                                request_date: Date.current - 3.days,
                                start_date: Date.current - 2.days,
                                end_date: Date.current - 1.day,
                                approved_date: Date.current - 3.days,
                                actual_borrow_date: Date.current - 2.days)
        expect(BorrowRequest.overdue_requests).to include(overdue_request)
      end

      it "does not include non-overdue borrowed requests" do
        non_overdue_request = create(:borrow_request, :borrowed,
                                    request_date: Date.current - 3.days,
                                    start_date: Date.current - 2.days,
                                    end_date: Date.current + 1.day,
                                    approved_date: Date.current - 3.days,
                                    actual_borrow_date: Date.current - 2.days)
        expect(BorrowRequest.overdue_requests).not_to include(non_overdue_request)
      end

      it "does not include non-borrowed requests" do
        pending_request = create(:borrow_request, :pending, 
                                start_date: Date.current - 2.days, 
                                end_date: Date.current - 1.day)
        expect(BorrowRequest.overdue_requests).not_to include(pending_request)
      end
    end

    describe "expired_requests" do
      it "returns pending requests with start_date in the past" do
        expired_request = create(:borrow_request, :pending, start_date: Date.current - 1.day)
        expect(BorrowRequest.expired_requests).to include(expired_request)
      end

      it "does not include pending requests with start_date in the future" do
        br = create(:borrow_request, :non_expired)
        expect(BorrowRequest.expired_requests).not_to include(br)
      end

      it "does not include non-pending requests" do
        approved_request = create(:borrow_request, :approved, 
                                 start_date: Date.current - 1.day,
                                 request_date: Date.current - 2.days,
                                 approved_date: Date.current - 2.days)
        expect(BorrowRequest.expired_requests).not_to include(approved_request)
      end
    end

    describe "sorted" do
      it "returns requests in descending created_at order" do
        old_request = create(:borrow_request, created_at: 2.days.ago)
        new_request = create(:borrow_request, created_at: Time.current)
        expect(BorrowRequest.sorted.first).to eq(new_request)
        expect(BorrowRequest.sorted.last).to eq(old_request)
      end
    end
  end

  describe "callbacks" do
    it "builds admin users appropriately after build for borrowed status" do
      br = build(:borrow_request, :borrowed,
                 request_date: 3.days.ago,
                 start_date: 2.days.ago,
                 approved_date: 3.days.ago,
                 actual_borrow_date: 2.days.ago)
      expect(br.borrowed_by_admin).to be_present
      expect(br.approved_by_admin).to be_present
    end

    it "builds admin users appropriately after create for borrowed status" do
      br = create(:borrow_request, :borrowed,
                  request_date: 3.days.ago,
                  start_date: 2.days.ago,
                  approved_date: 3.days.ago,
                  actual_borrow_date: 2.days.ago)
      expect(br.borrowed_by_admin).to be_present
      expect(br.approved_by_admin).to be_present
    end

    it "builds admin users appropriately after build for rejected status" do
      br = build(:borrow_request, :rejected)
      expect(br.rejected_by_admin).to be_present
    end

    it "builds admin users appropriately after build for returned status" do
      br = build(:borrow_request, :returned,
                 request_date: 3.days.ago,
                 start_date: 2.days.ago,
                 approved_date: 3.days.ago,
                 actual_borrow_date: 2.days.ago,
                 actual_return_date: 1.day.ago)
      expect(br.approved_by_admin).to be_present
      expect(br.borrowed_by_admin).to be_present
      expect(br.returned_by_admin).to be_present
    end

    it "creates borrow_request_items after create" do
      br = create(:borrow_request)
      expect(br.borrow_request_items.count).to be_between(1, 3)
    end
  end

  describe ".auto_update_overdue_requests" do
    it "updates overdue requests to overdue status" do
      overdue_request = create(:borrow_request, :borrowed,
                              request_date: Date.current - 3.days,
                              start_date: Date.current - 2.days,
                              end_date: Date.current - 1.day,
                              approved_date: Date.current - 3.days,
                              actual_borrow_date: Date.current - 2.days)
      non_overdue_request = create(:borrow_request, :borrowed,
                                  request_date: Date.current - 3.days,
                                  start_date: Date.current - 2.days,
                                  end_date: Date.current + 1.day,
                                  approved_date: Date.current - 3.days,
                                  actual_borrow_date: Date.current - 2.days)
      BorrowRequest.auto_update_overdue_requests
      expect(overdue_request.reload.status).to eq("overdue")
      expect(non_overdue_request.reload.status).to eq("borrowed")
    end

    it "logs the process" do
      create(:borrow_request, :borrowed,
             request_date: Date.current - 3.days,
             start_date: Date.current - 2.days,
             end_date: Date.current - 1.day,
             approved_date: Date.current - 3.days,
             actual_borrow_date: Date.current - 2.days)
      logger = instance_double(Logger)
      allow(BorrowRequest).to receive(:setup_logger).and_return(logger)
      allow(logger).to receive(:info)
      BorrowRequest.auto_update_overdue_requests
      expect(logger).to have_received(:info).with("Start auto updating overdue requests")
      expect(logger).to have_received(:info).with(/Updated \d+ requests in this batch/)
      expect(logger).to have_received(:info).with("Finished auto updating overdue requests")
    end

    it "handles errors and logs them" do
      allow(BorrowRequest).to receive(:overdue_requests).and_raise(StandardError.new("Test error"))
      logger = instance_double(Logger)
      allow(BorrowRequest).to receive(:setup_logger).and_return(logger)
      allow(logger).to receive(:info)
      allow(logger).to receive(:error)
      BorrowRequest.auto_update_overdue_requests
      expect(logger).to have_received(:info).with("Start auto updating overdue requests")
      expect(logger).to have_received(:error).with(/Error during auto update: Test error/)
    end
  end

  describe ".auto_update_expired_requests" do
    it "updates expired requests to expired status" do
      expired_request = create(:borrow_request, :pending, start_date: Date.current - 1.day)
      non_expired_request = create(:borrow_request, :non_expired)
      BorrowRequest.auto_update_expired_requests
      expect(expired_request.reload.status).to eq("expired")
      expect(non_expired_request.reload.status).to eq("pending")
    end

    it "logs the process" do
      create(:borrow_request, :pending, start_date: Date.current - 1.day)
      logger = instance_double(Logger)
      allow(BorrowRequest).to receive(:setup_expired_logger).and_return(logger)
      allow(logger).to receive(:info)
      BorrowRequest.auto_update_expired_requests
      expect(logger).to have_received(:info).with("Start auto updating expired requests")
      expect(logger).to have_received(:info).with(/Updated \d+ requests in this batch/)
      expect(logger).to have_received(:info).with("Finished auto updating expired requests")
    end

    it "handles errors and logs them" do
      allow(BorrowRequest).to receive(:expired_requests).and_raise(StandardError.new("Test error"))
      logger = instance_double(Logger)
      allow(BorrowRequest).to receive(:setup_expired_logger).and_return(logger)
      allow(logger).to receive(:info)
      allow(logger).to receive(:error)
      BorrowRequest.auto_update_expired_requests
      expect(logger).to have_received(:info).with("Start auto updating expired requests")
      expect(logger).to have_received(:error).with(/Error during auto update: Test error/)
    end
  end

  describe "#stock_error_messages" do
    let(:book_with_enough_stock) { create(:book, title: 'Sufficient Stock', available_quantity: 5) }
    let(:book_with_low_stock) { create(:book, title: 'Low Stock', available_quantity: 2) }

    let(:item1) { create(:borrow_request_item, book: book_with_enough_stock, quantity: 3) }
    let(:item2) { create(:borrow_request_item, book: book_with_low_stock, quantity: 5) }

    it "returns empty array if all books have sufficient stock" do
      br = create(:borrow_request, borrow_request_items: [item1])
      expect(br.stock_error_messages).to eq([])
    end

    it "returns error messages for books with insufficient stock" do
      br = create(:borrow_request, borrow_request_items: [item1, item2])
      expect(br.stock_error_messages).to eq([
        "Book 'Low Stock' only has 2 left (requested 5)"
      ])
    end

    it "returns multiple error messages if multiple books are low in stock" do
      book2 = create(:book, title: 'Another Low Stock', available_quantity: 1)
      item3 = create(:borrow_request_item, book: book2, quantity: 4)
      br = create(:borrow_request, borrow_request_items: [item2, item3])

      expect(br.stock_error_messages).to eq([
        "Book 'Low Stock' only has 2 left (requested 5)",
        "Book 'Another Low Stock' only has 1 left (requested 4)"
      ])
    end
  end


  describe ".ransackable_attributes" do
    it "returns the correct attributes" do
      expect(BorrowRequest.ransackable_attributes).to match_array(
        %w[id user_id request_date status start_date end_date actual_borrow_date actual_return_date]
      )
    end
  end

  describe ".ransackable_associations" do
    it "returns the correct associations" do
      expect(BorrowRequest.ransackable_associations).to match_array(%w[user])
    end
  end
end

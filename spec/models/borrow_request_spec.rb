require "rails_helper"

RSpec.describe BorrowRequest, type: :model do
  let(:user) { create(:user) }
  let(:book) { create(:book, available_quantity: 5) }
  let(:borrow_request) do
    described_class.new(
      user: user,
      request_date: Time.zone.now,
      start_date: Date.today + 1,
      end_date: Date.today + 2,
      status: :pending
    )
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:borrow_request_items).dependent(:destroy) }
    it { is_expected.to have_many(:books).through(:borrow_request_items) }
    it { is_expected.to belong_to(:approved_by_admin).optional }
    it { is_expected.to belong_to(:rejected_by_admin).optional }
    it { is_expected.to belong_to(:returned_by_admin).optional }
    it { is_expected.to belong_to(:borrowed_by_admin).optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:request_date) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:start_date) }
    it { is_expected.to validate_presence_of(:end_date) }
    it "is invalid if end_date is before start_date" do
      borrow_request.start_date = Date.today + 2
      borrow_request.end_date = Date.today + 1
      expect(borrow_request).not_to be_valid
    end
    it "requires actual_return_date if returned" do
      borrow_request.status = :returned
      borrow_request.actual_return_date = nil
      expect(borrow_request).not_to be_valid
    end
  end

  describe "scopes" do
    it "by_status returns correct requests" do
      borrow_request.save!
      expect(BorrowRequest.by_status("pending")).to include(borrow_request)
    end
    it "by_request_date_from returns requests after date" do
      borrow_request.save!
      expect(BorrowRequest.by_request_date_from(Date.today)).to include(borrow_request)
    end
    it "by_request_date_to returns requests before date" do
      borrow_request.save!
      expect(BorrowRequest.by_request_date_to(Date.today + 5)).to include(borrow_request)
    end
  end

  describe "class methods" do
    it "auto_update_overdue_requests does not raise" do
      expect { BorrowRequest.auto_update_overdue_requests(batch_size: 1) }.not_to raise_error
    end
    it "auto_update_expired_requests does not raise" do
      expect { BorrowRequest.auto_update_expired_requests(batch_size: 1) }.not_to raise_error
    end
  end
end

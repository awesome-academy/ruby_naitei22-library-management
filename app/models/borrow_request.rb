class BorrowRequest < ApplicationRecord
  belongs_to :user
  # belongs_to :book
  belongs_to :approved_by_admin, class_name: User.name, optional: true
  belongs_to :rejected_by_admin, class_name: User.name, optional: true
  belongs_to :returned_by_admin, class_name: User.name, optional: true
  belongs_to :borrowed_by_admin, class_name: User.name, optional: true

  has_many :borrow_request_items, dependent: :destroy
  has_many :books, through: :borrow_request_items

  enum status: {
    expired: -1,
    pending: 0,
    approved: 1,
    rejected: 2,
    returned: 3,
    overdue: 4,
    cancelled: 5,
    borrowed: 6
  }

  scope :by_status, lambda {|status|
    return all unless status.present? && statuses.key?(status)

    where(status:)
  }

  scope :by_request_date_from, lambda {|date|
    return all if date.blank?

    where("request_date >= ?", date.to_date)
  }

  scope :by_request_date_to, lambda {|date|
    return all if date.blank?

    where("request_date <= ?", date.to_date)
  }

  OVERDUE = "end_date < :now AND status = :borrowed".freeze
  EXPIRED = "start_date < :now AND status = :pending".freeze
  delegate :name, :email, :avatar, to: :user, prefix: true
  delegate :name, to: :approved_by_admin, prefix: true, allow_nil: true
  delegate :name, to: :rejected_by_admin, prefix: true, allow_nil: true
  delegate :name, to: :returned_by_admin, prefix: true, allow_nil: true
  delegate :name, to: :borrowed_by_admin, prefix: true, allow_nil: true

  scope :overdue_requests, (lambda do
    where(
      OVERDUE,
      now: Time.zone.now,
      borrowed: BorrowRequest.statuses[:borrowed]
    )
  end)
  scope :expired_requests, (lambda do
    where(
      EXPIRED,
      now: Time.zone.now,
      pending: BorrowRequest.statuses[:pending]
    )
  end)
  scope :sorted, -> {order(created_at: :desc)}
  validates :status, inclusion: {in: statuses.keys}
  validates :request_date, :status, :start_date, :end_date, presence: true
  validates :actual_return_date, presence: true, if: :returned?
  validate :end_date_after_start_date
  validate :admin_note_required_if_rejected, if: :rejected?
  validate :returned_date_required_if_return, if: :returned?
  validate :actual_return_date_cannot_be_future
  validate :actual_return_after_borrow_date
  validate :approved_date_before_start_date
  validate :approved_date_after_request_date
  validate :actual_borrow_date_after_start_date
  validate :actual_borrow_date_before_end_date
  validate :actual_borrow_date_after_approved_date

  def self.ransackable_attributes _auth_object = nil
    %w(
      id
      user_id
      request_date
      status
      start_date
      end_date
      actual_borrow_date
      actual_return_date
    )
  end

  def self.ransackable_associations _auth_object = nil
    %w(user)
  end

  def self.auto_update_overdue_requests batch_size: 100
    logger = setup_logger
    logger.info "Start auto updating overdue requests"
    process_batches(batch_size, logger)
    logger.info "Finished auto updating overdue requests"
  rescue StandardError => e
    log_error(logger, e)
  end

  def self.auto_update_expired_requests batch_size: 100
    logger = setup_expired_logger
    logger.info "Start auto updating expired requests"
    process_expired_batches(batch_size, logger)
    logger.info "Finished auto updating expired requests"
  rescue StandardError => e
    log_error(logger, e)
  end

  class << self
    private

    def setup_logger
      Logger.new(Rails.root.join("log/update_overdue.log")).tap do |logger|
        logger.level = Logger::INFO
        logger.formatter = proc do |severity, _datetime, _progname, msg|
          "[#{Time.zone.now}] #{severity} → #{msg}\n"
        end
      end
    end

    def process_batches batch_size, logger
      overdue_requests.find_in_batches(batch_size:) do |batch|
        updated_count = where(id: batch.map(&:id)).update_all(
          status: statuses[:overdue],
          updated_at: Time.zone.now
        )
        logger.info "Updated #{updated_count} requests in this batch"
      end
    end

    def log_error logger, error
      logger.error "Error during auto update: #{error.message}"
      logger.error error.backtrace.join("\n")
      Rails.logger.error error.full_message
    end

    def setup_expired_logger
      Logger.new(Rails.root.join("log/update_expired.log")).tap do |logger|
        logger.level = Logger::INFO
        logger.formatter = proc do |_severity, _datetime, _progname, msg|
          "[#{Time.zone.now}] INFO → #{msg}\n"
        end
      end
    end

    def process_expired_batches batch_size, logger
      expired_requests.find_in_batches(batch_size:) do |batch|
        updated_count = where(id: batch.map(&:id)).update_all(
          status: statuses[:expired],
          updated_at: Time.zone.now
        )
        logger.info "Updated #{updated_count} requests in this batch"
      end
    end
  end

  private
  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?
    return unless end_date < start_date

    errors.add(:end_date, :after_start_date)
  end

  def admin_note_required_if_rejected
    return unless status == :rejected && admin_note.blank?

    errors.add(:admin_note, :blank_if_rejected)
  end

  def returned_date_required_if_return
    return unless status == :returned && actual_return_date.blank?

    errors.add(:actual_return_date, :blank_if_returned)
  end

  def actual_return_date_cannot_be_future
    return if actual_return_date.blank?

    return unless actual_return_date > Time.zone.today

    errors.add(:actual_return_date, :cannot_be_future)
  end

  def approved_date_before_start_date
    return if approved_date.blank? || start_date.blank?

    return unless approved_date > start_date

    errors.add(:approved_date, :before_start_date)
  end

  def approved_date_after_request_date
    return if approved_date.blank? || request_date.blank?

    return unless approved_date < request_date.to_date

    errors.add(:approved_date, :after_request_date)
  end

  def actual_borrow_date_after_start_date
    return if actual_borrow_date.blank? || start_date.blank? || end_date.blank?

    return unless actual_borrow_date < start_date

    errors.add(:actual_borrow_date, :after_start_date)
  end

  def actual_borrow_date_before_end_date
    return if actual_borrow_date.blank? || end_date.blank?

    return unless actual_borrow_date > end_date

    errors.add(:actual_borrow_date, :before_end_date)
  end

  def actual_borrow_date_after_approved_date
    return if actual_borrow_date.blank? || approved_date.blank?

    return unless actual_borrow_date < approved_date

    errors.add(:actual_borrow_date, :after_approved_date)
  end

  def actual_return_after_borrow_date
    return if actual_return_date.blank? || actual_borrow_date.blank?

    return unless actual_return_date < actual_borrow_date

    errors.add(:actual_return_date, :after_borrowed_date)
  end
end

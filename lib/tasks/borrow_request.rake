namespace :borrow_request do
  desc "Gửi email nhắc nhở trả sách còn 1 ngày"
  task send_reminders: :environment do
    logger = Logger.new(Rails.root.join("log/borrow_request_reminder.log"))
    logger.info "[#{Time.zone.now}] Start sending reminders"

    BorrowRequest.where(
      status: BorrowRequest.statuses[:approved],
      end_date: Date.tomorrow
    ).find_each do |request|
      UserMailer.borrow_request_reminder(request).deliver_now
      logger.info "Sent reminder to #{request.user.email} for request ##{request.id}" # rubocop:disable Layout/LineLength
    rescue StandardError => e
      logger.error "Failed to send reminder to #{request.user.email}: #{e.message}" # rubocop:disable Layout/LineLength
    end

    logger.info "[#{Time.zone.now}] Finished sending reminders"
  end
end

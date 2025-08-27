namespace :user do
  desc "Xóa người dùng chưa xác nhận email trong 30 ngày"
  task remove_inactive_user: :environment do
    logger = Logger.new(Rails.root.join("log/user_cleanup.log"))
    logger.info "[#{Time.zone.now}] Start removing inactive users"

    threshold_date = 30.days.ago
    users_to_remove = User.where(confirmed_at: nil)
                          .where("confirmation_sent_at < ?", threshold_date)

    users_to_remove.find_each do |user|
      UserMailer.account_deleted(user).deliver_now

      if user.destroy
        logger.info "Deleted inactive user: #{user.email} (ID: #{user.id})"
      else
        logger.warn "Could not delete user #{user.email} (ID: #{user.id})"
      end
    rescue StandardError => e
      logger.error "Failed to process user #{user.email}: #{e.message}"
    end

    logger.info "[#{Time.zone.now}] Finished removing inactive users"
  end
end

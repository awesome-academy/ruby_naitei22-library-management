namespace :devise do
  desc "Copy old password_digest to encrypted_password"
  task migrate_passwords: :environment do
    User.find_each do |user|
      if user.password_digest.present? && user.encrypted_password.blank?
        user.update_column(:encrypted_password, user.password_digest)
      end
    end
    puts "✅ Migrated password_digest -> encrypted_password for all users"
  end
end

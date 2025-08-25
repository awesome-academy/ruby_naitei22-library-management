class AddDeviseFieldsToUsers < ActiveRecord::Migration[7.0]
  def change
    # Xóa mấy cột cũ của has_secure_password nếu tồn tại
    remove_column :users, :password_digest, :string if column_exists?(:users, :password_digest)
    remove_column :users, :remember_digest, :string if column_exists?(:users, :remember_digest)
    remove_column :users, :reset_digest, :string if column_exists?(:users, :reset_digest)
    remove_column :users, :activation_token, :string if column_exists?(:users, :activation_token)
    remove_column :users, :activation_digest, :string if column_exists?(:users, :activation_digest)

    # Đảm bảo encrypted_password tồn tại
    add_column :users, :encrypted_password, :string, null: false, default: "" unless column_exists?(:users, :encrypted_password)

    # Thêm index cho reset_password_token (Devise yêu cầu)
    add_index :users, :reset_password_token, unique: true unless index_exists?(:users, :reset_password_token)
  end
end

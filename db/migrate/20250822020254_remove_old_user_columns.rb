class RemoveOldUserColumns < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :password_digest, :string
    remove_column :users, :remember_digest, :string
    remove_column :users, :reset_digest, :string
    remove_column :users, :activation_token, :string
    remove_column :users, :activated_at, :datetime
    remove_column :users, :reset_sent_at, :datetime
    remove_column :users, :activation_digest, :string
  end
end

class AddDeviseFieldsToUsers < ActiveRecord::Migration[7.0]
  def change
    # Xóa các cột cũ không còn dùng nữa
    remove_column :users, :password_digest, :string
    remove_column :users, :activation_token, :string
    remove_column :users, :activation_digest, :string
    remove_column :users, :activated_at, :datetime
    remove_column :users, :remember_digest, :string
    remove_column :users, :reset_digest, :string
    remove_column :users, :reset_sent_at, :datetime

    ## Database authenticatable
    add_column :users, :encrypted_password, :string, null: false


    ## Confirmable
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email, :string # dùng khi đổi email

    ## Omniauthable
    # bạn đã có provider & uid nên giữ lại, chỉ cần index unique
    add_index :users, [:provider, :uid], unique: true

    ## Indexes
    add_index :users, :reset_password_token, unique: true
    add_index :users, :confirmation_token,   unique: true
  end
end

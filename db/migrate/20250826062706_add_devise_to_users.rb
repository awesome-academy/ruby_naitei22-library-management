class AddDeviseToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :encrypted_password, :string, null: false, default: ""

    add_column :users, :failed_attempts, :integer, default: 0, null: false
    add_column :users, :unlock_token, :string
    add_column :users, :locked_at, :datetime

    add_index :users, :reset_password_token, unique: true
    add_index :users, :unlock_token, unique: true
  end
end

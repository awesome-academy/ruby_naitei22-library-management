class AddNeedUpdateReasonToBorrowRequests < ActiveRecord::Migration[7.0]
  def change
    add_column :borrow_requests, :need_update_reason, :json
  end
end

class AddLastActiveAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :last_active_at, :timestamp
  end
end

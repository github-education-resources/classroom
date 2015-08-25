class RemoveStateFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :state
    change_column_null :users, :token, false
  end
end

class RemoveStateFromUsers < ActiveRecord::Migration[4.2]
  def change
    remove_column :users, :state
    change_column_null :users, :token, false
  end
end

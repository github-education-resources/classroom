class AddNonnullityConstarintToLastActiveAt < ActiveRecord::Migration
  def change
    change_column_null :users, :last_active_at, false
  end
end

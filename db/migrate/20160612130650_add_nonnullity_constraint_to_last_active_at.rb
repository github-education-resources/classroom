class AddNonnullityConstraintToLastActiveAt < ActiveRecord::Migration[4.2]
  def change
    change_column_null :users, :last_active_at, false
  end
end

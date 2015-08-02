class ChangeUsersUidToInteger < ActiveRecord::Migration
  def change
    change_column :users, :uid, 'integer USING CAST(uid AS integer)'
  end
end

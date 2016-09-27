class ChangeUsersUidToInteger < ActiveRecord::Migration[4.2]
  def change
    change_column :users, :uid, 'integer USING CAST(uid AS integer)'
  end
end

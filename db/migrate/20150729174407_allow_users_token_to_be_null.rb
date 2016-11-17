class AllowUsersTokenToBeNull < ActiveRecord::Migration[4.2]
  def change
    change_column :users, :token, :string, null: true
  end
end

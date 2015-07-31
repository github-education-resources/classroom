class AllowUsersTokenToBeNull < ActiveRecord::Migration
  def change
    change_column :users, :token, :string, null: true
  end
end

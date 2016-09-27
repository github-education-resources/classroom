class AddStateToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :state, :integer, default: 0
  end
end

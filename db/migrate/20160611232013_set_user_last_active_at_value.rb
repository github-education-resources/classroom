class SetUserLastActiveAtValue < ActiveRecord::Migration[4.2]
  def change
    User.find_each(batch_size: 100) do |user|
      user.update_columns(last_active_at: user.updated_at)
      User.update_index('stafftools#user') { user }
    end
  end
end

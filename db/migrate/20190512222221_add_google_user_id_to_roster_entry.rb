class AddGoogleUserIdToRosterEntry < ActiveRecord::Migration[5.1]
  def change
    add_column :roster_entries, :google_user_id, :string
    add_index  :roster_entries, :google_user_id
  end
end

class AddUseRosterIdToAssignments < ActiveRecord::Migration[5.1]

  def change
    add_column :assignments, :use_roster_id, :boolean, null: false, default: false
  end

end

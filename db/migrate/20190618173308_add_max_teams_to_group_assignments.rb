class AddMaxTeamsToGroupAssignments < ActiveRecord::Migration[5.1]
  def change
    add_column :group_assignments, :max_teams, :integer
  end
end

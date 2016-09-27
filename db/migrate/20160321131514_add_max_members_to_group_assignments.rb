class AddMaxMembersToGroupAssignments < ActiveRecord::Migration[4.2]
  def change
    add_column :group_assignments, :max_members, :integer
  end
end

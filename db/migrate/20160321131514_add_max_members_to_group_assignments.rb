class AddMaxMembersToGroupAssignments < ActiveRecord::Migration
  def change
    add_column :group_assignments, :max_members, :integer
  end
end

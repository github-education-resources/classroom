class AddGroupToGroupAssignmentRepo < ActiveRecord::Migration[4.2]
  def change
    add_column :group_assignment_repos, :group_id, :integer, null: false
  end
end

class AddGroupToGroupAssignmentRepo < ActiveRecord::Migration
  def change
    add_column :group_assignment_repos, :group_id, :integer, null: false
  end
end

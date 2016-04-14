class AddCopyOpenIssuesToAssignmentsAndGroupAssignments < ActiveRecord::Migration
  def change
    add_column :assignments, :copy_open_issues, :boolean, null: false, default: false
    add_column :group_assignments, :copy_open_issues, :boolean, null: false, default: false
  end
end

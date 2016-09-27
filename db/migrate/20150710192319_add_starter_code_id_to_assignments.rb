class AddStarterCodeIdToAssignments < ActiveRecord::Migration[4.2]
  def change
    add_column :assignments,       :starter_code_repo_id, :integer
    add_column :group_assignments, :starter_code_repo_id, :integer
    add_column :assignments,       :creator_id,           :integer
    add_column :group_assignments, :creator_id,           :integer
  end
end

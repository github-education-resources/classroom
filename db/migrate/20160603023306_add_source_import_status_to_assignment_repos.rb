class AddSourceImportStatusToAssignmentRepos < ActiveRecord::Migration
  def change
    add_column :assignment_repos, :is_starter_code_pushed, :boolean, default: false
    add_column :group_assignment_repos, :is_starter_code_pushed, :boolean, default: false
  end
end

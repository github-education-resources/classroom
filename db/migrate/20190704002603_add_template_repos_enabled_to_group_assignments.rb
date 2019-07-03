class AddTemplateReposEnabledToGroupAssignments < ActiveRecord::Migration[5.1]
  def change
    add_column :group_assignments, :template_repos_enabled, :boolean
  end
end

class AddTemplateReposEnabledToAssignments < ActiveRecord::Migration[5.1]
  def change
    add_column :assignments, :template_repos_enabled, :boolean
  end
end

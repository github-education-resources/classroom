class AddTemplateReposEnabledColumn < ActiveRecord::Migration[5.1]
  def change
    add_column :assignments, :template_repos_enabled, :boolean
    add_column :group_assignments, :template_repos_enabled, :boolean
  end
end

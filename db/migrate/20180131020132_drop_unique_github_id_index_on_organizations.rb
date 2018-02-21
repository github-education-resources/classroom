class DropUniqueGitHubIdIndexOnOrganizations < ActiveRecord::Migration[5.1]
  def change
    remove_index :organizations, :github_id
    add_index :organizations, :github_id
  end
end

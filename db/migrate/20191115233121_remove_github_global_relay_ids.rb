class RemoveGitHubGlobalRelayIds < ActiveRecord::Migration[5.2]
  def change
    remove_column :assignment_repos, :github_global_relay_id
    remove_column :group_assignment_repos, :github_global_relay_id
    remove_column :organizations, :github_global_relay_id
    remove_column :users, :github_global_relay_id
  end
end

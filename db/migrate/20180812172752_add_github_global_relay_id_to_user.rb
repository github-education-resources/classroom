class AddGitHubGlobalRelayIdToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :github_global_relay_id, :string
  end
end

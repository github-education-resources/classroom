class AddGlobalRelayIdToAssignmentRepos < ActiveRecord::Migration[5.1]
  def change
    add_column :assignment_repos, :global_relay_id, :string
    add_index :assignment_repos, :global_relay_id
  end
end

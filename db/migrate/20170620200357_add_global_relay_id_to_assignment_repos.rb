class AddGlobalRelayIdToAssignmentRepos < ActiveRecord::Migration[5.1]
  def change
    add_column :assignment_repos, :global_relay_id, :string
  end
end

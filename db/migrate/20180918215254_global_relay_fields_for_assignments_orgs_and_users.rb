class GlobalRelayFieldsForAssignmentsOrgsAndUsers < ActiveRecord::Migration[5.1]
  def change
    # With GraphQL in Classroom, an objects global_relay_id will refer to it's local ID. The GitHub global relay ID refers to it's external counterparts ID
    rename_column :assignment_repos, :global_relay_id, :github_global_relay_id

    add_column :group_assignment_repos, :global_relay_id, :string
    add_column :organizations, :global_relay_id, :string
    add_column :users, :global_relay_id, :string
  end
end

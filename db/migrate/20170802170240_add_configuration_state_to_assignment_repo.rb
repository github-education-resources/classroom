class AddConfigurationStateToAssignmentRepo < ActiveRecord::Migration[5.1]
  def change
    add_column :assignment_repos, :configuration_state, :integer, default: 0
    add_column :group_assignment_repos, :configuration_state, :integer, default: 0
  end
end

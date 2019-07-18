class AddColumnToLtiConfigurations < ActiveRecord::Migration[5.1]
  def change
    add_column :lti_configurations, :context_membership_url, :string
  end
end

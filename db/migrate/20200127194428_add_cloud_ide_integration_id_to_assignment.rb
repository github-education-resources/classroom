class AddCloudIDEIntegrationIdToAssignment < ActiveRecord::Migration[5.2]
  def change
    add_column :assignments, :cloud_ide_integration_id, :integer, index: true
    add_column :group_assignments, :cloud_ide_integration_id, :integer, index: true
  end
end

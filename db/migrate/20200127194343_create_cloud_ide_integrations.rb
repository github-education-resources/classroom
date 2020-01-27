class CreateCloudIDEIntegrations < ActiveRecord::Migration[5.2]
  def change
    create_table :cloud_ide_integrations do |t|
      t.belongs_to :cloud_ide, index: true
      t.timestamps
    end
  end
end

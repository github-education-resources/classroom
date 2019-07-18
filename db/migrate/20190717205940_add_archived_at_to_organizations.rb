class AddArchivedAtToOrganizations < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :archived_at, :datetime
  end
end

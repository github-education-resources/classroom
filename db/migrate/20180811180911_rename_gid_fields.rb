class RenameGidFields < ActiveRecord::Migration[5.1]
  def change
    rename_column :organizations, :global_relay_id, :github_global_relay_id
  end
end

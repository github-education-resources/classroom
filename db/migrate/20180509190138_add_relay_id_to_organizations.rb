class AddRelayIdToOrganizations < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :global_relay_id, :string
  end
end

class AddWebhookToOrganizations < ActiveRecord::Migration[4.2]
  def change
    add_column :organizations, :webhook_id, :string
    add_column :organizations, :is_webhook_active, :boolean, default: false
  end
end

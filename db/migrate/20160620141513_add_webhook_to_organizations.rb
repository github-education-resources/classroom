class AddWebhookToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :webhook_id, :string
    add_column :organizations, :is_webhook_active, :boolean, default: false
  end
end

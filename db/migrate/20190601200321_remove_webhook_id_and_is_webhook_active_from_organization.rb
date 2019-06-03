class RemoveWebhookIdAndIsWebhookActiveFromOrganization < ActiveRecord::Migration[5.1]
  def change
    remove_column :organizations, :webhook_id, :integer
    remove_column :organizations, :is_webhook_active, :boolean
  end
end

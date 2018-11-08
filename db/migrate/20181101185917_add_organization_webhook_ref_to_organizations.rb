class AddOrganizationWebhookRefToOrganizations < ActiveRecord::Migration[5.1]
  def change
    add_reference :organizations, :organization_webhook, foreign_key: true
  end
end

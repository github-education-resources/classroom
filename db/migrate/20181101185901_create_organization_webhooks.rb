class CreateOrganizationWebhooks < ActiveRecord::Migration[5.1]
  def change
    create_table :organization_webhooks do |t|
      t.integer  :github_id
      t.integer  :github_organization_id, null: false
      t.datetime :last_webhook_recieved

      t.timestamps
    end
    add_index :organization_webhooks, :github_id, unique: true
  end
end

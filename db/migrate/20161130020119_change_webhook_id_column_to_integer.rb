# frozen_string_literal: true
class ChangeWebhookIdColumnToInteger < ActiveRecord::Migration[5.0]
  def change
    change_column :organizations, :webhook_id, 'integer USING CAST(webhook_id AS integer)'
  end
end

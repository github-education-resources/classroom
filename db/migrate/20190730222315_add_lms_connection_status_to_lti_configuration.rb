class AddLmsConnectionStatusToLtiConfiguration < ActiveRecord::Migration[5.1]
  def change
    add_column :lti_configurations, :lms_connection_status, :text, null: false, default: "unlinked"
  end
end

class AddCachedLaunchMessageNonceToLtiConfiguration < ActiveRecord::Migration[5.1]
  def change
    add_column :lti_configurations, :cached_launch_message_nonce, :string
  end
end

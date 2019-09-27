class RemoveLmsLink < ActiveRecord::Migration[5.2]
  def change
    remove_column :lti_configurations, :lms_link
  end
end

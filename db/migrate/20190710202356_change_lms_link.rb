class ChangeLmsLink < ActiveRecord::Migration[5.1]
  def change
    change_column :lti_configurations, :lms_link, :text, :null => true
  end
end

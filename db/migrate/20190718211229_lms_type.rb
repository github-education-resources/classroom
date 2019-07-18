class LmsType < ActiveRecord::Migration[5.1]
  def change
    add_column :lti_configurations, :type, :text, :null => false, :default => "other"
  end
end

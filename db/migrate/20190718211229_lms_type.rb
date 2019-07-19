class LmsType < ActiveRecord::Migration[5.1]
  def change
    add_column :lti_configurations, :lms_type, :integer, :null => false, :default => 5
  end
end

class CreateLtiConfigurations < ActiveRecord::Migration[5.1]
  def change
    create_table :lti_configurations do |t|
      t.text :client_id
      t.text :secret
      t.text :lms_link

      t.timestamps
    end
  end
end

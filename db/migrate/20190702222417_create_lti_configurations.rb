class CreateLtiConfigurations < ActiveRecord::Migration[5.1]
  def change
    create_table :lti_configurations do |t|
      t.text :consumer_key
      t.text :shared_secret
      t.text :lms_link
      t.belongs_to :organization, index: true

      t.timestamps
    end
  end
end

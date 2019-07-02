class CreateLtiConfigurations < ActiveRecord::Migration[5.1]
  def change
    create_table :lti_configurations do |t|
      t.text :consumer_key, null: false
      t.text :shared_secret, null: false
      t.text :lms_link, null: false
      t.belongs_to :organization, index: true

      t.timestamps
    end
  end
end

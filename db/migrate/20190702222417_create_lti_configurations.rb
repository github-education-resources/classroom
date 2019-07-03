# frozen_string_literal: true

class CreateLtiConfigurations < ActiveRecord::Migration[5.1]
  def change
    create_table :lti_configurations do |t|
      t.text :consumer_key, null: false
      t.text :shared_secret, null: false
      t.text :lms_link, null: false
      t.belongs_to :organization, index: true, unique: true

      t.timestamps
    end

    add_index :lti_configurations, :consumer_key, unique: true
  end
end

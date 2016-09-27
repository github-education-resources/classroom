class CreateGroupsAndGroupings < ActiveRecord::Migration[4.2]
  def change
    create_table :groups do |t|
      t.integer :github_team_id, null: false

      t.timestamps null: false
    end

    add_index :groups, :github_team_id, unique: true

    create_table :groupings do |t|
      t.string     :title,        null: false
      t.belongs_to :organization, index: true

      t.timestamps null: false
    end

    change_table :groups do |t|
      t.belongs_to :grouping, index: true
    end
  end
end

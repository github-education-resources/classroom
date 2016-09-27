class CreateRepoAccesses < ActiveRecord::Migration[4.2]
  def change
    create_table :repo_accesses do |t|
      t.integer :github_team_id,  null: false

      t.belongs_to :organization, index: true
      t.belongs_to :user,         index: true

      t.timestamps null: false
    end

    add_index :repo_accesses, :github_team_id, unique: true
  end
end

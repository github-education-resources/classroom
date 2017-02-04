class CreateAssignmentRepos < ActiveRecord::Migration[4.2]
  def change
    create_table :assignment_repos do |t|
      t.integer :github_repo_id, null: false
      t.belongs_to :repo_access, index: true

      t.timestamps null: false
    end

    add_index :assignment_repos, :github_repo_id, unique: true

    create_table :group_assignment_repos do |t|
      t.integer :github_repo_id, null: false

      t.timestamps null: false
    end

    add_index :group_assignment_repos, :github_repo_id, unique: true
  end
end

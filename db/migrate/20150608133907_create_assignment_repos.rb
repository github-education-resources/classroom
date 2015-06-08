class CreateAssignmentRepos < ActiveRecord::Migration
  def change
    create_table :individual_assignment_repos do |t|
      t.integer :github_repo_id, null: false
    end

    add_index :individual_assignment_repos, :github_repo_id, unique: true

    create_table :group_assignment_repos do |t|
      t.integer :github_repo_id, null: false
    end

    add_index :group_assignment_repos, :github_repo_id, unique: true
  end
end

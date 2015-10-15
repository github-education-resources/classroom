class ModifyRepoAccessForCollabs < ActiveRecord::Migration
  def change
    add_column :assignment_repos, :user_id, :integer
    add_index :assignment_repos, :user_id

    change_column :repo_accesses, :github_team_id, :integer, null: true
  end
end

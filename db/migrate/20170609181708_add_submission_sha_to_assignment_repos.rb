class AddSubmissionShaToAssignmentRepos < ActiveRecord::Migration[5.0]
  def change
    add_column :assignment_repos, :submission_sha, :string
    add_column :group_assignment_repos, :submission_sha, :string
  end
end

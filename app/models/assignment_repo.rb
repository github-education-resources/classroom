class AssignmentRepo < ActiveRecord::Base
  has_one    :repo_access
  belongs_to :assignment

  validates_presence_of   :github_repo_id
  validates_uniqueness_of :github_repo_id

  def create_github_repo(org_owner, organization, repo_name)
    repo = GitHubRepository.create_repository_for_team(assignment_owner,
                                                       organization,
                                                       self.repo_access.github_team_id,
                                                       new_repo_name)

    self.github_repo_id = repo.id
  end
end

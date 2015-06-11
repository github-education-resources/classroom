class AssignmentRepo < ActiveRecord::Base
  belongs_to :assignment
  belongs_to :repo_access

  validates :github_repo_id, presence:   true
  validates :github_repo_id, uniqueness: true

  def create_github_repo(org_owner, organization, repo_name)
    repo = GitHubRepository.create_repository_for_team(org_owner,
                                                       organization,
                                                       self.repo_access.github_team_id,
                                                       repo_name)

    self.github_repo_id = repo.id
  end
end

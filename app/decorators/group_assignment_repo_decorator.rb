class GroupAssignmentRepoDecorator < Draper::Decorator
  delegate_all

  def github_team_url
    "https://github.com/orgs/#{github_team.organization.login}/teams/#{github_team.slug}"
  end

  def github_repo_url
    github_repository.html_url
  end

  def team_name
    github_team.name
  end

  private

  def github_repository
    @github_repository ||= GitHubRepository.new(creator.github_client, github_repo_id).repository
  end

  def github_team
    @github_team ||= GitHubTeam.new(creator.github_client, github_team_id).team
  end
end

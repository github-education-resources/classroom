class GroupAssignmentRepoDecorator < Draper::Decorator
  delegate_all

  def full_name
    github_repository.full_name
  rescue GitHub::NotFound
    "Deleted repository"
  end

  def github_team_url
    "https://github.com/orgs/#{github_team.organization.login}/teams/#{github_team.slug}"
  rescue GitHub::NotFound
    "#"
  end

  def github_repo_url
    github_repository.html_url
  rescue GitHub::NotFound
    "#"
  end

  def team_name
    github_team.name
  rescue GitHub::NotFound
    "Deleted team"
  end

  private

  def github_repository
    @github_repository ||= GitHubRepository.new(creator.github_client, github_repo_id).repository
  end

  def github_team
    @github_team ||= GitHubTeam.new(creator.github_client, github_team_id).team
  end
end

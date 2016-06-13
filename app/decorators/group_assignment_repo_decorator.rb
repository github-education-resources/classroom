# frozen_string_literal: true
class GroupAssignmentRepoDecorator < Draper::Decorator
  delegate_all

  def disabled?
    !github_repository.on_github? || !github_team.on_github?
  end

  def full_name
    github_repository.full_name
  end

  def github_team_url
    github_team.html_url
  end

  def github_repo_url
    github_repository.html_url
  end

  def team_name
    github_team.name
  end

  private

  def github_repository
    @github_repository ||= GitHubRepository.new(creator.github_client, github_repo_id)
  end

  def github_team
    @github_team ||= group.github_team
  end
end

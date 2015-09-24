class GroupAssignmentDecorator < Draper::Decorator
  delegate_all

  def full_name
    return unless starter_code?
    github_repository.full_name
  end

  private

  def github_repository
    @github_repository ||= GitHubRepository.new(creator.github_client, starter_code_repo_id).repository
  rescue GitHub::NotFound
    NullGitHubRepository.new
  end
end

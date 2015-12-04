class AssignmentDecorator < Draper::Decorator
  delegate_all

  def starter_code_github_url
    return unless starter_code?
    github_repository.html_url
  end

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

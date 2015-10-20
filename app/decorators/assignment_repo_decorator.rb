class AssignmentRepoDecorator < Draper::Decorator
  delegate_all

  def avatar_url(size)
    "https://avatars.githubusercontent.com/u/#{assignment_repo_user.uid}?v=3&size=#{size}"
  end

  def full_name
    github_repository.full_name
  end

  def github_url
    github_repository.html_url
  end

  def disabled?
    github_repository.null? || student.null?
  end

  def student_login
    student.login
  end

  def student_name
    student.name
  end

  private

  def github_repository
    @github_repository ||= GitHubRepository.new(creator.github_client, github_repo_id).repository
  rescue GitHub::NotFound
    NullGitHubRepository.new
  end

  def student
    @student ||= GitHubUser.new(creator.github_client, assignment_repo_user.uid).user
  rescue GitHub::NotFound
    NullGitHubUser.new
  end

  def assignment_repo_user
    if repo_access
      @assignment_repo_user = repo_access.user
    else
      @assignment_repo_user = user
    end
  end
end

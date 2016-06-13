# frozen_string_literal: true
class AssignmentRepoDecorator < Draper::Decorator
  delegate_all

  def avatar_url(size)
    "https://avatars.githubusercontent.com/u/#{assignment_repo.user.uid}?v=3&size=#{size}"
  end

  def full_name
    github_repository.full_name
  end

  def github_url
    github_repository.html_url
  end

  def disabled?
    !github_repository.on_github? || !student.on_github?
  end

  def student_login
    student.login
  end

  def student_name
    student.name
  end

  private

  def github_repository
    @github_repository ||= GitHubRepository.new(creator.github_client, github_repo_id)
  end

  def student
    @student ||= GitHubUser.new(creator.github_client, assignment_repo.user.uid)
  end
end

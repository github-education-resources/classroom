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
    github_repository.null? || student.null?
  end

  def student_login
    student.login
  end

  def student_name
    student.name
  end

  def student_identifier
    student_identifier = assignment_repo.user.identifier(assignment_repo.assignment.student_identifier_type)
    return '' unless student_identifier.present?
    student_identifier.value
  end

  private

  def github_repository
    @github_repository ||= GitHubRepository.new(creator.github_client, github_repo_id).repository
  rescue GitHub::NotFound
    NullGitHubRepository.new
  end

  def student
    @student ||= GitHubUser.new(creator.github_client, assignment_repo.user.uid).user
  rescue GitHub::NotFound
    NullGitHubUser.new
  end
end

# frozen_string_literal: true

class SharedAssignmentRepoView < ViewModel
  include ActionView::Helpers::TextHelper
  attr_reader :assignment_repo

  def repo_url
    @repo_url ||= github_repo.html_url
  end

  def github_repo
    assignment_repo.github_repository
  end

  def number_of_commits
    @branch ||= github_repo.default_branch
    @number_of_commits ||= github_repo.commits(@branch).length
  end

  def commit_text
    pluralize(number_of_commits, 'commit')
  end

  def disabled_class
    assignment_repo.disabled? ? 'disabled' : ''
  end

  def avatar_for(student, size)
    student.github_avatar_url(size)
  end
end

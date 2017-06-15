# frozen_string_literal: true

class SharedAssignmentRepoView < ViewModel
  include ActionView::Helpers::TextHelper
  attr_reader :assignment_repo

  delegate :github_repository, to: :assignment_repo

  def repo_url
    github_repository.html_url
  end

  def number_of_commits
    branch = github_repository.default_branch
    github_repository.commits(branch).length
  end

  def commit_text
    pluralize(number_of_commits, 'commit')
  end

  def disabled_class
    assignment_repo.disabled? ? 'disabled' : ''
  end

  def avatar_url_for(github_user, size)
    github_user.github_avatar_url(size)
  end

  def user_url_for(github_user)
    github_user.html_url
  end

  def login_for(github_user)
    github_user.login
  end
end

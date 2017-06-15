# frozen_string_literal: true

class SharedAssignmentRepoView < ViewModel
  include ActionView::Helpers::TextHelper
  attr_reader :assignment_repo

  def repo_url
    github_repo.html_url
  end

  def github_repo
    assignment_repo.github_repository
  end

  def number_of_commits
    branch = github_repo.default_branch
    github_repo.commits(branch).length
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

# frozen_string_literal: true

class SharedAssignmentRepoView < ViewModel
  include ActionView::Helpers::TextHelper
  attr_reader :assignment_repo

  delegate :github_repository, to: :assignment_repo

  def disabled?
    return @disabled if defined?(@disabled)
    @disabled = assignment_repo.disabled?
  end

  def github_repo_url
    github_repository.html_url
  end

  def number_of_github_commits
    return 0 if disabled?
    github_repository.number_of_commits
  end

  def commit_text
    pluralize(number_of_github_commits, "commit")
  rescue GitHub::Error
    "Failed to fetch commit data"
  end

  def github_commits_url
    return "" if disabled?

    branch = github_repository.default_branch
    github_repository.commits_url(branch)
  rescue GitHub::Error
    ""
  end

  def disabled_class
    disabled? ? "disabled" : ""
  end

  def github_avatar_url_for(github_user, size)
    github_user.github_avatar_url(size)
  end

  def github_user_url_for(github_user)
    github_user.html_url
  end

  def github_login_for(github_user)
    github_user.login
  end

  def submission_succeeded?
    return false if disabled?
    submission_passed? && assignment_repo.submission_sha.present?
  end

  def submission_passed?
    assignment_repo.assignment.deadline&.passed?
  end

  def submission_url
    return if disabled? || !submission_succeeded?
    assignment_repo.github_repository.tree_url_for_sha(assignment_repo.submission_sha)
  end

  def repository_text
    disabled? ? "Repository not found" : "View repository"
  end
end

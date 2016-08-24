# frozen_string_literal: true
class GitHubRepositoriesController < ApplicationController
  before_action :ensure_explicit_assignment_submission_is_enabled

  def latest_release
    render partial: 'shared/github_repository/latest_release',
           locals: { latest_release: github_repo_latest_release }
  end

  private

  def github_repo_latest_release
    github_repo.releases(headers: GitHub::APIHeaders.no_cache_no_store)
               .select { |release| !(release.prerelease || release.draft) }.first
  end
end

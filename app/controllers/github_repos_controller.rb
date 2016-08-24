# frozen_string_literal: true
class GitHubReposController < ApplicationController
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

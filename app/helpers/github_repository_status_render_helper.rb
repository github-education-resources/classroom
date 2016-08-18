# frozen_string_literal: true
module GitHubRepositoryStatusRenderHelper
  def render_github_repo_status(github_repo)
    latest_push = github_repo.latest_push_event

    render partial: 'shared/github_repository/status',
           locals: {
             latest_push: latest_push,
             link_to_latest_push: html_link_to_latest_push(github_repo, latest_push),
             build_status: build_status_of_latest_push(github_repo, latest_push)
           }
  end

  def html_link_to_latest_push(github_repo, latest_push)
    return nil unless latest_push.present?
    "#{github_repo.html_url}/tree/#{latest_push.payload.ref}"
  end

  def build_status_of_latest_push(github_repo, latest_push)
    return nil unless latest_push.present?
    github_repo.commit_status(latest_push.payload.ref,
                              headers: GitHub::APIHeaders.no_cache_no_store)
  end

  def tooltip_text_for_build_status(status)
    case status
    when 'pending'
      'Build is still in progress'
    when 'success'
      'Build completed successfully'
    when 'failure'
      'Build failed'
    end
  end
end

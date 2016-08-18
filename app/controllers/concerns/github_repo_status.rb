# frozen_string_literal: true
module GitHubRepoStatus
  extend ActiveSupport::Concern

  def ref_html_url(push_event)
    return nil unless push_event.present?
    github_repo.html_url_to(ref: push_event.payload.ref)
  end

  def build_status(push_event)
    return nil unless push_event.present?
    github_repo.commit_status(push_event.payload.ref,
                              headers: GitHub::APIHeaders.no_cache_no_store)
  end
end

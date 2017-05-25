# frozen_string_literal: true

module GitHubRepoStatus
  extend ActiveSupport::Concern

  included do
    before_action :set_assignment_repo, :set_github_repo, only: [:repo_status]
  end

  def repo_status
    push_event = @github_repo.latest_push_event

    render partial: 'shared/github_repository/status',
           locals: {
             push_event: push_event,
             ref_html_url: ref_html_url(push_event),
             build_status: build_status(push_event)
           }
  end

  def ref_html_url(push_event)
    return nil if push_event.blank?
    @github_repo.html_url_to(ref: push_event.payload.ref)
  end

  def build_status(push_event)
    return nil if push_event.blank?
    @github_repo.commit_status(push_event.payload.ref,
                               headers: GitHub::APIHeaders.no_cache_no_store)
  end

  private

  def set_assignment_repo
    @assignment_repo = controller_name.classify.safe_constantize.find_by!(id: params[:id])
  end

  def set_github_repo
    @github_repo ||= @assignment_repo.github_repository
  end
end

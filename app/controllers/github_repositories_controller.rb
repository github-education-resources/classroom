# frozen_string_literal: true
class GitHubRepositoriesController < ApplicationController
  include GitHubRepoStatus

  before_action :ensure_teacher_dashboard_is_enabled, only: [:repo_status]

  def repo_status
    push_event = github_repo.latest_push_event

    render partial: 'shared/github_repository/status',
           locals: {
             push_event: push_event,
             ref_html_url: ref_html_url(push_event),
             build_status: build_status(push_event)
           }
  end
end

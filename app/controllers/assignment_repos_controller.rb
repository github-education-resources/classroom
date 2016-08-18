# frozen_string_literal: true
class AssignmentReposController < ApplicationController
  include OrganizationAuthorization
  include GitHubRepoStatus

  before_action :set_assignment_repo

  def github_repo_status
    push_event = github_repo.latest_push_event

    render partial: 'shared/github_repository/status',
           locals: {
             push_event: push_event,
             ref_html_url: ref_html_url(push_event),
             build_status: build_status(push_event)
           }
  end

  private

  def set_assignment_repo
    assignment = @organization.assignments.includes(:assignment_invitation).find_by!(slug: params[:assignment_id])
    @assignment_repo = AssignmentRepo.find_by!(assignment: assignment, id: params[:id])
  end

  def github_repo
    @github_repo ||= @assignment_repo.github_repository
  end
end

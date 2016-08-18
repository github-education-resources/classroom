# frozen_string_literal: true
class GroupAssignmentReposController < ApplicationController
  include OrganizationAuthorization
  include GitHubRepoStatus

  before_action :set_group_assignment_repo

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

  def set_group_assignment_repo
    group_assignment = @organization
                       .group_assignments
                       .includes(:group_assignment_invitation)
                       .find_by!(slug: params[:group_assignment_id])
    @group_assignment_repo = GroupAssignmentRepo.find_by!(group_assignment: group_assignment, id: params[:id])
  end

  def github_repo
    @github_repo ||= @group_assignment_repo.github_repository
  end
end

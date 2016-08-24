# frozen_string_literal: true
class GroupAssignmentReposController < ApplicationController
  include OrganizationAuthorization

  before_action :set_group_assignment_repo

  def github_repo_latest_release
    render partial: 'shared/github_repository/latest_release',
           locals: { latest_release: github_repo.releases.first }
  end

  private

  def set_group_assignment_repo
    group_assignment = @organization
                       .group_assignments
                       .includes(:group_assignment_invitation)
                       .find_by!(slug: params[:group_assignment_id])
    @group_assignment_repo = GroupAssignmentRepo.find_by(group_assignment: group_assignment, id: params[:id])
    not_found unless @group_assignment_repo.present?
  end

  def github_repo
    @github_repo ||= @group_assignment_repo.github_repository
  end
end

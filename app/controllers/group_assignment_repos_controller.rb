# frozen_string_literal: true

class GroupAssignmentReposController < ApplicationController
  include OrganizationAuthorization
  include GitHubRepoStatus

  layout false

  def show
    @group_assignment_repo = GroupAssignmentRepo.includes(:group).includes(:group_assignment).find_by!(id: params[:id])
  end
end

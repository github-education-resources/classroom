# frozen_string_literal: true

class GroupAssignmentReposController < ApplicationController
  include OrganizationAuthorization

  layout false

  def show
    @group_assignment_repo = GroupAssignmentRepo.includes(:group).find_by!(id: params[:id])
  end
end

# frozen_string_literal: true

class AssignmentReposController < ApplicationController
  include OrganizationAuthorization

  layout false

  def show
    @assignment_repo = AssignmentRepo.includes(:user).find_by!(id: params[:id])
  end
end

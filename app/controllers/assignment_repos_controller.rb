# frozen_string_literal: true
class AssignmentReposController < ApplicationController
  include OrganizationAuthorization

  before_action :set_assignment_repo

  def github_repo_latest_release
    render partial: 'shared/github_repository/latest_release',
           locals: { latest_release: github_repo.releases.first }
  end

  private

  def set_assignment_repo
    assignment = @organization.assignments.includes(:assignment_invitation).find_by!(slug: params[:assignment_id])
    @assignment_repo = AssignmentRepo.find_by(assignment: assignment, id: params[:id])
    not_found unless @assignment_repo.present?
  end

  def github_repo
    @github_repo ||= @assignment_repo.github_repository
  end
end

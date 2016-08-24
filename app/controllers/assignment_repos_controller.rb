# frozen_string_literal: true
class AssignmentReposController < GitHubRepositoriesController
  include OrganizationAuthorization

  before_action :set_assignment_repo

  private

  def set_assignment_repo
    assignment = @organization.assignments.find_by(slug: params[:assignment_id])
    @assignment_repo = AssignmentRepo.find_by(assignment: assignment, id: params[:id])
    not_found unless @assignment_repo.present?
  end

  def github_repo
    @github_repo ||= @assignment_repo.github_repository
  end
end

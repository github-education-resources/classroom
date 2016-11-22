# frozen_string_literal: true
class GroupAssignmentReposController < GitHubRepositoriesController
  include OrganizationAuthorization

  before_action :set_group_assignment_repo

  private

  def set_group_assignment_repo
    group_assignment = @organization
                       .group_assignments
                       .find_by(slug: params[:group_assignment_id])
    @group_assignment_repo = GroupAssignmentRepo.find_by(group_assignment: group_assignment, id: params[:id])
    not_found unless @group_assignment_repo.present?
  end

  def github_repo
    @github_repo ||= @group_assignment_repo.github_repository
  end
end

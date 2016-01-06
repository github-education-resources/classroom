class GroupAssignmentReposController < ApplicationController
  include OrganizationAuthorization

  def recreate_repo
    if group_assignment_repo.update_attributes(github_repo_id: nil)
      flash[:success] = 'Repository was successfully recreated'
    else
      flash[:error] = 'Repository failed to be recreated'
    end

    redirect_to organization_group_assignment_path(organization, group_assignment)
  end

  private

  def group_assignment
    @group_assignment ||= group_assignment_repo.group_assignment
  end
  helper_method :group_assignment

  def group_assignment_repo
    @group_assignment_repo ||= GroupAssignmentRepo.find(params[:group_assignment_repo_id])
  end
  helper_method :group_assignment_repo

  def organization
    @organization ||= group_assignment_repo.organization
  end
  helper_method :organization
end

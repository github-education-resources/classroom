class AssignmentReposController < ApplicationController
  include OrganizationAuthorization

  def recreate_repo
    if assignment_repo.update_attributes(github_repo_id: nil)
      flash[:success] = 'Repository was successfully recreated'
    else
      flash[:error] = 'Repository failed to be recreated'
    end

    redirect_to organization_assignment_path(organization, assignment)
  end

  private

  def assignment
    @assignment ||= assignment_repo.assignment
  end
  helper_method :assignment

  def assignment_repo
    @assignment_repo ||= AssignmentRepo.find(params[:assignment_repo_id])
  end
  helper_method :assignment_repo

  def organization
    @organization ||= assignment_repo.organization
  end
  helper_method :organization
end

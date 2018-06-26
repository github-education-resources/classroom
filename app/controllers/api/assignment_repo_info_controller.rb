# frozen_string_literal: true
class API::AssignmentRepoInfoController < ApplicationController
    include Rails::Pagination
    include OrganizationAuthorization

    before_action :set_assignment

    def repos
      assignment_repos = AssignmentRepo.where(assignment: @assignment)
      assignment_repo_params = assignment_repos.map{ |a| {
          id: a.id,
          username: a.user.github_user.login, 
          repo_url: a.github_repository.html_url
      }}
      paginate json: assignment_repo_params
    end

    def info
      render json: {
        name: @assignment.title,
        type: "individual",
      }
    end

    private

    def set_assignment
      @assignment = @organization.assignments.includes(:assignment_invitation).find_by!(slug: params[:id])
    end
end

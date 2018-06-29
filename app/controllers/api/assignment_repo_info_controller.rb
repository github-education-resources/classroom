# frozen_string_literal: true
class API::AssignmentRepoInfoController < ApplicationController
    include Rails::Pagination
    include OrganizationAuthorization

    before_action :set_assignment
    before_action :add_security_headers

    def repos
      assignment_repos = AssignmentRepo.where(assignment: @assignment)
      assignment_repo_params = assignment_repos.map{ |a| {
          id: a.id,
          username: a.user.github_user.login, 
          repoUrl: a.github_repository.html_url,
      }}
      paginate json: assignment_repo_params
    end

    def info
      render json: {
        name: @assignment.title,
        type: "individual",
        accessToken: true_user.token,
      }
    end

    private

    def set_assignment
      @assignment = @organization.assignments.includes(:assignment_invitation).find_by!(slug: params[:id])
    end

    def add_security_headers
      response.headers['Access-Control-Allow-Origin'] = '*'
      response.headers['Access-Control-Allow-Methods'] = 'GET'
      response.headers['Access-Control-Allow-Headers'] = '*'
      response.headers['Access-Control-Expose-Headers'] = 'Total, Link, Per-Page'
    end
end

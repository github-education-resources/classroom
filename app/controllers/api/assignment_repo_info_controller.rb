# frozen_string_literal: true
class API::AssignmentRepoInfoController < ApplicationController
    include Rails::Pagination
    include ActionController::Serialization
    include OrganizationAuthorization

    before_action :set_assignment
    before_action :add_security_headers

    def repos
      if type == :individual
        individual_repos
      elsif type == :group
        group_repos
      end
      render json: @assignment_repos
    end

    def info
      render json: {
        name: @assignment.title,
        type: type.to_s,
        accessToken: true_user.token,
      }
    end

    private

    def group_repos
      @assignment_repos = GroupAssignmentRepo.where(group_assignment: @assignment).page(params[:page])
    end

    def individual_repos
      @assignment_repos = AssignmentRepo.where(assignment: @assignment).page(params[:page])
    end

    def set_assignment
      # binding.pry
      if type == :individual
        @assignment = @organization.assignments.includes(:assignment_invitation).find_by!(slug: params[:assignment_id])
      elsif type == :group
        @assignment = @organization.group_assignments.includes(:group_assignment_invitation).find_by!(slug: params[:group_assignment_id])
      end
    end

    def type
      params[:type]
    end

    def add_security_headers
      response.headers['Access-Control-Allow-Origin'] = '*'
      response.headers['Access-Control-Allow-Methods'] = 'GET'
      response.headers['Access-Control-Allow-Headers'] = '*'
      response.headers['Access-Control-Expose-Headers'] = 'Total, Link, Per-Page'
    end
end

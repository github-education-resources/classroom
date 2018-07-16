# frozen_string_literal: true
class API::AssignmentRepoInfoController < API::ApplicationController
    include ActionController::Serialization
    include OrganizationAuthorization

    before_action :set_assignment
    before_action :add_security_headers

    def repos
      if type == :individual
        paginate json: individual_repos
      else
        paginate json: group_repos
      end
    end

    def info
      render json: {
        name: @assignment.title,
        type: type.to_s,
      }
    end

    private

    def group_repos
      GroupAssignmentRepo.where(group_assignment: @assignment)
    end

    def individual_repos
      AssignmentRepo.where(assignment: @assignment)
    end

    def set_assignment
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

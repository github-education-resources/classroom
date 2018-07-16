# frozen_string_literal: true
class API::AssignmentsController < API::ApplicationController
  include Rails::Pagination
  include ActionController::Serialization
  include OrganizationAuthorization

  before_action :add_security_headers

  def index
    if type == "individual"
      paginate json: @organization.assignments
    elsif type == "group"
      paginate json: @organization.group_assignments
    end
  end

  private

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

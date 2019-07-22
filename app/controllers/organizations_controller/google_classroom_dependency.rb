# frozen_string_literal: true

require "google/apis/classroom_v1"

class OrganizationsController < Orgs::Controller
  before_action :ensure_google_classroom_roster_import_is_enabled, only: %i[
    select_google_classroom
    search_google_classroom
  ]
  before_action :authorize_google_classroom, only: %i[
    select_google_classroom
    search_google_classroom
  ]
  before_action :ensure_no_lti_configuration, only: %i[
    select_google_classroom
  ]
  before_action :google_classroom_ensure_no_roster, only: %i[
    select_google_classroom
  ]

  def select_google_classroom
    @google_classroom_courses = fetch_all_google_classrooms
  end

  def search_google_classroom
    courses_found = fetch_all_google_classrooms do |course|
      course.name.downcase.include? params[:query].downcase
    end

    respond_to do |format|
      format.html do
        render partial: "google_classroom_collection",
               locals: { courses: courses_found }
      end
    end
  end

  def unlink_google_classroom
    current_organization.update!(google_course_id: nil)
    flash[:success] = "Removed link to Google Classroom. No students were removed from your roster."

    redirect_to roster_path(current_organization)
  end

  private

  def current_organization_google_course_name
    return unless current_organization.google_course_id
    course = @google_classroom_service.get_course(current_organization.google_course_id)
    course&.name
  rescue Google::Apis::Error
    nil
  end

  def fetch_all_google_classrooms
    next_page = nil
    courses = []
    loop do
      response = @google_classroom_service.list_courses(page_size: 20, page_token: next_page)
      courses.push(*response.courses)

      next_page = response.next_page_token
      break unless next_page
    end

    courses
  end

  def google_classroom_ensure_no_roster
    return unless current_organization.roster
    redirect_to edit_organization_path(current_organization),
      alert: "We are unable to link your classroom organization to Google Classroom "\
        "because a roster already exists. Please delete your current roster and try again."
  end

  def ensure_no_lti_configuration
    return unless current_organization.lti_configuration
    redirect_to edit_organization_path(current_organization),
      alert: "A LMS configuration already exists. Please remove configuration before creating a new one."
  end
end
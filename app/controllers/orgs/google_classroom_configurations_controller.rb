# frozen_string_literal: true

require "google/apis/classroom_v1"

module Orgs
  class GoogleClassroomConfigurationsController < Orgs::Controller
    before_action :authorize_google_classroom, only: %i[create search index]
    before_action :ensure_no_lti_configuration, only: %i[create index]
    before_action :ensure_no_roster, only: %i[create index]

    def create
      current_organization.update(google_course_id: params[:course_id])

      GitHubClassroom.statsd.increment("google_classroom.create")

      flash[:success] = "Google Classroom integration was succesfully configured."
      redirect_to new_roster_path(current_organization)
    end

    def search
      courses_found = fetch_all_google_classrooms.select do |course|
        course.name.downcase.include? params[:query].downcase
      end

      respond_to do |format|
        format.html do
          render partial: "google_classroom_collection",
                 locals: { courses: courses_found }
        end
      end
    end

    def index
      @google_classroom_courses = fetch_all_google_classrooms
    rescue Google::Apis::AuthorizationError, Signet::AuthorizationError
      google_classroom_client = GitHubClassroom.google_classroom_client
      login_hint = current_user.github_user.login
      redirect_to google_classroom_client.get_authorization_url(login_hint: login_hint, request: request)
    rescue Google::Apis::ServerError, Google::Apis::ClientError
      flash[:error] = "Failed to fetch classroom from Google Classroom. Please try again."
      redirect_to organization_path(current_organization)
    end

    def destroy
      current_organization.update!(google_course_id: nil)
      GitHubClassroom.statsd.increment("google_classroom.destroy")
      flash[:success] = "Removed link to Google Classroom. No students were removed from your roster."

      redirect_to organization_path(current_organization)
    end

    private

    def ensure_no_lti_configuration
      return unless current_organization.lti_configuration
      lms_name = current_organization.lti_configuration.lms_name(default_name: "a learning management system")
      redirect_to edit_organization_path(current_organization),
        alert: "This classroom is already connected to #{lms_name}. Please disconnect from #{lms_name} before "\
        "connecting to Google Classroom."
    end

    def ensure_no_roster
      return unless current_organization.roster
      redirect_to edit_organization_path(current_organization),
        alert: "We are unable to link your classroom organization to Google Classroom "\
          "because a roster already exists. Please delete your current roster and try again."
    end

    def fetch_all_google_classrooms
      next_page = nil
      courses = []
      loop do
        response = @google_classroom_service.list_courses(course_states: "ACTIVE", teacher_id: "me", page_size: 20, page_token: next_page)

        courses.push(*response.courses)

        next_page = response.next_page_token
        break unless next_page
      end

      courses
    end
  end
end

# frozen_string_literal: true

require "google/apis/classroom_v1"

module Orgs
  class GoogleClassroomConfigurationsController < Orgs::Controller
    before_action :ensure_google_classroom_roster_import_is_enabled, only: %i[create search index]
    before_action :authorize_google_classroom, only: %i[create search index]

    def create
      current_organization.update(google_course_id: params[:course_id])

      flash[:success] = "Google Classroom integration was succesfully configured."
      redirect_to new_roster_path(current_organization)
    end

    def search
      courses_found = fetch_all_google_classrooms.select do |course|
        course.name.downcase.include? params[:query].downcase
      end

      respond_to do |format|
        format.html do
          render partial: "orgs/rosters/google_classroom_collection",
                locals: { courses: courses_found }
        end
      end
    end

    def index
      @google_classroom_courses = fetch_all_google_classrooms
    end

    def destroy
      current_organization.update!(google_course_id: nil)
      flash[:success] = "Removed link to Google Classroom. No students were removed from your roster."

      redirect_to roster_path(current_organization)
    end

    private

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
  end
end

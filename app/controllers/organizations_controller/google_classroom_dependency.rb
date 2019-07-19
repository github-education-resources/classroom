# frozen_string_literal: true

require "google/apis/classroom_v1"

class OrganizationsController < Orgs::Controller
  def select_google_classroom
    @google_classroom_courses = fetch_all_google_classrooms
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
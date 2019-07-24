# frozen_string_literal: true

require "rails_helper"
require "google/apis/classroom_v1"

RSpec.describe Roster, type: :model do
  before do
    GoogleAPI = Google::Apis::ClassroomV1
  end

  describe "#initialize" do
    it "succeeds" do
      google_classroom_service = Google::Apis::ClassroomV1::ClassroomService.new
      course = GoogleClassroomCourse.new(google_classroom_service, "5555")
      expect(course).to_not be_nil
    end
  end

  describe "#student", :vcr do
    it "succeeds" do
      client = Signet::OAuth2::Client.new
      allow_any_instance_of(ApplicationController)
        .to receive(:user_google_classroom_credentials)
        .and_return(client)

      response = GoogleAPI::ListCoursesResponse.new
      allow_any_instance_of(GoogleAPI::ClassroomService)
        .to receive(:list_course_students)
        .and_return(response)

      google_classroom_service = GoogleAPI::ClassroomService.new
      course = GoogleClassroomCourse.new(google_classroom_service, "5555")
      expect(course.students).to eq([])
    end
  end

  describe "#name", :vcr do
    it "suceeds" do
      client = Signet::OAuth2::Client.new
      allow_any_instance_of(ApplicationController)
        .to receive(:user_google_classroom_credentials)
        .and_return(client)

      response = GoogleAPI::Course.new
      allow_any_instance_of(GoogleAPI::ClassroomService)
        .to receive(:get_course)
        .and_return(response)

      google_classroom_service = GoogleAPI::ClassroomService.new
      course = GoogleClassroomCourse.new(google_classroom_service, "5555")

      expect(course.name).to be_nil
    end
  end
end

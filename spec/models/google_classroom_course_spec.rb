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
    before do
      client = Signet::OAuth2::Client.new
      allow_any_instance_of(ApplicationController)
        .to receive(:user_google_classroom_credentials)
        .and_return(client)

      valid_response = GoogleAPI::ListStudentsResponse.new

      student_names = ["Student 1", "Student 2"]
      student_profiles = student_names.map do |name|
        GoogleAPI::UserProfile.new(name: GoogleAPI::Name.new(full_name: name))
      end
      students = student_profiles.map { |prof| GoogleAPI::Student.new(profile: prof) }

      valid_response.students = students
      allow_any_instance_of(GoogleAPI::ClassroomService)
        .to receive(:list_course_students)
        .and_return(valid_response)

      google_classroom_service = GoogleAPI::ClassroomService.new
      @course = GoogleClassroomCourse.new(google_classroom_service, "5555")
    end

    it "has the correct number of students" do
      expect(@course.students.length).to eq(2)
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

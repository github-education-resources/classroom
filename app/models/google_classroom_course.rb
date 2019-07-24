# frozen_string_literal: true

class GoogleClassroomCourse
  attr_accessor :name, :students
  def initialize(google_classroom_service, course_id)
    @google_classroom_service = google_classroom_service
    @course_id = course_id
  end

  def name
    course = @google_classroom_service.get_course(@course_id)
    course&.name
  end

  def students
    response = @google_classroom_service.list_course_students(@course_id)
    return [] unless defined? response.students && respoonse.students.present?
    response.students ||= []
    response.students
  end
end

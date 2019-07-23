# frozen_string_literal: true

class GoogleClassroomCourse
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
    response.students ||= []
    response.students
  rescue Google::Apis::AuthorizationError
    google_classroom_client = GitHubClassroom.google_classroom_client
    login_hint = current_user.github_user.login
    redirect_to google_classroom_client.get_authorization_url(login_hint: login_hint, request: request)
    nil
  rescue Google::Apis::ServerError, Google::Apis::ClientError
    flash[:error] = "Failed to fetch students from Google Classroom. Please try again later."
    redirect_to organization_path(current_organization)
    nil
  end
end

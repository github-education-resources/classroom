# frozen_string_literal: true

class ApplicationController
  def authorize_google_classroom
    google_classroom_client = GitHubClassroom.google_classroom_client
    unless user_google_classroom_credentials
      login_hint = current_user.github_user.login
      redirect_to google_classroom_client.get_authorization_url(login_hint: login_hint, request: request)
    end

    @google_classroom_service = Google::Apis::ClassroomV1::ClassroomService.new
    @google_classroom_service.client_options.application_name = "GitHub Classroom"
    @google_classroom_service.authorization = user_google_classroom_credentials
  end

  private

  def user_google_classroom_credentials
    google_classroom_client = GitHubClassroom.google_classroom_client
    user_id = current_user.uid.to_s

    google_classroom_client.get_credentials(user_id, request)
  rescue Signet::AuthorizationError
    # Will reauthorize upstream
    nil
  end
end
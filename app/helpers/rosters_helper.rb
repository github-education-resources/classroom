# frozen_string_literal: true

require 'google/apis/classroom_v1'

module RostersHelper
  def google_classroom_courses
    google_classroom_service.list_courses(page_size: 10).courses rescue nil
  end

  def google_classroom_service
    google_classroom_client = GitHubClassroom.google_classroom_client

    if user_google_classroom_credentials.nil?
      redirect_to google_classroom_client.get_authorization_url(login_hint: current_user.github_user.login, request: request)
    end

    google_classroom_service = Google::Apis::ClassroomV1::ClassroomService.new
    google_classroom_service.client_options.application_name = "GitHub Classroom"
    google_classroom_service.authorization = user_google_classroom_credentials

    google_classroom_service
  end

  def user_google_classroom_credentials
    # DEBUG
    # token_store = Google::Auth::Stores::RedisTokenStore.new(redis: GitHubClassroom.redis)
    # token_store.delete(user_id)

    google_classroom_client = GitHubClassroom.google_classroom_client
    user_id = current_user.github_user.login

    google_classroom_client.get_credentials(user_id, request) rescue nil
  end
end

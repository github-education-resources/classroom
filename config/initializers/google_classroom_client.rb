# frozen_string_literal: true

require "googleauth"
require "googleauth/stores/redis_token_store"
require "google/api_client/client_secrets"

module GitHubClassroom
  def self.google_classroom_client
    scope = [
      Google::Apis::ClassroomV1::AUTH_CLASSROOM_COURSES_READONLY,
      Google::Apis::ClassroomV1::AUTH_CLASSROOM_ROSTERS_READONLY
    ]

    client_id = Rails.application.secrets.google_client_id
    client_secret = Rails.application.secrets.google_client_secret
    client = Google::Auth::ClientId.new(client_id, client_secret)

    token_store = Google::Auth::Stores::RedisTokenStore.new(redis: GitHubClassroom.redis)
    Google::Auth::WebUserAuthorizer.new(client, scope, token_store, "/google_classroom/oauth2_callback")
  end
end

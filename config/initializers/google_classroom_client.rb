# frozen_string_literal: true

require 'googleauth'
require 'googleauth/stores/redis_token_store'
require 'google/api_client/client_secrets'

module GitHubClassroom
  def self.google_classroom_client(options = {})
    scope = [Google::Apis::ClassroomV1::AUTH_CLASSROOM_COURSES_READONLY, Google::Apis::ClassroomV1::AUTH_CLASSROOM_ROSTERS_READONLY]
    client_id = Google::Auth::ClientId.new("421659922438-rri2uuv71jj3aaeh2bkfj3906npmv5n2.apps.googleusercontent.com", "toXhuU9fg7-d2K45Xb_j3Jk5")
    token_store = Google::Auth::Stores::RedisTokenStore.new(redis: GitHubClassroom.redis)

    Google::Auth::WebUserAuthorizer.new(client_id, scope, token_store, '/google_classroom/oauth2_callback')
  end
end

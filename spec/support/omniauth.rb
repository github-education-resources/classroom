# frozen_string_literal: true

OmniAuth.config.test_mode = true

VCR.use_cassette "auth_user" do
  token = ENV["TEST_CLASSROOM_OWNER_GITHUB_TOKEN"] ||= "some-token"
  user = Octokit::Client.new(access_token: token).user

  OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
    "provider" => "github",
    "uid"      => user.id.to_s,

    "extra" => { "raw_info" => { "site_admin" => false } },

    "credentials" => { "token" => token }
  )

  OmniAuth.config.mock_auth[:lti] = OmniAuth::AuthHash.new(
    provider: "lti",
    uid: "mock_lti_uid",

    extra: {
      raw_info: {
        oauth_nonce: "mock_nonce",
        oauth_timestamp: DateTime.now.to_i.to_s
      }
    },

    info: {
      name: "mock_name",
      user_id: "mock_lti_uid",
      email: "mock_email",
      first_name: "mock_first_name",
      last_name: "mock_last_name",
      image: "mock_image_url"
    },

    credentials: {
      token: "mock_token",
      secret: "mock_secret"
    }
  )
end

module AuthenticationHelper
  def sign_in_as(user)
    session[:user_id] = user.id
  end

  def sign_out
    session[:user_id] = nil
  end
end

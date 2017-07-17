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
end

module AuthenticationHelper
  def sign_in_as(user)
    session[:user_id] = user.id
  end

  def sign_out
    session[:user_id] = nil
  end
end

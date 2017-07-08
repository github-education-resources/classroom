# frozen_string_literal: true

OmniAuth.config.test_mode = true

# Public: Set the OmniAuth mock auth back to it's default
# state between tests.
#
# This is used in `before_setup` in the test/test_helper.rb
# file.
#
# Returns the OmniAuth::AuthHash.
def reset_omniauth
  VCR.use_cassette 'auth_user' do
    token = ENV['TEST_CLASSROOM_OWNER_GITHUB_TOKEN'] ||= 'some-token'
    user = Octokit::Client.new(access_token: token).user

    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      'provider' => 'github',
      'uid'      => user.id.to_s,

      'extra' => { 'raw_info' => { 'site_admin' => false } },

      'credentials' => { 'token' => token }
    )
  end
end

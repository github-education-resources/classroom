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
end

# Public: provide the default GitHub Omniauth hash or return a new custom one.
#
# uid        - The Integer unique identifier (defaults to nil).
# site_admin - The Boolean value for site admin status (defaults to false).
# token      - The String GitHub auth token (defaults to nil).
#
# Examples:
#
#   github_omniauth_hash
#   # => {
#     "provider"=>"github",
#     "uid"=>"12435329",
#     "extra"=>{
#       "raw_info"=>{
#         "site_admin"=>false
#         }
#       },
#     "credentials"=> {"token"=>"REDACTED"}
#   }
#
#   github_omniauth_hash(uid: 1, site_admin: true, token: "1234")
#   # => {
#     "provider"=>"github",
#     "uid"=>"1",
#     "extra"=>{
#       "raw_info"=>{
#         "site_admin"=>true
#         }
#       },
#     "credentials"=> {"token"=>"1234"}
#   }
#
# Returns an OmniAuth::AuthHash.
def github_omniauth_hash(uid: nil, site_admin: false, token: nil)
  custom_hash = OmniAuth.config.mock_auth[:github]

  custom_hash.uid                       = uid unless uid.nil?
  custom_hash.extra.raw_info.site_admin = site_admin
  custom_hash.credentials.token         = token unless token.nil?

  custom_hash
end

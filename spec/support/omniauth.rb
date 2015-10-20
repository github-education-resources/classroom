OmniAuth.config.test_mode = true

VCR.use_cassette "auth_user" do
  token = ENV["TEST_CLASSROOM_OWNER_GITHUB_TOKEN"]
  user = Octokit::Client.new(access_token: token).user

  OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
    'provider' => 'github',
    'uid'      => user.id.to_s,

    'info' =>
    {
      'nickname' => user.login,
      'email'    => user.email,
      'name'     => user.name
    },

    'extra' => { 'raw_info' => { 'site_admin' => false } },

    'credentials' => { 'token' => token }
  )
end

OmniAuth.config.test_mode = true

OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new({
  'provider'=> 'github',
  'uid'=> '8675309',

  'info'=>
  {
    'nickname' => 'testuser',
    "email"    => 'testuser@gmail.com',
    'name'     => 'Test User',
  },

  'credentials' => { 'token' => 'some-token' }
})

require 'test_helper'

class AuthHashTest < ActiveSupport::TestCase
  test "it extracts the user's information" do
    auth = AuthHash.new(OmniAuth.config.mock_auth[:github])
    assert_equal 'some-token', auth.user_info[:token]
  end
end

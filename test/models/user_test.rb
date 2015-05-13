require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def setup
    @github_omniauth_hash = OmniAuth.config.mock_auth[:github]
    @user                 = users(:tobias)
  end

  test '#create_from_auth_hash creates a valid user' do
    assert_difference 'User.count', 1 do
      User.create_from_auth_hash(@github_omniauth_hash)
    end
  end

  test '#assign_from_auth_hash updates the users attributes' do
    @user.assign_from_auth_hash(@github_omniauth_hash)
    assert_equal @github_omniauth_hash.credentials.token, @user.token
  end

  test '#find_by_auth_hash finds the correct user' do
    User.create_from_auth_hash(@github_omniauth_hash)
    located_user = User.find_by_auth_hash(@github_omniauth_hash)

    assert_equal User.last, located_user
  end
end

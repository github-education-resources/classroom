require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def setup
    @github_omniauth_hash = OmniAuth.config.mock_auth[:github]
    @user                 = users(:jim)
  end

  context 'validations' do
    context 'presence' do
      [:provider, :uid, :login, :email, :token].each do |column|
        should validate_presence_of(column)
      end
    end

    context 'uniqueness' do
      [:uid, :login, :email, :token].each do |column|
        should validate_uniqueness_of(column)
      end
    end
  end

  test 'create a new valid user from the auth hash' do
    assert_difference 'User.count', 1 do
      User.create_from_auth_hash(@github_omniauth_hash)
    end

    assert User.last.valid?
  end

  test 'find the user from the auth hash' do
    User.create_from_auth_hash(@github_omniauth_hash)
    located_user = User.find_by_auth_hash(@github_omniauth_hash)

    assert_equal User.last, located_user
  end

  test 'updates the users attributes from the auth hash' do
    @user.assign_from_auth_hash(@github_omniauth_hash)
    assert_equal @github_omniauth_hash.credentials.token, @user.token
  end
end

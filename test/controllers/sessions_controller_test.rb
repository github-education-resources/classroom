require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
  def setup
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:github]
  end

  test 'new should redirect to /auth/github' do
    get :new
    assert_redirected_to '/auth/github'
  end

  test 'create adds a new user if they do not exist' do
    assert_difference 'User.count' do
      post :create, provider: 'github'
    end
  end

  test 'create finds the user if they already exist' do
    auth_hash = request.env['omniauth.auth']
    User.create_from_auth_hash(auth_hash)

    assert_no_difference 'User.count' do
      post :create, provider: 'github'
    end
  end

  test 'create redirects to the users show path' do
    post :create, provider: 'github'
    assert_redirected_to user_path(User.last)
  end

  test 'destroy removes session[:user_id] AND redirects to the root_path' do
    session[:user_id] = 1
    get :destroy

    assert_equal nil, session[:user_id]
    assert_redirected_to root_path
  end

  test 'failure redirects to root_path with flash message' do
    get :failure, message: 'FAILURE!!!'

    assert_redirected_to root_path
    assert_equal 'FAILURE!!!', flash[:notice]
  end
end

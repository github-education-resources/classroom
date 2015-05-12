require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
  def setup
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:github]
  end

  test 'new should redirect to /auth/github' do
    get :new
    assert_redirected_to '/auth/github'
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

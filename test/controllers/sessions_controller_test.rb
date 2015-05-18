require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
  before do
    @controller                  = SessionsController.new
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:github]
  end

  describe '#new' do
    it 'redirects to /auth/github' do
      get :new
      assert_redirected_to '/auth/github'
    end
  end

  describe '#create' do
    it 'adds a new user if they do not exist' do
      assert_difference 'User.count', 1 do
        post :create, provider: 'github'
      end
    end

    it 'finds the user if they already exist' do
      auth_hash = request.env['omniauth.auth']
      User.create_from_auth_hash(auth_hash)

      assert_no_difference 'User.count' do
        post :create, provider: 'github'
      end
    end

    it 'redirects to the users dashboard' do
      post :create, provider: 'github'
      assert_redirected_to dashboard_path
    end
  end

  describe '#destroy' do
    it 'removes session[:user_id]' do
      session[:user_id] = 1
      get :destroy

      assert_equal nil, session[:user_id]
    end

    it 'redirects to root_path' do
      get :destroy
      assert_redirected_to root_path
    end
  end

  describe '#failure' do
    it 'redirects to root_path with a flash message' do
      get :failure, message: 'Failure!'

      assert_redirected_to root_path
      assert_equal 'Failure!', flash[:notice]
    end
  end
end

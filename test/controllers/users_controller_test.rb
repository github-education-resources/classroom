require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  def setup
    @user             = users(:tobias)
    session[:user_id] = @user.id
  end

  test '#show returns success' do
    get :show
    assert_response :success
    assert_not_nil assigns(:user)
  end
end

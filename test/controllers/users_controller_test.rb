require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  def setup
    @user = users(:jim)
  end

  test 'should get show' do
    get :show, 'id' => @user.id
    assert_response :success
    assert_not_nil assigns(:user)
  end
end

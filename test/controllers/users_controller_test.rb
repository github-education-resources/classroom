require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  before do
    @controller       = UsersController.new
    session[:user_id] = users(:tobias).id
  end

  describe '#show' do
    it 'returns success and sets the user' do
      get :show
      assert_response :success
      assert_not_nil assigns(:user)
    end
  end
end

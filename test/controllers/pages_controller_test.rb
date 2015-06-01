require 'test_helper'

class PagesControllerTest < ActionController::TestCase
  before do
    @controller = PagesController.new
  end

  describe '#home' do
    it 'returns success' do
      get :home
      assert_response :success
    end

    it 'redirects to the dashboard_path if a user is logged in' do
      session[:user_id] = create(:user).id
      get :home
      assert_redirected_to dashboard_path
    end
  end
end

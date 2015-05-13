require 'test_helper'

class PagesControllerTest < ActionController::TestCase
  test '#home returns success' do
    get :home
    assert_response :success
  end
end

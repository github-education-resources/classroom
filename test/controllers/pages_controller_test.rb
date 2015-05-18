require 'test_helper'

class PagesControllerTest < ActionController::TestCase
  before do
    @controller = PagesController.new
  end

  describe '#home' do
    test 'returns success' do
      get :home
      assert_response :success
    end
  end
end

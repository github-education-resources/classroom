require 'test_helper'

class OcticonHelperTest < ActionView::TestCase
  test 'should return a mega-oction span tag' do
    assert_equal "<span class=\"mega-octicon octicon-logo-github\"></span>", mega_octicon('logo-github')
  end

  test 'should return an oction span tag' do
    assert_equal "<span class=\"octicon octicon-logo-github\"></span>", octicon('logo-github')
  end
end

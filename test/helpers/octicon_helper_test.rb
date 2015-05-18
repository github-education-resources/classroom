require 'test_helper'

class OcticonHelperTest < ActionView::TestCase
  test '#mega_oction returns a mega-oction span tag' do
    assert_equal "<span class=\"mega-octicon octicon-logo-github\"></span>", mega_octicon('logo-github')
  end

  test '#octicon returns an oction span tag' do
    assert_equal "<span class=\"octicon octicon-logo-github\"></span>", octicon('logo-github')
  end
end

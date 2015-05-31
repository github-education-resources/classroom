require 'test_helper'

class InvitationTest < ActiveSupport::TestCase
  def setup
    @invitation = create(:invitation)
  end

  test '#accept_invitation' do
    # Still Todo
  end

  test '#to_param' do
    assert @invitation.key, @invitation.to_param
  end
end

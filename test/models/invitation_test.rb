require 'test_helper'

class InvitationTest < ActiveSupport::TestCase
  def setup
    @invitation = invitations(:one)
  end

  test '#accept_invitation' do
    # Still Todo
  end

  test '#to_param' do
    assert @invitation.key, @invitation.to_param
  end
end

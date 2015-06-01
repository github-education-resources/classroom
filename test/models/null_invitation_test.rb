require 'test_helper'

class NullInvitationTest < ActiveSupport::TestCase
  def setup
    @null_invitation = NullInvitation.new
  end

  test 'has the same interface as Invitation' do
    assert_matching_interface Invitation, NullInvitation
  end

  test '#to_param_path' do
    assert 'invitations/null', @null_invitation
  end
end

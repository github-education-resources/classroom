require 'test_helper'

class InvitationTest < ActiveSupport::TestCase
  def setup
    @invitation = create(:invitation)
  end

  test '#accept_invitation' do
    team_id    = 43
    other_user = { login: 'otheruser', id: 42 }

    stub_github_user(other_user[:id], other_user)
    stub_add_team_membership(@invitation.team_id, other_user[:login], { state: 'pending' })

    @invitation.accept_invitation(other_user)

    assert_requested :put, github_url("/teams/#{@invitation.team_id}/memberships/#{other_user[:login]}")
  end

  test '#to_param' do
    assert @invitation.key, @invitation.to_param
  end
end

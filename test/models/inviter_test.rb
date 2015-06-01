require 'test_helper'

class InviterTest < ActiveSupport::TestCase
  def setup
    @user         = create(:user_with_organizations)
    @organization = @user.organizations.first

    @team = { id: 8675309, name: 'Students' }
  end

  test '#create_invitation with an existing team returns a valid invitation' do
    stub_json_request(:get,
                      github_url("/teams/#{@team[:id]}"),
                      @team)

    inviter    = Inviter.new(@user, @organization, @team[:id], @team[:name])
    invitation = inviter.create_invitation

    assert invitation.valid?
  end

  test '#create_invitation with new team parameters returns a valid invitation' do
    stub_json_request(:get,
                      github_url("/teams/"),
                      nil)

    stub_json_request(:post,
                      github_url("/organizations/#{@organization.github_id}/teams"),
                      { name: @team[:name], permission: 'push'}.to_json,
                      @team)

    inviter    = Inviter.new(@user, @organization, nil, @team[:name])
    invitation = inviter.create_invitation

    assert invitation.valid?
  end
end

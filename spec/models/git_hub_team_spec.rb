require 'rails_helper'

describe GitHubTeam do
  let(:user)         { create(:user_with_organizations) }
  let(:organization) { user.organizations.first }
  let(:team)         { { id: 8_675_309, name: 'Students' } }

  describe '#add_user_to_team' do
    it 'adds a user to the given GitHubTeam' do
    end
  end

  describe '#create_team' do
    before(:each) do
      stub_github_team(nil, nil)
    end

    it 'returns a GitHubTeam' do
      stub_create_github_team(organization.github_id, { name: team[:name], permission: 'push' }, team)

      github_team = GitHubTeam.create_team(user, organization.github_id, team[:name])

      expect(github_team.id).to eql(team[:id])
      expect(github_team.name).to eql(team[:name])
    end

    it 'returns a NullGitHubTeam' do
      stub_create_github_team(organization.github_id, { name: team[:name], permission: 'push' }, nil)

      github_team = GitHubTeam.create_team(user, organization.github_id, team[:name])

      expect(github_team.class).to eq(NullGitHubTeam)
    end
  end
end

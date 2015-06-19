require 'rails_helper'

describe GitHubClient do
  let(:admin_org)  { { login: 'tarebytetestorg', id: 12_439_714, owners_team_id: 1_501_923 } }

  let(:member_org) { { login: 'education',       id: 6_667_880 } }

  let(:user)      { { login: 'tarebyte',        id:   564_113  } }
  let(:test_user) { { login: 'tarebytetest',    id: 12_435_329 } }

  let(:token)  { Rails.application.secrets.classroom_test_github_token || 'some-token' }

  let(:client) { GitHubClient.new(token) }

  describe '#add_team_membership' do
    it 'invites a user to a team' do
      VCR.use_cassette('add_team_membership') do
        membership = client.add_team_membership(admin_org[:owners_team_id], test_user[:login])
        assert_requested :put, github_url("teams/#{admin_org[:owners_team_id]}/memberships/#{test_user[:login]}")
        expect(membership.state).to eq('pending')
      end
    end
  end

  describe '#create_repository' do
    it 'creates a repository' do
    end
  end

  describe '#create_team' do
    it 'created a team on a GitHub organization' do
      VCR.use_cassette('create_team') do
        team_name = "Test Team #{Time.zone.now.to_i}"
        client.create_team(admin_org[:id], name: team_name)

        assert_requested :post, github_url("/organizations/#{admin_org[:id]}/teams")
      end
    end
  end

  describe '#organization' do
    it 'gets a GitHub organization' do
      VCR.use_cassette('organization') do
        organization = client.organization(member_org[:id])

        assert member_org[:login], organization.login
        assert_requested :get, github_url("/organizations/#{member_org[:id]}")
      end
    end
  end

  describe '#organization_admin?' do
    it 'returns whether or not a user is an admin of a given GitHub organization' do
      VCR.use_cassette('admin_organization_membership') do
        expect(client.organization_admin?(admin_org[:id])).to be(true)
        assert_requested :get, github_url("user/memberships/orgs/#{admin_org[:login]}")
      end

      VCR.use_cassette('member_organization_membership') do
        expect(client.organization_admin?(member_org[:id])).to be(false)
        assert_requested :get, github_url("user/memberships/orgs/#{member_org[:login]}")
      end
    end
  end

  describe '#organization_teams' do
    it 'returns that organizations teams' do
      VCR.use_cassette('organization_teams') do
        teams = client.organization_teams(member_org[:id])
        expect(teams.class).to be(Array)
        assert_requested :get, github_url("/organizations/#{member_org[:id]}/teams?per_page=100")
      end
    end
  end

  describe '#organization_membership' do
    it 'gets the users membership of the organization' do
      VCR.use_cassette('organization_membership') do
        client.organization_membership(member_org[:login])
        assert_requested :get, github_url("/user/memberships/orgs/#{member_org[:login]}")
      end
    end
  end

  describe '#team' do
    it 'gets a organization team' do
      VCR.use_cassette('team') do
        team = client.team(admin_org[:owners_team_id])
        expect(team.id).to be(admin_org[:owners_team_id])
        assert_requested :get, github_url("/teams/#{admin_org[:owners_team_id]}")
      end
    end
  end

  describe '#team_repository?' do
    it 'checks to see if a repository belongs to a team' do
      VCR.use_cassette('team_repository?') do
        team_repo = client.team_repository?(admin_org[:owners_team_id], "#{admin_org[:login]}/notateamrepository")
        url       = "/teams/#{admin_org[:owners_team_id]}/repos/#{admin_org[:login]}/notateamrepository"

        expect(team_repo).to be(false)
        assert_requested :get, github_url(url)
      end
    end
  end

  describe '#user' do
    it 'gets a specified GitHub user' do
      VCR.use_cassette('user') do
        github_user = client.user(test_user[:id])

        expect(github_user.login).to eql(test_user[:login])
        assert_requested :get, github_url("/user/#{test_user[:id]}")
      end
    end

    it 'will get the users GitHub information' do
      VCR.use_cassette('user_self') do
        user = client.user
        expect(user.login).to eql(user[:login])
        assert_requested :get, github_url('/user')
      end
    end
  end
end

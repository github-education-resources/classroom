require 'rails_helper'

describe GitHubTeam do
  before do
    Octokit.reset!
    @client              = oauth_client
    @github_organization = GitHubOrganization.new(@client, 'cse3901-osu-2015su')
  end

  before(:each) do
    team = @github_organization.create_team('Team')
    @github_team = GitHubTeam.new(@client, team.id)
  end

  after(:each) do
    @client.delete_team(@github_team.id)
  end

  describe '#add_to_team', :vcr do
    it 'adds a user to the given GitHubTeam' do
      @github_team.add_to_team('tarebytetest')
      assert_requested :put, github_url("teams/#{@github_team.id}/memberships/tarebytetest")
    end
  end

  describe '#team_repository?', :vcr do
    it 'checks if a repo is managed by a specific team' do
      is_team_repo = @github_team.team_repository?('cse3901-osu-2015su/notateamrepository')
      url = "/teams/#{@github_team.id}/repos/cse3901-osu-2015su/notateamrepository"

      expect(is_team_repo).to be false
      assert_requested :get, github_url(url)
    end
  end
end

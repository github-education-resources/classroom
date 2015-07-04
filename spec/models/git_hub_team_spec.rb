require 'rails_helper'

describe GitHubTeam do
  before do
    Octokit.reset!
    @client              = oauth_client
    @github_organization = GitHubOrganization.new(@client, classroom_owner_github_org_id)
  end

  before(:each) do
    team_name    = "Team Team #{Time.zone.now.to_i}"
    team         = @github_organization.create_team(team_name)
    @github_team = GitHubTeam.new(@client, team.id)
  end

  after(:each) do
    @client.delete_team(@github_team.id)
  end

  describe '#add_to_team', :vcr do
    it 'adds a user to the given GitHubTeam' do
      @github_team.add_to_team(classroom_student)
      assert_requested :put, github_url("teams/#{@github_team.id}/memberships/#{classroom_student}")
    end
  end

  describe '#team_repository?', :vcr do
    it 'checks if a repo is managed by a specific team' do
      is_team_repo = @github_team.team_repository?("#{classroom_owner_github_org}/notateamrepository")
      url = "/teams/#{@github_team.id}/repos/#{classroom_owner_github_org}/notateamrepository"

      expect(is_team_repo).to be false
      assert_requested :get, github_url(url)
    end
  end
end

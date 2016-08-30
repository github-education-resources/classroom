# frozen_string_literal: true
require 'rails_helper'

describe GitHubTeam do
  before do
    Octokit.reset!
    @client                    = oauth_client
    @github_organization_login = classroom_owner_organization_github_login
    @github_organization       = GitHubOrganization.new(@client, @github_organization_login)
  end

  before(:each) do
    team = @github_organization.create_team('Team')
    @github_team = GitHubTeam.new(@client, team.id)
  end

  after(:each) do
    @client.delete_team(@github_team.id)
  end

  describe '#add_team_membership', :vcr do
    it 'adds a user to the given GitHubTeam' do
      login = @client.user.login
      @github_team.add_team_membership(login)
      expect(WebMock).to have_requested(:put, github_url("teams/#{@github_team.id}/memberships/#{login}"))
    end
  end

  describe '#team_repository?', :vcr do
    it 'checks if a repo is managed by a specific team' do
      is_team_repo = @github_team.team_repository?("#{@github_organization_login}/notateamrepository")
      url = "/teams/#{@github_team.id}/repos/#{@github_organization_login}/notateamrepository"

      expect(is_team_repo).to be false
      expect(WebMock).to have_requested(:get, github_url(url))
    end
  end

  describe '#html_url', :vcr do
    it 'returns the GitHub URL for the team' do
      expected_url = "https://github.com/orgs/#{@github_organization.login}/teams/#{@github_team.slug}"
      expect(@github_team.html_url).to eql(expected_url)
    end
  end

  GitHubTeam.new(@client, 123).send(:attributes).each do |attribute|
    describe "##{attribute}", :vcr do
      it "gets the #{attribute} of the team" do
        gh_team = @client.team(@github_team.id)

        if attribute == 'organization'
          expect(@github_team.send(attribute).id).to eql(gh_team.send(attribute).id)
        else
          expect(@github_team.send(attribute)).to eql(gh_team.send(attribute))
        end

        expect(WebMock).to have_requested(:get, github_url("/teams/#{gh_team.id}")).twice
      end
    end
  end
end

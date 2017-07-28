# frozen_string_literal: true

require "rails_helper"

describe GitHubTeam do
  before do
    Octokit.reset!
    @client                    = oauth_client
    @github_organization_login = classroom_owner_organization_github_login
    @github_organization       = GitHubOrganization.new(@client, @github_organization_login)
  end

  before(:each) do
    team = @github_organization.create_team("Team")
    @github_team = GitHubTeam.new(@client, team.id)
  end

  after(:each) do
    @client.delete_team(@github_team.id)
  end

  it "responds to all (GitHub) attributes", :vcr do
    gh_team = @client.team(@github_team.id)

    @github_team.attributes.each do |attribute, value|
      next if %i[client access_token organization].include?(attribute)
      expect(@github_team).to respond_to(attribute)
      expect(value).to eql(gh_team.send(attribute))
    end

    expect(WebMock).to have_requested(:get, github_url("/orgs/#{@github_organization_login}"))
    expect(WebMock).to have_requested(:get, github_url("/teams/#{@github_team.id}")).times(3)
  end

  it "responds to all *_no_cache methods", :vcr do
    @github_team.attributes.each do |attribute, _|
      next if %i[id client access_token organization].include?(attribute)
      expect(@github_team).to respond_to("#{attribute}_no_cache")
    end
  end

  describe "#add_team_membership", :vcr do
    it "adds a user to the given GitHubTeam" do
      login = @client.user.login
      @github_team.add_team_membership(login)
      expect(WebMock).to have_requested(:put, github_url("teams/#{@github_team.id}/memberships/#{login}"))
    end
  end

  describe "#team_repository?", :vcr do
    it "checks if a repo is managed by a specific team" do
      is_team_repo = @github_team.team_repository?("#{@github_organization_login}/notateamrepository")
      url = "/teams/#{@github_team.id}/repos/#{@github_organization_login}/notateamrepository"

      expect(is_team_repo).to be false
      expect(WebMock).to have_requested(:get, github_url(url))
    end
  end

  describe "#html_url", :vcr do
    it "returns the GitHub URL for the team" do
      expected_url = "https://github.com/orgs/#{@github_organization.login}/teams/#{@github_team.slug}"
      expect(@github_team.html_url).to eql(expected_url)
    end
  end
end

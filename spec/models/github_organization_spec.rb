# frozen_string_literal: true

require "rails_helper"

describe GitHubOrganization do
  let(:organization) { classroom_org }

  before do
    Octokit.reset!
    @client              = oauth_client
    @repo_name           = "test-github-repository"
    @github_organization = GitHubOrganization.new(@client, organization.github_id)
  end

  it "responds to all (GitHub) attributes", :vcr do
    gh_organization = @client.organization(organization.github_id)

    @github_organization.attributes.each do |attribute, value|
      next if %i[client access_token].include?(attribute)
      expect(@github_organization).to respond_to(attribute)
      expect(value).to eql(gh_organization.send(attribute))
    end

    expect(WebMock).to have_requested(:get, github_url("/organizations/#{organization.github_id}")).twice
  end

  it "responds to all *_no_cache methods", :vcr do
    @github_organization.attributes.each do |attribute, _|
      next if %i[id client access_token].include?(attribute)
      expect(@github_organization).to respond_to("#{attribute}_no_cache")
    end
  end

  describe "#admin?", :vcr do
    it "verifies if the user is an admin of the organization" do
      user         = organization.users.first
      github_admin = GitHubUser.new(user.github_client, user.uid)
      expect(@github_organization.admin?(github_admin.login)).to eql(true)
    end

    it "returns false otherwise" do
      user = create(:user, uid: 67)
      github_admin = GitHubUser.new(user.github_client, user.uid)
      expect(@github_organization.admin?(github_admin.login)).to be_falsey
    end
  end

  describe "#create_repository", :vcr do
    after do
      @client.delete_repository("#{organization.title}/#{@repo_name}")
    end

    it "successfully creates a GitHub Repository for the Organization" do
      @github_organization.create_repository(@repo_name, private: true)
      expect(WebMock).to have_requested(:post, github_url("/organizations/#{organization.github_id}/repos"))
    end
  end

  describe "#create_team", :vcr do
    before do
      @github_team = @github_organization.create_team("Team")
    end

    after do
      @client.delete_team(@github_team.id)
    end

    it "successfully creates a GitHub team" do
      expect(WebMock).to have_requested(:post, github_url("/organizations/#{organization.github_id}/teams"))
    end
  end

  describe "#plan", :vcr do
    it "gets the plan for an organization" do
      expect(@github_organization.plan[:owned_private_repos]).not_to be_nil
      expect(@github_organization.plan[:private_repos]).not_to be_nil
    end

    it "fails for an org that the token is not authenticated for" do
      unauthorized_github_organization = GitHubOrganization.new(@client, 9919)
      expect { unauthorized_github_organization.plan }.to raise_error(GitHub::Error)
    end
  end

  describe "#create_organization_webhook", :vcr do
    before do
      @org_hook = @github_organization.create_organization_webhook(config: { url: "http://localhost" })
    end

    after do
      @client.remove_org_hook(organization.github_id, @org_hook.id)
    end

    it "successfully creates a GitHub organization webhook" do
      expect(WebMock).to have_requested(:post, github_url("/organizations/#{organization.github_id}/hooks"))
    end
  end

  describe "#remove_organization_webhook", :vcr do
    before do
      @org_hook = @github_organization.create_organization_webhook(config: { url: "http://localhost" })
    end

    it "successfully removes the GitHub organization webhook" do
      @github_organization.remove_organization_webhook(@org_hook.id)
      expect(WebMock).to have_requested(:delete,
                                        github_url("/organizations/#{organization.github_id}/hooks/#{@org_hook.id}"))
    end
  end

  describe "#team_invitations_url", :vcr do
    it "points to the people url" do
      url = "https://github.com/orgs/#{@github_organization.login}/people"
      expect(@github_organization.team_invitations_url).to eql(url)
    end
  end
end

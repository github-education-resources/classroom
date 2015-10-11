require 'rails_helper'

describe GitHubOrganization do
  let(:organization) { GitHubFactory.create_owner_classroom_org }

  before do
    Octokit.reset!
    @client              = oauth_client
    @repo_name           = 'test-github-repository'
    @github_organization = GitHubOrganization.new(@client, organization.github_id)
  end

  describe '#admin?', :vcr do
    it 'verifies if the user is an admin of the organization' do
      github_admin = GitHubUser.new(organization.users.first.github_client)
      expect(@github_organization.admin?(github_admin.login)).to eql(true)
    end
  end

  describe '#create_repository', :vcr do
    after do
      @client.delete_repository("#{organization.title}/#{@repo_name}")
    end

    it 'successfully creates a GitHub Repository for the Organization' do
      @github_organization.create_repository(@repo_name, private: true)
      expect(WebMock).to have_requested(:post, github_url("/organizations/#{organization.github_id}/repos"))
    end
  end

  describe '#create_team', :vcr do
    before do
      @github_team = @github_organization.create_team('Team')
    end

    after do
      @client.delete_team(@github_team.id)
    end

    it 'successfully creates a GitHub team' do
      expect(WebMock).to have_requested(:post, github_url("/organizations/#{organization.github_id}/teams"))
    end
  end

  describe '#login', :vcr do
    it 'gets the login for the GitHub Organization' do
      expect(@github_organization.login).to eql(organization.title)
    end
  end
end

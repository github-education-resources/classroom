# frozen_string_literal: true
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
      user         = organization.users.first
      github_admin = GitHubUser.new(user.github_client, user.uid)
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

  describe '#plan', :vcr do
    it 'gets the plan for an organization' do
      expect(@github_organization.plan[:owned_private_repos]).not_to be_nil
      expect(@github_organization.plan[:private_repos]).not_to be_nil
    end

    it 'fails for an org that the token is not authenticated for' do
      unauthorized_github_organization = GitHubOrganization.new(@client, 9919)
      expect { unauthorized_github_organization.plan }.to raise_error(GitHub::Error)
    end
  end

  describe '#create_organization_webhook', :vcr do
    before do
      @org_hook = @github_organization.create_organization_webhook(config: { url: 'http://example.com' })
    end

    after do
      @client.remove_org_hook(organization.github_id, @org_hook.id)
    end

    it 'successfully creates a GitHub organization webhook' do
      expect(WebMock).to have_requested(:post, github_url("/organizations/#{organization.github_id}/hooks"))
    end
  end

  GitHubOrganization.new(@client, 123).send(:attributes).each do |attribute|
    describe "##{attribute}", :vcr do
      it "gets the #{attribute} of the organization" do
        gh_organization = @client.organization(organization.github_id)

        expect(@github_organization.send(attribute)).to eql(gh_organization.send(attribute))
        expect(WebMock).to have_requested(:get, github_url("/organizations/#{organization.github_id}")).twice
      end
    end
  end
end

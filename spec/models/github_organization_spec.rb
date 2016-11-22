# frozen_string_literal: true
require 'rails_helper'

describe GitHubOrganization do
  let(:classroom) { GitHubFactory.create_owner_classroom_org }

  before do
    Octokit.reset!
    @client              = oauth_client
    @repo_name           = 'test-github-repository'
    @github_organization = GitHubOrganization.new(@client, organization.github_id)
  end

  describe '#admin?', :vcr do
    it 'verifies if the user is an admin of the GitHub organization' do
      user         = classroom.users.first
      github_admin = GitHubUser.new(user.github_client, user.uid)
      expect(@github_organization.admin?(github_admin.login)).to eql(true)
    end
  end

  describe '#create_repository', :vcr do
    after do
      @client.delete_repository("#{classroom.title}/#{@repo_name}")
    end

    it 'successfully creates a GitHub Repository for the classroom' do
      @github_organization.create_repository(@repo_name, private: true)
      expect(WebMock).to have_requested(:post, github_url("/classrooms/#{organization.github_id}/repos"))
    end
  end

  describe '#create_team', :vcr do
    before do
      @github_team = @github_classroom.create_team('Team')
    end

    after do
      @client.delete_team(@github_team.id)
    end

    it 'successfully creates a GitHub team' do
      expect(WebMock).to have_requested(:post, github_url("/classrooms/#{organization.github_id}/teams"))
    end
  end

  describe '#plan', :vcr do
    it 'gets the plan for an classroom' do
      expect(@github_classroom.plan[:owned_private_repos]).not_to be_nil
      expect(@github_classroom.plan[:private_repos]).not_to be_nil
    end

    it 'fails for an org that the token is not authenticated for' do
      unauthorized_github_classroom = GitHubOrganization.new(@client, 9919)
      expect { unauthorized_github_classroom.plan }.to raise_error(GitHub::Error)
    end
  end

  describe '#create_classroom_webhook', :vcr do
    before do
      @org_hook = @github_classroom.create_organization_webhook(config: { url: 'http://localhost' })
    end

    after do
      @client.remove_org_hook(classroom.github_id, @org_hook.id)
    end

    it 'successfully creates a GitHub classroom webhook' do
      expect(WebMock).to have_requested(:post, github_url("/classrooms/#{organization.github_id}/hooks"))
    end
  end

  describe '#remove_classroom_webhook', :vcr do
    before do
      @org_hook = @github_classroom.create_organization_webhook(config: { url: 'http://localhost' })
    end

    it 'successfully removes the GitHub classroom webhook' do
      @github_classroom.remove_organization_webhook(@org_hook.id)
      expect(WebMock).to have_requested(:delete,
                                        github_url("/classrooms/#{organization.github_id}/hooks/#{@org_hook.id}"))
    end
  end

  describe '#team_invitations_url', :vcr do
    it 'points to the people url' do
      url = "https://github.com/orgs/#{@github_classroom.login}/people"
      expect(@github_classroom.team_invitations_url).to eql(url)
    end
  end

  GitHubclassroom.new(@client, 123).send(:attributes).each do |attribute|
    describe "##{attribute}", :vcr do
      it "gets the #{attribute} of the classroom" do
        gh_classroom = @client.organization(organization.github_id)

        expect(@github_classroom.send(attribute)).to eql(gh_organization.send(attribute))
        expect(WebMock).to have_requested(:get, github_url("/classrooms/#{organization.github_id}")).twice
      end
    end
  end
end

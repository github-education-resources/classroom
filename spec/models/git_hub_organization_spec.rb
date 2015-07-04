require 'rails_helper'

describe GitHubOrganization do
  before do
    Octokit.reset!
    @client              = oauth_client
    @github_organization = GitHubOrganization.new(@client, classroom_owner_github_org_id)
  end

  describe '#create_repository', :vcr do
    before do
      @repo_name = "classroom-test-repo"
    end

    after do
      @client.delete_repository("#{classroom_owner_github_org}/#{@repo_name}")
    end

    it 'successfully creates a GitHub Repository for the Organization' do
      github_repository = @github_organization.create_repository(@repo_name, private: true)
      assert_requested :post, github_url("/organizations/#{classroom_owner_github_org_id}/repos")
    end
  end

  describe '#create_team', :vcr do
    before do
      team_name    = "Team Team #{Time.zone.now.to_i}"
      @github_team = @github_organization.create_team(team_name)
    end

    after do
      @client.delete_team(@github_team.id)
    end

    it 'successfully creates a GitHub team' do
      assert_requested :post, github_url("/organizations/#{classroom_owner_github_org_id}/teams")
    end
  end

  describe '#login', :vcr do
    it 'gets the login for the GitHub Organization' do
      expect(@github_organization.login).to eql(classroom_owner_github_org)
    end
  end

  describe '#authorization_on_github_organization', :vcr do
    context 'when authorized' do
      it 'verifies that the user is an owner of the organization' do
        verification_result = @github_organization.authorization_on_github_organization?(classroom_owner_github_org)
        expect(verification_result).to be_nil
      end
    end

    context 'when not authorized' do
      it 'raises a GitHub::Forbidden' do
        begin
          @github_organization.authorization_on_github_organization?(member_github_organization)
        rescue => err
          expect(err.class).to eql(GitHub::Forbidden)
        end
      end
    end
  end
end

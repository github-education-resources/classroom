require 'rails_helper'

describe GitHubRepository do
  let(:organization) { GitHubFactory.create_owner_classroom_org }

  before do
    Octokit.reset!
    @client = oauth_client
  end

  before(:each) do
    github_organization = GitHubOrganization.new(@client, organization.github_id)
    @github_repository  = github_organization.create_repository('test-repository', private: true)
  end

  after(:each) do
    @client.delete_repository(@github_repository.id)
  end

  describe '#full_name', :vcr do
    it 'gets the full_name (owner/repo_name) of the repository' do
      expect(@github_repository.full_name).to eql("#{organization.title}/test-repository")
      assert_requested :get, github_url("/repositories/#{@github_repository.id}")
    end
  end

  describe '#push_to', :vcr do
    it 'mirrors the repository to the destination' do
    end
  end

  describe '#repository', :vcr do
    it 'returns a new GitRepository object' do
      github_repository      = GitHubRepository.new(@client, nil)
      test_github_repository = github_repository.repository("#{organization.title}/test-repository")

      expect(test_github_repository.id).to eql(@github_repository.id)
    end
  end
end

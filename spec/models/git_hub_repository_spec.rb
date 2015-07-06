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
end

require 'rails_helper'

describe GitHubRepository do
  before do
    Octokit.reset!
    @client = oauth_client
  end

  before(:each) do
    @repo_name           = 'repo'
    github_organization  = GitHubOrganization.new(@client, classroom_owner_github_org_id)
    @github_repository   = github_organization.create_repository(@repo_name, private: true)
  end

  after(:each) do
    @client.delete_repository(@full_name)
  end

  describe '#full_name', :vcr do
    it 'gets the full_name (owner/repo_name) of the repository' do
      @full_name = "#{classroom_owner_github_org}/#{@repo_name}"

      expect(@github_repository.full_name).to eql(@full_name)
      assert_requested :get, github_url("/repositories/#{@github_repository.id}")
    end
  end
end

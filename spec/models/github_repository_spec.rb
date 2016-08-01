# frozen_string_literal: true
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

  describe '::present?', :vcr do
    it 'returns true if the repo is present' do
      expect(GitHubRepository.present?(@client, 'rails/rails')).to be_truthy
    end

    it 'returns false if the repo is not present' do
      expect(GitHubRepository.present?(@client, 'foobar/jim')).to be_falsey
    end
  end

  describe '#find_by_name_with_owner!', :vcr do
    it 'raises a GitHubError if it cannot find the repo' do
      expect do
        GitHubRepository.find_by_name_with_owner!(@client, 'foobar/jim')
      end.to raise_error(GitHub::Error)
    end
  end

  GitHubRepository.new(@client, 123).send(:attributes).each do |attribute|
    describe "##{attribute}", :vcr do
      it "gets the #{attribute} of the repository " do
        repository = @client.repository(@github_repository.id)

        expect(@github_repository.send(attribute)).to eql(repository.send(attribute))
        expect(WebMock).to have_requested(:get, github_url("/repositories/#{repository.id}")).twice
      end
    end
  end
end

# frozen_string_literal: true
require 'rails_helper'

describe GitHubRepository do
  let(:organization) { classroom_org }

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

  it 'responds to all (GitHub) attributes', :vcr do
    gh_repo = @client.repository(@github_repository.id)

    @github_repository.attributes.each do |attribute, value|
      next if attribute == :client || attribute == :access_token
      expect(@github_repository).to respond_to(attribute)
      expect(value).to eql(gh_repo.send(attribute))
    end

    expect(WebMock).to have_requested(:get, github_url("/repositories/#{@github_repository.id}")).twice
  end

  it 'responds to all *_no_cache methods', :vcr do
    @github_repository.attributes.each do |attribute, _|
      next if attribute == :id || attribute == :client || attribute == :access_token
      expect(@github_repository).to respond_to("#{attribute}_no_cache")
    end
  end

  describe 'class methods' do
    describe '::present?', :vcr do
      context 'without options' do
        it 'returns true if the repo is present' do
          expect(GitHubRepository.present?(@client, 'rails/rails')).to be_truthy
        end

        it 'returns false if the repo is not present' do
          expect(GitHubRepository.present?(@client, 'foobar/jim')).to be_falsey
        end
      end

      context 'with options' do
        before do
          @custom_options = { headers: GitHub::APIHeaders.no_cache_no_store }
        end

        it 'returns true if the repo is present' do
          expect(GitHubRepository.present?(@client, 'rails/rails', @custom_options)).to be_truthy
        end

        it 'returns false if the repo is not present' do
          expect(GitHubRepository.present?(@client, 'foobar/jim', @custom_options)).to be_falsey
        end

        it 'uses custom options when requesting GitHub API' do
          GitHubRepository.present?(@client, 'rails/rails', @custom_options)

          expect(WebMock).to have_requested(:get, %r{/repos/rails/rails}).with(@custom_options)
        end
      end
    end

    describe '::find_by_name_with_owner!', :vcr do
      it 'raises a GitHubError if it cannot find the repo' do
        expect do
          GitHubRepository.find_by_name_with_owner!(@client, 'foobar/jim') # rubocop:disable Rails/DynamicFindBy
        end.to raise_error(GitHub::Error)
      end
    end
  end

  describe 'instance methods' do
    describe '#present?', :vcr do
      context 'without options' do
        it 'returns true if the repo is present' do
          # 8514 is rails/rails
          github_repository = GitHubRepository.new(@client, 8514)
          expect(github_repository.present?).to be_truthy
        end

        it 'returns false if the repo is not present' do
          github_repository = GitHubRepository.new(@client, -1)
          expect(github_repository.present?).to be_falsey
        end
      end

      context 'with options' do
        before do
          @custom_options = { headers: GitHub::APIHeaders.no_cache_no_store }
        end

        it 'returns true if the repo is present' do
          # 8514 is rails/rails
          github_repository = GitHubRepository.new(@client, 8514)
          expect(github_repository.present?(@custom_options)).to be_truthy
        end

        it 'returns false if the repo is not present' do
          github_repository = GitHubRepository.new(@client, -1)
          expect(github_repository.present?(@custom_options)).to be_falsey
        end

        it 'uses custom options when requesting GitHub API' do
          # 8514 is rails/rails
          github_repository = GitHubRepository.new(@client, 8514)
          github_repository.present?(@custom_options)

          expect(WebMock).to have_requested(:get, github_url('/repositories/8514')).with(@custom_options)
        end
      end
    end

    describe '#public=', :vcr do
      it 'updates the github repository to public' do
        @github_repository.public = true

        expect(WebMock).to have_requested(
          :patch,
          github_url("/repos/#{@github_repository.full_name}")
        ).with(body: { private: false, name: @github_repository.name })
      end

      it 'updates the github repository to private' do
        @github_repository.public = false
        expect(WebMock).to have_requested(
          :patch,
          github_url("/repos/#{@github_repository.full_name}")
        ).with(body: { private: true, name: @github_repository.name })
      end
    end
  end
end

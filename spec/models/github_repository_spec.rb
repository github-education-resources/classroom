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

    describe '#latest_push_event', :vcr do
      it 'queries GitHub events API' do
        repo_id = 8514 # 8514 is rails/rails
        github_repository = GitHubRepository.new(@client, repo_id)
        github_repository.latest_push_event

        expect(WebMock).to have_requested(:get, github_url("/repositories/#{repo_id}/events?page=1&per_page=100"))
      end
    end

    describe '#commit_status', :vcr do
      before(:each) do
        @repo_id = 8514 # 8514 is rails/rails
        @ref = 'refs/heads/master'
      end

      context 'without options' do
        it 'queries GitHub commit status API' do
          github_repository = GitHubRepository.new(@client, @repo_id)
          github_repository.commit_status(@ref)

          expect(WebMock).to have_requested(:get,
                                            github_url("/repositories/#{@repo_id}/commits/#{@ref}/status"))
        end
      end

      context 'with options' do
        before do
          @custom_options = { headers: GitHub::APIHeaders.no_cache_no_store }
        end

        it 'uses custom options when requesting GitHub API' do
          github_repository = GitHubRepository.new(@client, @repo_id)
          github_repository.commit_status(@ref, @custom_options)

          expect(WebMock).to have_requested(:get,
                                            github_url("/repositories/#{@repo_id}/commits/#{@ref}/status"))
            .with(@custom_options)
        end
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
end

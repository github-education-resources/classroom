# frozen_string_literal: true

require "rails_helper"

describe GitHubRepository do
  let(:organization) { classroom_org }

  before do
    Octokit.reset!
    @client = oauth_client
  end

  before(:each) do
    github_organization = GitHubOrganization.new(@client, organization.github_id)
    @github_repository  = github_organization.create_repository("test-repository", private: true)
  end

  after(:each) do
    @client.delete_repository(@github_repository.id)
  end

  it "responds to all (GitHub) attributes", :vcr do
    gh_repo = @client.repository(@github_repository.id)

    @github_repository.attributes.each do |attribute, value|
      next if %i[client access_token].include?(attribute)
      expect(@github_repository).to respond_to(attribute)
      expect(value).to eql(gh_repo.send(attribute))
    end

    expect(WebMock).to have_requested(:get, github_url("/repositories/#{@github_repository.id}")).twice
  end

  it "responds to all *_no_cache methods", :vcr do
    @github_repository.attributes.each do |attribute, _|
      next if %i[id client access_token].include?(attribute)
      expect(@github_repository).to respond_to("#{attribute}_no_cache")
    end
  end

  describe "class methods" do
    describe "::present?", :vcr do
      context "without options" do
        it "returns true if the repo is present" do
          expect(GitHubRepository.present?(@client, "rails/rails")).to be_truthy
        end

        it "returns false if the repo is not present" do
          expect(GitHubRepository.present?(@client, "foobar/jim")).to be_falsey
        end
      end

      context "with options" do
        before do
          @custom_options = { headers: GitHub::APIHeaders.no_cache_no_store }
        end

        it "returns true if the repo is present" do
          expect(GitHubRepository.present?(@client, "rails/rails", @custom_options)).to be_truthy
        end

        it "returns false if the repo is not present" do
          expect(GitHubRepository.present?(@client, "foobar/jim", @custom_options)).to be_falsey
        end

        it "uses custom options when requesting GitHub API" do
          GitHubRepository.present?(@client, "rails/rails", @custom_options)

          expect(WebMock).to have_requested(:get, %r{/repos/rails/rails}).with(@custom_options)
        end
      end
    end

    describe "::find_by_name_with_owner!", :vcr do
      it "raises a GitHubError if it cannot find the repo" do
        expect do
          GitHubRepository.find_by_name_with_owner!(@client, "foobar/jim") # rubocop:disable Rails/DynamicFindBy
        end.to raise_error(GitHub::Error)
      end
    end
  end

  describe "instance methods" do
    describe "#present?", :vcr do
      context "without options" do
        it "returns true if the repo is present" do
          # 8514 is rails/rails
          github_repository = GitHubRepository.new(@client, 8514)
          expect(github_repository.present?).to be_truthy
        end

        it "returns false if the repo is not present" do
          github_repository = GitHubRepository.new(@client, -1)
          expect(github_repository.present?).to be_falsey
        end
      end

      context "with options" do
        before do
          @custom_options = { headers: GitHub::APIHeaders.no_cache_no_store }
        end

        it "returns true if the repo is present" do
          # 8514 is rails/rails
          github_repository = GitHubRepository.new(@client, 8514)
          expect(github_repository.present?(@custom_options)).to be_truthy
        end

        it "returns false if the repo is not present" do
          github_repository = GitHubRepository.new(@client, -1)
          expect(github_repository.present?(@custom_options)).to be_falsey
        end

        it "uses custom options when requesting GitHub API" do
          # 8514 is rails/rails
          github_repository = GitHubRepository.new(@client, 8514)
          github_repository.present?(@custom_options)

          expect(WebMock).to have_requested(:get, github_url("/repositories/8514")).with(@custom_options)
        end
      end
    end

    describe "#public=", :vcr do
      it "updates the github repository to public" do
        @github_repository.public = true

        expect(WebMock).to have_requested(
          :patch,
          github_url("/repos/#{@github_repository.full_name}")
        ).with(body: { private: false, name: @github_repository.name })
      end

      it "updates the github repository to private" do
        @github_repository.public = false
        expect(WebMock).to have_requested(
          :patch,
          github_url("/repos/#{@github_repository.full_name}")
        ).with(body: { private: true, name: @github_repository.name })
      end
    end

    describe "#import_progress", :vcr do
      it "returns progress" do
        # 1296269 is octocat/Hello-World
        starter_code_repository = GitHubRepository.new(@client, 1_296_269)
        @github_repository.get_starter_code_from(starter_code_repository)

        expect(@github_repository.import_progress).to be_a_kind_of(Sawyer::Resource)
      end
    end

    context "importable" do
      describe "#importing?", :vcr do
        it "returns true when import is ongoing" do
          state = GitHubRepository::IMPORT_ONGOING.sample
          allow_any_instance_of(GitHubRepository).to receive(:import_progress).and_return(status: state)

          expect(@github_repository.importing?).to be_truthy
        end

        it "returns false when import is complete" do
          allow_any_instance_of(GitHubRepository).to receive(:import_progress).and_return(status: "complete")

          expect(@github_repository.importing?).to be_falsey
        end

        it "returns false when import fails" do
          state = GitHubRepository::IMPORT_ERRORS.sample
          allow_any_instance_of(GitHubRepository).to receive(:import_progress).and_return(status: state)

          expect(@github_repository.importing?).to be_falsey
        end
      end

      describe "#imported?", :vcr do
        it "returns false when import is ongoing" do
          state = GitHubRepository::IMPORT_ONGOING.sample
          allow_any_instance_of(GitHubRepository).to receive(:import_progress).and_return(status: state)

          expect(@github_repository.imported?).to be_falsey
        end

        it "returns true when import is complete" do
          allow_any_instance_of(GitHubRepository).to receive(:import_progress).and_return(status: "complete")

          expect(@github_repository.imported?).to be_truthy
        end

        it "returns false when import fails" do
          state = GitHubRepository::IMPORT_ERRORS.sample
          allow_any_instance_of(GitHubRepository).to receive(:import_progress).and_return(status: state)

          expect(@github_repository.imported?).to be_falsey
        end
      end

      describe "#import_failed?", :vcr do
        it "returns false when import is ongoing" do
          state = GitHubRepository::IMPORT_ONGOING.sample
          allow_any_instance_of(GitHubRepository).to receive(:import_progress).and_return(status: state)

          expect(@github_repository.import_failed?).to be_falsey
        end

        it "returns false when import is complete" do
          allow_any_instance_of(GitHubRepository).to receive(:import_progress).and_return(status: "complete")

          expect(@github_repository.import_failed?).to be_falsey
        end

        it "returns true when import fails" do
          state = GitHubRepository::IMPORT_ERRORS.sample
          allow_any_instance_of(GitHubRepository).to receive(:import_progress).and_return(status: state)

          expect(@github_repository.import_failed?).to be_truthy
        end
      end
    end

    describe "#create_label", :vcr do
      it "creates label with default color" do
        label = @github_repository.create_label("test-label")

        expect(label[:color]).to eq(GitHubRepository::DEFAULT_LABEL_COLOR)
      end

      it "creates label with specified color" do
        label = @github_repository.create_label("test-label", "f3fdef")

        expect(label[:color]).to eq("f3fdef")
      end
    end

    describe "#labels", :vcr do
      it "returns labels" do
        @github_repository.create_label("test-label1")
        @github_repository.create_label("test-label2")

        labels = @github_repository.labels.map(&:name)
        expect(labels).to include "test-label1"
        expect(labels).to include "test-label2"
      end
    end

    describe "#delete_label!", :vcr do
      it "deletes an existing label" do
        @github_repository.create_label("test-label")
        expect(@github_repository.labels.map(&:name)).to include "test-label"

        @github_repository.delete_label!("test-label")
        expect(@github_repository.labels.map(&:name)).not_to include "test-label"
      end
    end

    describe "#number_of_commits", :vcr do
      it "returns a number greater than 30 for large repos" do
        # education/classroom
        github_repository = GitHubRepository.new(@client, 35_079_964)

        expect(github_repository.number_of_commits).to be > 30
      end
    end
  end
end

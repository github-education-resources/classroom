# frozen_string_literal: true

require "rails_helper"

describe ClassroomConfig do
  let(:organization) { classroom_org }
  let(:config_branch) { ClassroomConfig::CONFIG_BRANCH }

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

  describe "#initialize", :vcr do
    it "raises Error without github-classroom branch" do
      expect { ClassroomConfig.new(@github_repository) }.to raise_error(ArgumentError)
    end

    it "succeeds with a github-classroom branch" do
      expect { ClassroomConfig.new(stub_repository("template")) }.not_to raise_error
    end
  end

  context "valid template repo" do
    subject { ClassroomConfig.new(stub_repository("template")) }

    before(:each) do
      create_github_branch(@client, @github_repository, config_branch)
    end

    describe "#setup_repository", :vcr do
      it "completes repo setup" do
        setup = subject.setup_repository(@github_repository)
        expect(setup).to eq(true)
        expect(@github_repository).not_to be_branch_present config_branch
      end
    end

    describe "#configurable?", :vcr do
      it "is configurable when github-classroom exists" do
        expect(@github_repository).to be_branch_present config_branch
        expect(subject).to be_configurable @github_repository
      end

      it "is not configurable after setup" do
        subject.setup_repository(@github_repository)
        expect(@github_repository).to_not be_branch_present config_branch
        expect(subject).to_not be_configurable @github_repository
      end
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

STUB_REPO_ID = 123

RSpec.describe Assignment, type: :model do
  setup do
    STUB_CLIENT = stub_octokit_client
  end

  it_behaves_like "a default scope where deleted_at is not present"

  it "is invalid without an invitation" do
    expect { create(:assignment, assignment_invitation: nil) }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "is invalid if the organization has been archived" do
    archived = classroom_org
    archived.update(archived_at: 1.week.ago)

    expect { create(:assignment, organization: archived, assignment_invitation: nil) }.to raise_error(ActiveRecord::RecordInvalid)
  end

  describe ".search" do
    let(:searchable_assignment) { create(:assignment) }

    before do
      expect(searchable_assignment).to_not be_nil
    end

    it "searches by id" do
      results = Assignment.search(searchable_assignment.id)
      expect(results.to_a).to include(searchable_assignment)
    end

    it "searches by title" do
      results = Assignment.search(searchable_assignment.title)
      expect(results.to_a).to include(searchable_assignment)
    end

    it "searches by slug" do
      results = Assignment.search(searchable_assignment.slug)
      expect(results.to_a).to include(searchable_assignment)
    end

    it "does not return the assignment when it shouldn't" do
      results = Assignment.search("spaghetto")
      expect(results.to_a).to_not include(searchable_assignment)
    end
  end

  describe "invitations_enabled default" do
    it "sets invitations_enabled to true by default" do
      options = {
        organization: create(:organization),
        slug: "assignment-1"
      }

      assignment = create(:assignment, { title: "foo" }.merge(options))

      expect(assignment.invitations_enabled).to be_truthy
    end
  end

  describe "slug uniqueness" do
    it "verifes that the slug is unique even if the titles are unique" do
      options = {
        organization: create(:organization),
        slug: "assignment-1"
      }

      create(:assignment, { title: "foo" }.merge(options))
      new_assignment = build(:assignment, { title: "bar" }.merge(options))

      expect { new_assignment.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "title blacklist" do
    it "disallows blacklisted names" do
      assignment1 = build(:assignment, organization: create(:organization), title: "new")
      assignment2 = build(:assignment, organization: create(:organization), title: "edit")

      expect { assignment1.save! }.to raise_error(ActiveRecord::RecordInvalid)
      expect { assignment2.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "uniqueness of title across organization" do
    it "validates that a GroupAssignment in the same organization does not have the same slug" do
      options = {
        title: "Ruby project",
        organization: create(:organization)
      }

      create(:group_assignment, options)
      validation_message = "Validation failed: Your assignment repository prefix must be unique"

      expect { create(:assignment, options) }.to raise_error(ActiveRecord::RecordInvalid, validation_message)
    end
  end

  describe "uniqueness of title across application" do
    it "allows two organizations to have the same Assignment title and slug" do
      assignment1 = create(:assignment, organization: create(:organization))
      assignment2 = create(:assignment, organization: create(:organization), title: assignment1.title)

      expect(assignment2.title).to eql(assignment1.title)
      expect(assignment2.slug).to  eql(assignment1.slug)
    end
  end

  context "with assignment" do
    subject { create(:assignment) }

    describe "#flipper_id" do
      it "should return an id" do
        expect(subject.flipper_id).to eq("Assignment:#{subject.id}")
      end
    end

    describe "#public?" do
      it "returns true if Assignments public_repo column is true" do
        expect(subject.public?).to be(true)
      end
    end

    describe "#private?" do
      it "returns false if Assignments public_repo column is true" do
        expect(subject.private?).to be(false)
      end
    end
  end

  describe "#starter_code_repository_not_empty" do
    let(:organization) { classroom_org }

    before(:each) do
      stub_org_request(organization.github_id)
      stub_repo_request(STUB_REPO_ID)
      @github_repository = GitHubRepository.new(STUB_CLIENT, STUB_REPO_ID)
    end

    it "raises an error when starter code repository is empty" do
      assignment = build(:assignment, organization: organization, title: "assignment")
      assignment.assign_attributes(starter_code_repo_id: @github_repository.id)
      stub_repo_contents_request(STUB_REPO_ID) # returning no response is interpreted as empty
      expect { assignment.save! }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Starter code "\
        "repository cannot be empty. Select a repository that is not empty or create the assignment without starter "\
        "code.")
    end

    it "does not raise an error when starter code repository is not empty" do
      assignment = build(:assignment, organization: organization, title: "assignment")
      assignment.assign_attributes(starter_code_repo_id: @github_repository.id)
      stub_repo_contents_request(STUB_REPO_ID, empty: false)

      expect { assignment.save! }.not_to raise_error
    end
  end

  describe "#starter_code_repository_is_template" do
    let(:organization) { classroom_org }
    let(:github_organization) do
      stub_org_request(organization.github_id)
      GitHubOrganization.new(STUB_CLIENT, organization.github_id)
    end
    let(:assignment) { build(:assignment, organization: organization, title: "Assignment") }
    let(:github_repository) do
      stub_repo_request(STUB_REPO_ID)
      GitHubRepository.new(STUB_CLIENT, STUB_REPO_ID)
    end

    context "assignment is using template repos to import" do
      before do
        assignment.update(template_repos_enabled: true)
      end

      it "does not raise an error when starter code repo is a template repo" do
        stub_repo_request(github_repository.id, GitHubRepository::TEMPLATE_PREVIEW_OPTIONS, is_template: true)
        stub_repo_contents_request(github_repository.id, empty: false)
        assignment.assign_attributes(starter_code_repo_id: github_repository.id)
        expect { assignment.save! }.not_to raise_error
      end

      it "raises an error when starter code repository is not a template repo" do
        stub_repo_request(github_repository.id, GitHubRepository::TEMPLATE_PREVIEW_OPTIONS, is_template: false)
        stub_repo_contents_request(github_repository.id, empty: false)
        assignment.assign_attributes(starter_code_repo_id: github_repository.id)
        expect { assignment.save! }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Starter code "\
          "repository is not a template repository. Make it a template repository to use template cloning.")
      end
    end

    context "assignment is not using template repos to import" do
      before do
        assignment.update(template_repos_enabled: false)
      end

      it "does not raise error when using importer" do
        stub_repo_request(github_repository.id)
        stub_repo_contents_request(github_repository.id, empty: false)
        assignment.assign_attributes(starter_code_repo_id: github_repository.id)
        expect { assignment.save! }.not_to raise_error
      end

      it "does not raise error when not using starter code" do
        expect { assignment.save! }.not_to raise_error
      end
    end
  end

  describe "validation methods that call API" do
    let(:organization) { classroom_org }
    let(:assignment) { create(:assignment, organization: organization, title: "Assignment 3") }
    let(:github_repository) do
      stub_repo_request(STUB_REPO_ID)
      GitHubRepository.new(STUB_CLIENT, STUB_REPO_ID)
    end

    context "#starter_code_repository_not_empty" do
      it "calls methods if starter_code_repo_id is changed" do
        expect(assignment).to receive(:starter_code_repository_not_empty)
        assignment.update(starter_code_repo_id: 1_062_897)
      end

      it "does not call methods if starter_code_repo_id is unchanged" do
        expect(assignment).not_to receive(:starter_code_repository_not_empty)
        assignment.update(title: "Assignment 4")
      end
    end

    context "#starter_code_repository_is_template" do
      it "is called if starter_code_repo_id is changed" do
        expect(assignment).to receive(:starter_code_repository_is_template)
        stub_repo_request(1_062_897)
        stub_repo_contents_request(1_062_897)
        assignment.update(starter_code_repo_id: 1_062_897)
      end

      it "is called if template_repos_enabled is changed" do
        expect(assignment).to receive(:starter_code_repository_is_template)
        expect(assignment.update(template_repos_enabled: false)).to be true
      end

      it "is called if both starter_code_repo_id and template_repos_enabled are changed" do
        expect(assignment).to receive(:starter_code_repository_is_template)
        stub_repo_request(1_062_897)
        stub_repo_contents_request(1_062_897)
        assignment.update(starter_code_repo_id: 1_062_897, template_repos_enabled: true)
      end

      it "isn't called if starter_code_repo_id and template_repos_enabled are not changed" do
        expect(assignment).to receive(:starter_code_repository_is_template)
        assignment.update(title: "Assignment 5")
      end
    end
  end

  it "tracks when assignments are created with a private starter code repo owned by a user" do
    stub_repo_request(STUB_REPO_ID, {}, private: true, owner: { type: "User" })
    stub_repo_contents_request(STUB_REPO_ID, empty: false)
    expect(GitHubClassroom.statsd).to receive(:increment).with("assignment.private_repo_owned_by_user.create")
    create(:assignment, starter_code_repo_id: STUB_REPO_ID)
  end

  it "does not track when assignments are created with a private starter code repo owned by an organization" do
    stub_repo_request(STUB_REPO_ID)
    stub_repo_contents_request(STUB_REPO_ID, private: true, owner: { type: "Organization" })
    expect(GitHubClassroom.statsd).to_not receive(:increment).with("assignment.private_repo_owned_by_user.create")
    create(:assignment, starter_code_repo_id: STUB_REPO_ID)
  end
end

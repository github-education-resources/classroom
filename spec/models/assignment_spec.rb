# frozen_string_literal: true

require "rails_helper"

RSpec.describe Assignment, type: :model do
  it_behaves_like "a default scope where deleted_at is not present"

  it "is invalid without an invitation" do
    expect { create(:assignment, assignment_invitation: nil) }.to raise_error(ActiveRecord::RecordInvalid)
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

    before do
      @client = oauth_client
    end

    before(:each) do
      github_organization = GitHubOrganization.new(@client, organization.github_id)
      @github_repository  = github_organization.create_repository("test-repository", private: true)
    end

    after(:each) do
      @client.delete_repository(@github_repository.id)
    end

    it "raises an error when starter code repository is empty", :vcr do
      assignment = build(:assignment, organization: organization, title: "assignment")
      assignment.assign_attributes(starter_code_repo_id: @github_repository.id)

      expect(@github_repository.empty?).to eql(true)
      expect { assignment.save! }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Starter code "\
        "repository cannot be empty. Select a repository that is not empty or create the assignment without starter "\
        "code.")
    end

    it "does not raise an error when starter code repository is not empty", :vcr do
      assignment = build(:assignment, organization: organization, title: "assignment")
      assignment.assign_attributes(starter_code_repo_id: @github_repository.id)
      GitHubRepository.any_instance.stub(:empty?).and_return(false)

      expect(@github_repository.empty?).to eql(false)
      expect { assignment.save! }.not_to raise_error
    end
  end

  describe "#starter_code_repository_is_template", :vcr do
    let(:organization) { classroom_org }
    let(:client) { oauth_client }
    let(:github_organization) { GitHubOrganization.new(client, organization.github_id) }
    let(:assignment) { build(:assignment, organization: organization, title: "Assignment") }
    let(:github_repository) do
      github_organization.create_repository("#{Faker::Team.name} Template", private: true, auto_init: true)
    end

    after do
      client.delete_repository(github_repository.id)
    end

    context "assignment is using template repos to import" do
      before do
        assignment.update(template_repos_enabled: true)
      end

      it "does not raise an error when starter code repo is a template repo" do
        client.patch(
          "https://api.github.com/repositories/#{github_repository.id}",
          is_template: true,
          accept: "application/vnd.github.baptiste-preview"
        )
        assignment.assign_attributes(starter_code_repo_id: github_repository.id)
        expect { assignment.save! }.not_to raise_error
      end

      it "raises an error when starter code repository is not a template repo" do
        client.patch(
          "https://api.github.com/repositories/#{github_repository.id}",
          is_template: false,
          accept: "application/vnd.github.baptiste-preview"
        )
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
        assignment.assign_attributes(starter_code_repo_id: github_repository.id)
        expect { assignment.save! }.not_to raise_error
      end

      it "does not raise error when not using starter code" do
        expect { assignment.save! }.not_to raise_error
      end
    end
  end
end

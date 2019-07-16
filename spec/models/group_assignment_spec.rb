# frozen_string_literal: true

require "rails_helper"

RSpec.describe GroupAssignment, type: :model do
  it_behaves_like "a default scope where deleted_at is not present"

  describe ".search" do
    let(:searchable_assignment) { create(:group_assignment) }

    before do
      expect(searchable_assignment).to_not be_nil
    end

    it "searches by id" do
      results = GroupAssignment.search(searchable_assignment.id)
      expect(results.to_a).to include(searchable_assignment)
    end

    it "searches by title" do
      results = GroupAssignment.search(searchable_assignment.title)
      expect(results.to_a).to include(searchable_assignment)
    end

    it "searches by slug" do
      results = GroupAssignment.search(searchable_assignment.slug)
      expect(results.to_a).to include(searchable_assignment)
    end

    it "does not return the assignment when it shouldn't" do
      results = GroupAssignment.search("spaghetto")
      expect(results.to_a).to_not include(searchable_assignment)
    end
  end

  describe "invitations_enabled default" do
    it "sets invitations_enabled to true by default" do
      options = {
        organization: create(:organization),
        slug: "assignment-1"
      }

      assignment = create(:group_assignment, { title: "foo" }.merge(options))

      expect(assignment.invitations_enabled).to be_truthy
    end
  end

  describe "slug uniqueness" do
    it "verifes that the slug is unique even if the titles are unique" do
      options = {
        organization: create(:organization),
        slug: "group-assignment-1"
      }

      create(:group_assignment, { title: "group-assignment-1" }.merge(options))
      new_group_assignment = build(:group_assignment, { title: "group assignment 1" }.merge(options))

      expect { new_group_assignment.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "title blacklist" do
    it "disallows blacklisted names" do
      groupassignment1 = build(:group_assignment, organization: create(:organization), title: "new")
      groupassignment2 = build(:group_assignment, organization: create(:organization), title: "edit")

      expect { groupassignment1.save! }.to raise_error(ActiveRecord::RecordInvalid)
      expect { groupassignment2.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "uniqueness of title across organization" do
    it "validates that an Assignment in the same organization does not have the same slug" do
      options = {
        title: "Ruby project",
        organization: create(:organization)
      }

      create(:assignment, options)
      group_assignment = build(:group_assignment, options)

      validation_message = "Validation failed: Your assignment repository prefix must be unique"
      expect { group_assignment.save! }.to raise_error(ActiveRecord::RecordInvalid, validation_message)
    end
  end

  describe "uniqueness of title across application" do
    it "allows two organizations to have the same GroupAssignment title and slug" do
      groupassignment1 = create(:assignment, organization: create(:organization))
      groupassignment2 = create(:group_assignment, organization: create(:organization), title: groupassignment1.title)

      expect(groupassignment2.title).to eql(groupassignment1.title)
      expect(groupassignment2.slug).to eql(groupassignment1.slug)
    end
  end

  context "with group_assignment" do
    subject { create(:group_assignment) }

    describe "#flipper_id" do
      it "should return an id" do
        expect(subject.flipper_id).to eq("GroupAssignment:#{subject.id}")
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

  describe "#max_teams_less_than_group_count" do
    let(:organization) { classroom_org }
    let(:grouping)     { create(:grouping, organization: organization) }
    let(:first_group)  { create(:group, grouping: grouping) }
    let(:second_group) { create(:group, grouping: grouping) }
    let(:options) do
      {
        organization: organization,
        slug: "group-assignment-1",
        title: "Group Assignment 1",
        grouping: grouping
      }
    end

    before(:each) do
      first_group.reload
      second_group.reload
    end

    context "adding max_teams limit to new group assignment" do
      let(:group_assignment) { build(:group_assignment, options) }

      it "raises exception when creating new assignment with grouping group count greater than max_teams" do
        group_assignment.update(max_teams: 1)

        validation_message = "Validation failed: Max teams is less than the number of teams in the existing"\
          " set you've selected (2)"
        expect { group_assignment.save! }.to raise_error(ActiveRecord::RecordInvalid, validation_message)
      end

      it "does not raise exception when creating new assignment with grouping group count less than or equal to"\
        " max_teams" do
        group_assignment.update(max_teams: 2)

        expect { group_assignment.save! }.not_to raise_error
      end
    end

    context "adding max_teams limit to existing group assignment" do
      let(:group_assignment) { create(:group_assignment, options) }

      it "raises exception when existing group count is greater than max_teams limit" do
        group_assignment.update(max_teams: 1)

        validation_message = "Validation failed: Max teams is less than the number of existing teams (2)"
        expect { group_assignment.save! }.to raise_error(ActiveRecord::RecordInvalid, validation_message)
      end

      it "does not raise an exception when existing group count is less than or equal to max_teams limit" do
        group_assignment.update(max_teams: 2)

        expect { group_assignment.save! }.not_to raise_error
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
      group_assignment = build(:group_assignment, organization: organization, title: "group-assignment")
      group_assignment.assign_attributes(starter_code_repo_id: @github_repository.id)

      expect(@github_repository.empty?).to eql(true)
      expect { group_assignment.save! }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Starter code "\
        "repository cannot be empty. Select a repository that is not empty or create the assignment without starter "\
        "code.")
    end

    it "does not raise an error when starter code repository is not empty", :vcr do
      group_assignment = build(:group_assignment, organization: organization, title: "group-assignment")
      group_assignment.assign_attributes(starter_code_repo_id: @github_repository.id)
      GitHubRepository.any_instance.stub(:empty?).and_return(false)

      expect(@github_repository.empty?).to eql(false)
      expect { group_assignment.save! }.not_to raise_error
    end
  end

  describe "#starter_code_repository_is_template", :vcr do
    let(:organization) { classroom_org }
    let(:client) { oauth_client }
    let(:github_organization) { GitHubOrganization.new(client, organization.github_id) }
    let(:group_assignment) { build(:group_assignment, organization: organization, title: "Group Assignment 1") }
    let(:github_repository) do
      github_organization.create_repository("Group Assignment 1 Template", private: true, auto_init: true)
    end

    after(:each) do
      client.delete_repository(github_repository.id)
    end

    context "group assignment is using template repos to import" do
      before do
        group_assignment.update(template_repos_enabled: true)
      end

      it "does not raise an error when starter code repo is a template repo" do
        client.patch(
          "https://api.github.com/repositories/#{github_repository.id}",
          is_template: true,
          accept: "application/vnd.github.baptiste-preview"
        )
        group_assignment.assign_attributes(starter_code_repo_id: github_repository.id)
        expect { group_assignment.save! }.not_to raise_error
      end

      it "raises an error when starter code repository is not a template repo" do
        client.patch(
          "https://api.github.com/repositories/#{github_repository.id}",
          is_template: false,
          accept: "application/vnd.github.baptiste-preview"
        )
        group_assignment.assign_attributes(starter_code_repo_id: github_repository.id)
        expect { group_assignment.save! }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Starter code"\
          " repository is not a template repository. Make it a template repository to use template cloning.")
      end
    end

    context "group assignment is not using template repos to import" do
      before do
        group_assignment.update(template_repos_enabled: false)
      end

      it "does not raise error when using importer" do
        group_assignment.assign_attributes(starter_code_repo_id: github_repository.id)
        expect { group_assignment.save! }.not_to raise_error
      end

      it "does not raise error when not using starter code" do
        expect { group_assignment.save! }.not_to raise_error
      end
    end
  end
end

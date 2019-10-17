# frozen_string_literal: true

require "rails_helper"

STUB_REPO_ID = 123

RSpec.describe GroupAssignment, type: :model do
  setup do
    STUB_CLIENT = stub_octokit_client
  end

  it_behaves_like "a default scope where deleted_at is not present"

  it "is invalid if the organization has been archived" do
    archived = classroom_org
    archived.update(archived_at: 1.week.ago)

    expect { create(:group_assignment, organization: archived) }.to raise_error(ActiveRecord::RecordInvalid)
  end

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

    before(:each) do
      stub_org_request(organization.github_id)
      stub_repo_request(STUB_REPO_ID)
      @github_repository = GitHubRepository.new(STUB_CLIENT, STUB_REPO_ID)
    end

    it "raises an error when starter code repository is empty" do
      group_assignment = build(:group_assignment, organization: organization, title: "group-assignment")
      group_assignment.assign_attributes(starter_code_repo_id: @github_repository.id)

      stub_repo_contents_request(STUB_REPO_ID)
      expect { group_assignment.save! }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Starter code "\
        "repository cannot be empty. Select a repository that is not empty or create the assignment without starter "\
        "code.")
    end

    it "does not raise an error when starter code repository is not empty" do
      group_assignment = build(:group_assignment, organization: organization, title: "group-assignment")
      group_assignment.assign_attributes(starter_code_repo_id: @github_repository.id)
      GitHubRepository.any_instance.stub(:empty?).and_return(false)

      expect(@github_repository.empty?).to eql(false)
      expect { group_assignment.save! }.not_to raise_error
    end
  end

  describe "#starter_code_repository_is_template" do
    let(:organization) { classroom_org }
    let(:github_organization) do
      stub_org_request(organization.github_id)
      GitHubOrganization.new(STUB_CLIENT, organization.github_id)
    end
    let(:group_assignment) { build(:group_assignment, organization: organization, title: "Group Assignment 1") }
    let(:github_repository) do
      stub_repo_request(STUB_REPO_ID)
      GitHubRepository.new(STUB_CLIENT, STUB_REPO_ID)
    end

    context "group assignment is using template repos to import" do
      before do
        group_assignment.update(template_repos_enabled: true)
      end

      it "does not raise an error when starter code repo is a template repo" do
        stub_repo_request(github_repository.id, GitHubRepository::TEMPLATE_PREVIEW_OPTIONS, is_template: true)
        stub_repo_contents_request(github_repository.id, empty: false)
        group_assignment.assign_attributes(starter_code_repo_id: github_repository.id)
        expect { group_assignment.save! }.not_to raise_error
      end

      it "raises an error when starter code repository is not a template repo" do
        stub_repo_request(github_repository.id, GitHubRepository::TEMPLATE_PREVIEW_OPTIONS, is_template: false)
        stub_repo_contents_request(github_repository.id, empty: false)
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
        stub_repo_request(github_repository.id)
        stub_repo_contents_request(github_repository.id, empty: false)
        group_assignment.assign_attributes(starter_code_repo_id: github_repository.id)
        expect { group_assignment.save! }.not_to raise_error
      end

      it "does not raise error when not using starter code" do
        expect { group_assignment.save! }.not_to raise_error
      end
    end
  end

  describe "grouping" do
    let(:organization) { classroom_org }
    let(:grouping)     { build(:grouping, organization: organization) }
    let(:group_assignment) { build(:group_assignment, title: "Test 1", organization: organization, grouping: grouping) }

    context "group_assignment validation fails" do
      before(:each) do
        group_assignment.update_attributes(title: "")
      end

      it "does not persist the grouping" do
        expect(group_assignment.save).to be false
        expect(group_assignment.grouping.persisted?).to be false
      end
    end

    context "group_assignment validation passes" do
      it "persists the grouping" do
        expect(group_assignment.save).to be true
        expect(group_assignment.grouping.persisted?).to be true
      end
    end

    describe "validates_associating Grouping" do
      context "Grouping is invalid" do
        before do
          grouping.assign_attributes(title: "")
        end

        it "Group and Grouping fail validation and are not persisted" do
          expect { group_assignment.save! }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Your set "\
           "of teams is invalid")
          expect(group_assignment.persisted?).to be false
          expect(group_assignment.grouping.persisted?).to be false
        end
      end

      context "Grouping is valid" do
        it "Group and Grouping pass validation and are persisted" do
          expect { group_assignment.save! }.not_to raise_error
          expect(group_assignment.persisted?).to be true
          expect(group_assignment.grouping.persisted?).to be true
        end
      end
    end
  end

  describe "validation methods that call API" do
    let(:organization) { classroom_org }
    let(:group_assignment) { create(:group_assignment, organization: organization, title: "Assignment 3") }

    context "#starter_code_repository_not_empty" do
      it "calls methods if starter_code_repo_id is changed" do
        expect(group_assignment).to receive(:starter_code_repository_not_empty)
        group_assignment.update(starter_code_repo_id: 1_062_897)
      end

      it "does not call methods if starter_code_repo_id is unchanged" do
        expect(group_assignment).not_to receive(:starter_code_repository_not_empty)
        group_assignment.update(title: "Assignment 4")
      end
    end

    context "#starter_code_repository_is_template" do
      it "is called if starter_code_repo_id is changed" do
        expect(group_assignment).to receive(:starter_code_repository_is_template)
        stub_repo_request(1_062_897)
        stub_repo_contents_request(1_062_897)
        group_assignment.update(starter_code_repo_id: 1_062_897)
      end

      it "is called if template_repos_enabled is changed" do
        expect(group_assignment).to receive(:starter_code_repository_is_template)
        expect(group_assignment.update(template_repos_enabled: false)).to be true
      end

      it "is called if both starter_code_repo_id and template_repos_enabled are changed" do
        expect(group_assignment).to receive(:starter_code_repository_is_template)
        stub_repo_request(1_062_897)
        stub_repo_contents_request(1_062_897)
        group_assignment.update(starter_code_repo_id: 1_062_897, template_repos_enabled: true)
      end

      it "isn't called if starter_code_repo_id and template_repos_enabled are not changed" do
        expect(group_assignment).to receive(:starter_code_repository_is_template)
        group_assignment.update(title: "Assignment 5")
      end
    end
  end

  it "tracks when assignments are created with a private starter code repo owned by a user" do
    stub_repo_request(STUB_REPO_ID, {}, private: true, owner: { type: "User" })
    stub_repo_contents_request(STUB_REPO_ID, empty: false)
    expect(GitHubClassroom.statsd).to receive(:increment).with("assignment.private_repo_owned_by_user.create")
    create(:group_assignment, starter_code_repo_id: STUB_REPO_ID)
  end

  it "does not track when assignments are created with a private starter code repo owned by an organization" do
    stub_repo_request(STUB_REPO_ID)
    stub_repo_contents_request(STUB_REPO_ID, private: true, owner: { type: "Organization" })
    expect(GitHubClassroom.statsd).to_not receive(:increment).with("assignment.private_repo_owned_by_user.create")
    create(:group_assignment, starter_code_repo_id: STUB_REPO_ID)
  end
end

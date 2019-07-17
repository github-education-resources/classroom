# frozen_string_literal: true

require "rails_helper"

RSpec.describe CreateGitHubRepoService::Entity do
  let(:entity) { described_class.new(assignment, student) }
  describe ".build" do
    let(:assignment) { double(organization: double, invitation: double(status: double)) }
    it "builds a Individual if collaborator is a user" do
      collaborator = double("is_a?": true)
      expect(described_class.build(assignment, collaborator)).to be_an_instance_of(CreateGitHubRepoService::Individual)
    end
    it "builds a Team if collaborator is a group" do
      collaborator = double("is_a?": false)
      expect(described_class.build(assignment, collaborator)).to be_an_instance_of(CreateGitHubRepoService::Team)
    end
  end
  describe "#organization_login", :vcr do
    let(:organization) { classroom_org }
    let(:student)      { classroom_student }
    let(:assignment) do
      options = {
        title: "Learn Elm",
        starter_code_repo_id: 1_062_897,
        organization: organization,
        students_are_repo_admins: true,
        public_repo: true
      }
      build(:assignment, options)
    end
    let(:entity) { described_class.new(assignment, student) }
    it "is the organization login name" do
      expect(entity.organization_login).to eq(organization.github_organization.login)
    end
  end
end

RSpec.describe CreateGitHubRepoService::Individual, :vcr do
  let(:organization) { classroom_org }
  let(:student)      { classroom_student }
  let(:assignment) do
    options = {
      title: "Learn Elm",
      starter_code_repo_id: 1_062_897,
      organization: organization,
      students_are_repo_admins: true,
      public_repo: true
    }
    build(:assignment, options)
  end
  let(:entity) { described_class.new(assignment, student) }
  describe "#assignment_type" do
    it "is underscored class name" do
      expect(entity.assignment_type).to eq(Assignment.to_s.underscore)
    end
  end
  describe "#user?" do
    it "is true" do
      expect(entity.user?).to be(true)
    end
  end
  describe "#admin?" do
    it "is true if students are repo admins" do
      expect(entity.admin?).to be(true)
    end
    it "is false if students are not repo admins" do
      allow(assignment).to receive(:students_are_repo_admins?).and_return(false)
      expect(entity.admin?).to be(false)
    end
  end
  describe "#default_repo_name" do
    it "is assignment_repo_name-collaborator_slug" do
      expect(entity.default_repo_name).to eq("#{assignment.slug}-#{student.github_user.login}")
    end
  end
  describe "#generate_repo_name" do
    it "is default_repo_name if no repository with same name exists" do
      allow(GitHubRepository).to receive(:present?).and_return(false)
      expect(entity.repo_name).to eq(entity.default_repo_name)
    end
    it "is expected to add suffix if repository with same name exists" do
      allow(GitHubRepository).to receive(:present?).and_return(true, false)
      expect(entity.repo_name).to eq("#{entity.default_repo_name}-1")
    end
  end
  describe "#humanize" do
    it "is expected to return 'user'" do
      expect(entity.humanize).to eq("user")
    end
  end
  describe "#stat_prefix" do
    it "is expected to return 'exercise_repo'" do
      expect(entity.stat_prefix).to eq("exercise_repo")
    end
  end
  describe "#slug" do
    it "is expected to get login from github" do
      expect(entity.collaborator).to receive_message_chain("github_user.login").with(use_cache: false)
      entity.slug
    end
  end
  describe "#repos" do
    it "is expected to be a AssignmentRepo::ActiveRecord_Associations_CollectionProxy" do
      expect(entity.repos).to be_an_instance_of(assignment.assignment_repos.class)
    end
    it "should be assignment.assignment_repos" do
      expect(entity.repos).to eq(assignment.assignment_repos)
    end
  end
end

RSpec.describe CreateGitHubRepoService::Team, :vcr do
  let(:organization) { classroom_org }
  let(:repo_access)    { RepoAccess.create(user: student, organization: organization) }
  let(:grouping)       { create(:grouping, organization: organization) }
  let(:github_team_id) { 3_284_880 }
  let(:group)          { create(:group, grouping: grouping, github_team_id: github_team_id) }
  let(:group_assignment) do
    create(
      :group_assignment,
      grouping: grouping,
      title: "Learn JavaScript",
      organization: organization,
      public_repo: true,
      starter_code_repo_id: 1_062_897,
      students_are_repo_admins: true
    )
  end
  let(:entity) { described_class.new(group_assignment, group) }
  describe "#assignment_type" do
    it "is underscored class name" do
      expect(entity.assignment_type).to eq(GroupAssignment.to_s.underscore)
    end
  end
  describe "#user?" do
    it "is true" do
      expect(entity.user?).to be(false)
    end
  end
  describe "#admin?" do
    it "is true if students are repo admins" do
      expect(entity.admin?).to be(true)
    end
    it "is false if students are not repo admins" do
      allow(group_assignment).to receive(:students_are_repo_admins?).and_return(false)
      expect(entity.admin?).to be(false)
    end
  end
  describe "#default_repo_name" do
    it "is assignment_repo_name-collaborator_slug" do
      expect(entity.default_repo_name).to eq("#{group_assignment.slug}-#{group.github_team.slug_no_cache}")
    end
  end
  describe "#generate_repo_name" do
    it "is default_repo_name if no repository with same name exists" do
      allow(GitHubRepository).to receive(:present?).and_return(false)
      expect(entity.repo_name).to eq(entity.default_repo_name)
    end
    it "is expected to add suffix if repository with same name exists" do
      allow(GitHubRepository).to receive(:present?).and_return(true, false)
      expect(entity.repo_name).to eq("#{entity.default_repo_name}-1")
    end
  end
  describe "#humanize" do
    it "is expected to return 'group'" do
      expect(entity.humanize).to eq("group")
    end
  end
  describe "#stat_prefix" do
    it "is expected to return 'group_exercise_repo'" do
      expect(entity.stat_prefix).to eq("group_exercise_repo")
    end
  end
  describe "#slug" do
    it "is expected to get login from github" do
      expect(entity.collaborator).to receive_message_chain("github_team.slug_no_cache")
      entity.slug
    end
  end
  describe "#repos" do
    it "is expected to be a GroupAssignmentRepo::ActiveRecord_Associations_CollectionProxy" do
      expect(entity.repos).to be_an_instance_of(group_assignment.group_assignment_repos.class)
    end
    it "should be group_assignment.group_assignment_repos" do
      expect(entity.repos).to eq(group_assignment.group_assignment_repos)
    end
  end
end

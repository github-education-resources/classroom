# frozen_string_literal: true

require "rails_helper"

RSpec.describe CreateGitHubRepoService::GroupExercise, :vcr do
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
  let(:exercise) { described_class.new(group_assignment, group) }

  describe "#assignment_type" do
    it "is underscored class name" do
      expect(exercise.assignment_type).to eq(GroupAssignment.to_s.underscore)
    end
  end

  describe "#user?" do
    it "is true" do
      expect(exercise.user?).to be(false)
    end
  end

  describe "#admin?" do
    it "is true if students are repo admins" do
      expect(exercise.admin?).to be(true)
    end

    it "is false if students are not repo admins" do
      allow(group_assignment).to receive(:students_are_repo_admins?).and_return(false)
      expect(exercise.admin?).to be(false)
    end
  end

  describe "#default_repo_name" do
    it "is assignment_repo_name-collaborator_slug" do
      expect(exercise.default_repo_name).to eq("#{group_assignment.slug}-#{group.github_team.slug_no_cache}")
    end
  end

  describe "#generate_repo_name" do
    it "is default_repo_name if no repository with same name exists" do
      allow(GitHubRepository).to receive(:present?).and_return(false)
      expect(exercise.repo_name).to eq(exercise.default_repo_name)
    end

    it "is expected to add suffix if repository with same name exists" do
      allow(GitHubRepository).to receive(:present?).and_return(true, false)
      expect(exercise.repo_name).to eq("#{exercise.default_repo_name}-1")
    end
  end

  describe "#humanize" do
    it "is expected to return 'group'" do
      expect(exercise.humanize).to eq("group")
    end
  end

  describe "#stat_prefix" do
    it "is expected to return 'group_exercise_repo'" do
      expect(exercise.stat_prefix).to eq("group_exercise_repo")
    end
  end

  describe "#slug" do
    it "is expected to get login from github" do
      expect(exercise.collaborator).to receive_message_chain("github_team.slug_no_cache")
      exercise.slug
    end
  end

  describe "#repos" do
    it "is expected to be a GroupAssignmentRepo::ActiveRecord_Associations_CollectionProxy" do
      expect(exercise.repos).to be_an_instance_of(group_assignment.group_assignment_repos.class)
    end

    it "should be group_assignment.group_assignment_repos" do
      expect(exercise.repos).to eq(group_assignment.group_assignment_repos)
    end
  end
end

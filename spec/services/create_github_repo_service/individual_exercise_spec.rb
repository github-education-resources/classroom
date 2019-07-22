# frozen_string_literal: true

require "rails_helper"

RSpec.describe CreateGitHubRepoService::IndividualExercise, :vcr do
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
  let(:exercise) { described_class.new(assignment, student) }

  describe "#assignment_type" do
    it "is underscored class name" do
      expect(exercise.assignment_type).to eq(Assignment.to_s.underscore)
    end
  end

  describe "#user?" do
    it "is true" do
      expect(exercise.user?).to be(true)
    end
  end

  describe "#admin?" do
    it "is true if students are repo admins" do
      expect(exercise.admin?).to be(true)
    end

    it "is false if students are not repo admins" do
      allow(assignment).to receive(:students_are_repo_admins?).and_return(false)
      expect(exercise.admin?).to be(false)
    end
  end

  describe "#default_repo_name" do
    it "is assignment_repo_name-collaborator_slug" do
      expect(exercise.default_repo_name).to eq("#{assignment.slug}-#{student.github_user.login}")
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
    it "is expected to return 'user'" do
      expect(exercise.humanize).to eq("user")
    end
  end

  describe "#stat_prefix" do
    it "is expected to return 'exercise_repo'" do
      expect(exercise.stat_prefix).to eq("exercise_repo")
    end
  end

  describe "#slug" do
    it "is expected to get login from github" do
      expect(exercise.collaborator).to receive_message_chain("github_user.login").with(use_cache: false)
      exercise.slug
    end
  end

  describe "#repos" do
    it "is expected to be a AssignmentRepo::ActiveRecord_Associations_CollectionProxy" do
      expect(exercise.repos).to be_an_instance_of(assignment.assignment_repos.class)
    end

    it "should be assignment.assignment_repos" do
      expect(exercise.repos).to eq(assignment.assignment_repos)
    end
  end
end

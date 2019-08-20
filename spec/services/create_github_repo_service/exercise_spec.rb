# frozen_string_literal: true

require "rails_helper"

RSpec.describe CreateGitHubRepoService::Exercise do
  let(:exercise) { described_class.new(assignment, student) }

  describe ".build" do
    let(:assignment) do
      double(
        organization: double(github_organization: double),
        invitation: double(status: double),
        starter_code?: false
      )
    end

    it "builds a Individual if collaborator is a user" do
      collaborator = double("is_a?": true)
      expect(described_class.build(assignment, collaborator))
        .to be_an_instance_of(CreateGitHubRepoService::IndividualExercise)
    end

    it "builds a Team if collaborator is a group" do
      collaborator = double("is_a?": false)
      expect(described_class.build(assignment, collaborator))
        .to be_an_instance_of(CreateGitHubRepoService::GroupExercise)
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
    let(:exercise) { described_class.new(assignment, student) }

    it "is the organization login name" do
      expect(exercise.organization_login).to eq(organization.github_organization.login)
    end
  end

  describe "#github_organization_with_access", :vcr do
    let(:client) { oauth_client }
    let(:organization) { classroom_org }
    let(:github_organization) { organization.github_organization }
    let(:teacher)      { classroom_teacher }
    let(:student)      { classroom_student }
    let(:assignment) do
      options = {
        title: "Learn Elm",
        organization: organization,
        students_are_repo_admins: true,
        public_repo: true
      }
      build(:assignment, options)
    end
    let(:exercise) { described_class.new(assignment, student) }

    before(:each) do
      assignment.update(starter_code_repo_id: github_repository.id)
    end

    after(:each) do
      teacher.github_client.delete_repository(github_repository.id)
    end

    context "repository is public" do
      let(:github_repository) do
        options = { private: false, is_template: true, auto_init: true }
        github_organization.create_repository("#{Faker::Company.name} Public Template", options)
      end

      it "uses Organization#github_organization" do
        exercise = described_class.new(assignment, student)
        expect(exercise.github_organization).to eql(github_organization)
      end
    end

    context "repository is private" do
      context "repository belongs to classroom organization" do
        let(:github_repository) do
          options = { private: true, is_template: true, auto_init: true }
          github_organization.create_repository("#{Faker::Company.name} Private Template on Org", options)
        end

        it "uses Organization#github_organization" do
          exercise = described_class.new(assignment, student)
          expect(exercise.github_organization).to eql(github_organization)
        end
      end

      context "repository does not belong to classroom organization" do
        let(:github_repository) do
          options = { private: true, is_template: true, auto_init: true }
          teacher.github_client.create_repository("#{Faker::Company.name} Private Template on User", options)
        end

        it "uses a new GitHubOrganization with the assignment creator's token" do
          exercise = described_class.new(assignment, student)
          expect(exercise.github_organization).not_to eql(github_organization)
          expect(exercise.github_organization.access_token).to eql(assignment.creator.github_client.access_token)
        end
      end
    end
  end
end

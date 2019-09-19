# frozen_string_literal: true

require "rails_helper"

RSpec.describe CreateGitHubRepoService::Exercise do
  let(:exercise) { described_class.new(assignment, student) }

  describe ".build" do
    let(:assignment) { double(organization: double, invitation: double(status: double)) }

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
end

# frozen_string_literal: true

require "rails_helper"

# This exception initializer crashes if it isn't thrown from the serializer...
# so let's override it.
module ActiveJob
  class DeserializationError
    def initialize; end
  end
end

RSpec.describe Organization::ClassroomVisibilityJob, type: :job do
  subject { Organization::ClassroomVisibilityJob }

  let(:organization) { classroom_org }
  let(:client) { oauth_client }
  let(:teacher) { classroom_teacher }
  let(:student) { classroom_student }
  let(:assignment_repo) { create(:assignment_repo, user: user, assignment: invitation.assignment) }

  describe "#perform", :vcr do
    before(:each) do
      3.times do |i|
        assignment = create(
          :assignment,
          title: "Assignment #{i}",
          public_repo: false,
          organization: organization
        )
        AssignmentRepo::Creator.perform(assignment: assignment, user: student)
        AssignmentRepo::Creator.perform(assignment: assignment, user: teacher)
        organization.assignments << assignment
      end
    end

    after(:each) do
      organization.assignments.each do |assignment|
        assignment.repos.each do |assignment_repo|
          organization.github_organization.delete_repository(assignment_repo.github_repo_id)
        end
      end
    end

    it "changes the visibility of all assignments and their repositories" do
      subject.perform_now(organization, "public")
      expect(organization.assignments).to all(have_attributes(public_repo: true))
      organization.assignments.each do |assignment|
        assignment.repos.each do |assignment_repo|
          expect(client.repository(assignment_repo.github_repo_id).private).to be false
        end
      end
    end

    context "classroom has a deleted repository" do
      before do
        organization.github_organization.delete_repository(organization.assignments.first.repos.first.github_repo_id)
      end

      it "does not fail" do
        expect { subject.perform_now(organization, "public") }.not_to raise_error
      end
    end
  end
end

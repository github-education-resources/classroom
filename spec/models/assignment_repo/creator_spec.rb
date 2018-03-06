# frozen_string_literal: true

require "rails_helper"

RSpec.describe AssignmentRepo::Creator, type: :model do
  let(:organization) { classroom_org }
  let(:student)      { classroom_student }
  let(:teacher)      { classroom_teacher }

  let(:assignment) do
    options = {
      title: "Learn Elm",
      starter_code_repo_id: 1_062_897,
      organization: organization,
      students_are_repo_admins: true
    }

    create(:assignment, options)
  end

  describe "::perform", :vcr do
    describe "successful creation" do
      after(:each) do
        AssignmentRepo.destroy_all
      end

      it "creates an AssignmentRepo as an outside_collaborator" do
        result = AssignmentRepo::Creator.perform(assignment: assignment, user: student)

        expect(result.success?).to be_truthy
        expect(result.assignment_repo.assignment).to eql(assignment)
        expect(result.assignment_repo.user).to eql(student)
      end

      it "creates an AssignmentRepo as a member" do
        result = AssignmentRepo::Creator.perform(assignment: assignment, user: teacher)

        expect(result.success?).to be_truthy
        expect(result.assignment_repo.assignment).to eql(assignment)
        expect(result.assignment_repo.user).to eql(teacher)
      end

      it "tracks the how long it too to be created" do
        expect(GitHubClassroom.statsd).to receive(:timing)
        AssignmentRepo::Creator.perform(assignment: assignment, user: student)
      end

      context "github repository with the same name already exists" do
        before do
          result = AssignmentRepo::Creator.perform(assignment: assignment, user: student)
          assignment_repo = result.assignment_repo

          @original_repository = organization.github_client.repository(assignment_repo.github_repo_id)
          assignment_repo.delete
        end

        after do
          organization.github_client.delete_repository(@original_repository.id)
          AssignmentRepo.destroy_all
        end

        it "new repository name has expected suffix" do
          AssignmentRepo::Creator.perform(assignment: assignment, user: student)
          expect(WebMock).to have_requested(:post, github_url("/organizations/#{organization.github_id}/repos"))
            .with(body: /^.*#{@original_repository.name}-1.*$/)
        end
      end
    end

    describe "unsuccessful creation" do
      it "fails when the repository could not be created" do
        stub_request(:post, github_url("/organizations/#{organization.github_id}/repos"))
          .to_return(body: "{}", status: 401)

        result = AssignmentRepo::Creator.perform(assignment: assignment, user: student)

        expect(result.failed?).to be_truthy
        expect(result.error).to eql(AssignmentRepo::Creator::REPOSITORY_CREATION_FAILED)
      end

      context "with a successful repository creation" do
        # Verify that we try to delete the GitHub repository
        # if part of the process fails.
        after(:each) do
          regex = %r{#{github_url("/repositories")}/\d+$}
          expect(WebMock).to have_requested(:delete, regex)
        end

        it "fails when the starter code could not be imported" do
          # https://developer.github.com/v3/migration/source_imports/#start-an-import
          import_regex = %r{#{github_url("/repositories/")}\d+/import$}
          stub_request(:put, import_regex).to_return(body: "{}", status: 401)

          result = AssignmentRepo::Creator.perform(assignment: assignment, user: student)

          expect(result.failed?).to be_truthy
          expect(result.error).to eql(AssignmentRepo::Creator::REPOSITORY_STARTER_CODE_IMPORT_FAILED)
          expect(WebMock).to have_requested(:put, import_regex)
        end

        it "fails when the user could not be added to the repo" do
          # https://developer.github.com/v3/repos/collaborators/#add-user-as-a-collaborator
          repo_invitation_regex = %r{#{github_url("/repositories/")}\d+/collaborators/.+$}
          stub_request(:put, repo_invitation_regex).to_return(body: "{}", status: 401)

          result = AssignmentRepo::Creator.perform(assignment: assignment, user: student)

          expect(result.failed?).to be_truthy
          expect(result.error).to eql(AssignmentRepo::Creator::REPOSITORY_COLLABORATOR_ADDITION_FAILED)
          expect(WebMock).to have_requested(:put, repo_invitation_regex)
        end

        it "fails when the AssignmentRepo object could not be created" do
          allow_any_instance_of(AssignmentRepo).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)

          result = AssignmentRepo::Creator.perform(assignment: assignment, user: student)

          expect(result.failed?).to be_truthy
          expect(result.error).to eql(AssignmentRepo::Creator::DEFAULT_ERROR_MESSAGE)
        end
      end
    end
  end
end

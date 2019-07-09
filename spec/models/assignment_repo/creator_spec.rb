# frozen_string_literal: true

require "rails_helper"

RSpec.describe AssignmentRepo::Creator, type: :model do
  subject            { described_class }
  let(:organization) { classroom_org }
  let(:student)      { classroom_student }
  let(:teacher)      { classroom_teacher }

  let(:assignment) do
    options = {
      title: "Learn Elm",
      starter_code_repo_id: 1_062_897,
      organization: organization,
      students_are_repo_admins: true,
      public_repo: false
    }

    create(:assignment, options)
  end

  describe "#verify_organization_has_private_repos_available!", :vcr do
    let(:creator) { subject.new(assignment: assignment, user: student) }

    context "organization has private repos" do
      it "returns true" do
        allow_any_instance_of(GitHubOrganization)
          .to receive(:plan)
          .and_return(
            owned_private_repos: 1,
            private_repos: 2
          )
        expect(creator.verify_organization_has_private_repos_available!).to eq(true)
      end
    end

    context "organization plan can't be found" do
      before do
        expect_any_instance_of(GitHubOrganization)
          .to receive(:plan)
          .and_raise(GitHub::Error, "Cannot retrieve this organizations repo plan, please reauthenticate your token.")
      end

      it "raises a Result::Error" do
        expect { creator.verify_organization_has_private_repos_available! }
          .to raise_error(
            GitHub::Error,
            "Cannot retrieve this organizations repo plan, please reauthenticate your token."
          )
      end
    end

    context "organization plan limit reached" do
      before do
        expect_any_instance_of(GitHubOrganization)
          .to receive(:plan)
          .and_return(
            owned_private_repos: 1,
            private_repos: 1
          )
      end

      it "raises a Result::Error" do
        expect { creator.verify_organization_has_private_repos_available! }
          .to raise_error(GitHub::Error)
      end
    end
  end

  describe "::perform", :vcr do
    describe "successful creation" do
      let(:assignment) do
        options = {
          title: "Learn Elm",
          starter_code_repo_id: 1_062_897,
          organization: organization,
          students_are_repo_admins: true,
          public_repo: true
        }

        create(:assignment, options)
      end

      after(:each) do
        AssignmentRepo.destroy_all
      end

      it "creates an AssignmentRepo as an outside_collaborator" do
        result = AssignmentRepo::Creator.perform(assignment: assignment, user: student)

        expect(result.success?).to be_truthy
        expect(result.assignment_repo.assignment).to eql(assignment)
        expect(result.assignment_repo.user).to eql(student)
        expect(result.assignment_repo.github_global_relay_id).to be_truthy
      end

      it "creates an AssignmentRepo as a member" do
        result = AssignmentRepo::Creator.perform(assignment: assignment, user: teacher)

        expect(result.success?).to be_truthy
        expect(result.assignment_repo.assignment).to eql(assignment)
        expect(result.assignment_repo.user).to eql(teacher)
        expect(result.assignment_repo.github_global_relay_id).to be_truthy
      end

      it "tracks the how long it too to be created" do
        expect(GitHubClassroom.statsd).to receive(:timing).with("exercise_repo.create.time", anything)
        expect(GitHubClassroom.statsd).to receive(:timing).with("v2_exercise_repo.create.time", anything)
        AssignmentRepo::Creator.perform(assignment: assignment, user: student)
      end

      it "tracks create success stat" do
        expect(GitHubClassroom.statsd).to receive(:increment).with("exercise_repo.import.started")
        expect(GitHubClassroom.statsd).to receive(:increment).with("v2_exercise_repo.create.success")
        expect(GitHubClassroom.statsd).to receive(:increment).with("exercise_repo.create.success")
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
      let(:assignment) do
        options = {
          title: "Learn Elm",
          starter_code_repo_id: 1_062_897,
          organization: organization,
          students_are_repo_admins: true,
          public_repo: true
        }

        create(:assignment, options)
      end

      it "fails when the repository could not be created" do
        stub_request(:post, github_url("/organizations/#{organization.github_id}/repos"))
          .to_return(body: "{}", status: 401)

        result = AssignmentRepo::Creator.perform(assignment: assignment, user: student)

        expect(result.failed?).to be_truthy
        expect(result.error).to start_with(AssignmentRepo::Creator::REPOSITORY_CREATION_FAILED)
      end

      it "tracks create fail stat" do
        stub_request(:post, github_url("/organizations/#{organization.github_id}/repos"))
          .to_return(body: "{}", status: 401)

        expect(GitHubClassroom.statsd).to receive(:increment).with("github.error.Unauthorized")
        expect(GitHubClassroom.statsd).to receive(:increment).with("exercise_repo.create.fail")
        AssignmentRepo::Creator.perform(assignment: assignment, user: student)
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
          expect(result.error).to start_with(AssignmentRepo::Creator::REPOSITORY_STARTER_CODE_IMPORT_FAILED)
          expect(WebMock).to have_requested(:put, import_regex)
        end

        it "fails when the user could not be added to the repo" do
          # https://developer.github.com/v3/repos/collaborators/#add-user-as-a-collaborator
          repo_invitation_regex = %r{#{github_url("/repositories/")}\d+/collaborators/.+$}
          stub_request(:put, repo_invitation_regex).to_return(body: "{}", status: 401)

          result = AssignmentRepo::Creator.perform(assignment: assignment, user: student)

          expect(result.failed?).to be_truthy
          expect(result.error).to start_with(AssignmentRepo::Creator::REPOSITORY_COLLABORATOR_ADDITION_FAILED)
          expect(WebMock).to have_requested(:put, repo_invitation_regex)
        end

        it "fails when the AssignmentRepo object could not be created" do
          allow_any_instance_of(AssignmentRepo).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)

          result = AssignmentRepo::Creator.perform(assignment: assignment, user: student)

          expect(result.failed?).to be_truthy
          expect(result.error).to start_with(AssignmentRepo::Creator::DEFAULT_ERROR_MESSAGE)
        end
      end
    end
  end
end

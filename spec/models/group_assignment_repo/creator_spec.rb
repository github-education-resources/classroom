# frozen_string_literal: true

require "rails_helper"

RSpec.describe GroupAssignmentRepo::Creator do
  subject              { described_class }
  let(:organization)   { classroom_org }
  let(:student)        { classroom_student }
  let(:teacher)        { classroom_teacher }
  let(:repo_access)    { RepoAccess.create(user: student, organization: organization) }
  let(:grouping)       { create(:grouping, organization: organization) }
  let(:github_team_id) { organization.github_organization.create_team(Faker::Team.name[0..39]).id }
  let(:group)          { create(:group, grouping: grouping, github_team_id: github_team_id) }
  let(:group_assignment) do
    create(
      :group_assignment,
      grouping: grouping,
      title: "Learn JavaScript",
      organization: organization,
      public_repo: true,
      starter_code_repo_id: 1_062_897
    )
  end
  let(:group_repo_channel) { GroupRepositoryCreationStatusChannel }
  let(:channel) { group_repo_channel.channel(group_assignment_id: group_assignment.id, group_id: group.id) }

  describe "#verify_organization_has_private_repos_available!", :vcr do
    before(:each) do
      group_assignment.invitation.status(group).waiting!
    end
    let(:creator) { subject.new(group_assignment: group_assignment, group: group) }
    context "organization has private repos" do
      it "returns true" do
        expect(creator.verify_organization_has_private_repos_available!).to eq(true)
      end
    end

    context "organization plan can't be found" do
      before do
        expect_any_instance_of(GitHubOrganization)
          .to receive(:plan)
          .and_raise(GitHub::Error, "Cannot retrieve this organizations repo plan, please reauthenticate your token.")
        creator.group_assignment.public_repo = false
      end

      after do
        creator.group_assignment.public_repo = true
      end

      it "raises a Result::Error" do
        expect { creator.verify_organization_has_private_repos_available! }
          .to raise_error(
            subject::Result::Error,
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
        creator.group_assignment.public_repo = false
      end

      after do
        creator.group_assignment.public_repo = true
      end

      it "raises a Result::Error" do
        expect { creator.verify_organization_has_private_repos_available! }
          .to raise_error(subject::Result::Error)
      end
    end
  end

  describe "::perform", :vcr do
    before(:each) do
      group_assignment.invitation.status(group).waiting!
    end
    describe "successful creation" do
      after(:each) do
        GroupAssignmentRepo.destroy_all
      end

      it "creates a GroupAssignmentRepo with a group" do
        result = GroupAssignmentRepo::Creator.perform(group_assignment: group_assignment, group: group)

        expect(result.success?).to be_truthy
        expect(result.group_assignment_repo.group_assignment).to eql(group_assignment)
        expect(result.group_assignment_repo.group).to eql(group)
        expect(result.group_assignment_repo.github_global_relay_id).to be_truthy
      end

      it "tracks the how long it too to be created" do
        expect(GitHubClassroom.statsd).to receive(:timing)
        GroupAssignmentRepo::Creator.perform(group_assignment: group_assignment, group: group)
      end

      it "tracks create success stat" do
        expect(GitHubClassroom.statsd).to receive(:increment).with("v2_group_exercise_repo.create.success")
        expect(GitHubClassroom.statsd).to receive(:increment).with("group_exercise_repo.create.success")
        expect(GitHubClassroom.statsd).to receive(:increment).with("group_exercise_repo.import.started")
        expect(GitHubClassroom.statsd).to receive(:increment).with("exercise_repo.create.success")
        GroupAssignmentRepo::Creator.perform(group_assignment: group_assignment, group: group)
      end

      context "github repository with the same name already exists" do
        before do
          @result = GroupAssignmentRepo::Creator.perform(group_assignment: group_assignment, group: group)
          group_assignment_repo = @result.group_assignment_repo

          @original_repository = organization.github_client.repository(group_assignment_repo.github_repo_id)
          group_assignment_repo.delete
        end

        after do
          organization.github_client.delete_repository(@original_repository.id)
          GroupAssignmentRepo.destroy_all
        end

        it "new repository name has expected suffix" do
          GroupAssignmentRepo::Creator.perform(group_assignment: group_assignment, group: group)
          expect(WebMock).to have_requested(:post, github_url("/organizations/#{organization.github_id}/repos"))
            .with(body: /^.*#{@original_repository.name}-1.*$/)
        end
      end
      describe "broadcasts" do
        it "creating_repo" do
          expect { subject.perform(group_assignment: group_assignment, group: group) }
            .to have_broadcasted_to(channel)
            .with(text: subject::CREATE_REPO, status: "creating_repo", repo_url: nil)
        end

        it "importing_starter_code" do
          slug = group.github_team.slug
          expect { subject.perform(group_assignment: group_assignment, group: group) }
            .to have_broadcasted_to(channel)
            .with(
              text: subject::IMPORT_STARTER_CODE,
              status: "importing_starter_code",
              repo_url: "https://github.com/#{organization.github_organization.login}/learn-javascript-#{slug}"
            )
        end
      end
    end

    describe "unsuccessful creation" do
      it "fails when the repository could not be created" do
        stub_request(:post, github_url("/organizations/#{organization.github_id}/repos"))
          .to_return(body: "{}", status: 401)

        result = GroupAssignmentRepo::Creator.perform(group_assignment: group_assignment, group: group)

        expect(result.failed?).to be_truthy
        expect(result.error).to start_with(GroupAssignmentRepo::Creator::REPOSITORY_CREATION_FAILED)
      end

      it "tracks create fail stat" do
        stub_request(:post, github_url("/organizations/#{organization.github_id}/repos"))
          .to_return(body: "{}", status: 401)

        expect(GitHubClassroom.statsd).to receive(:increment).with("github.error.Unauthorized")
        expect(GitHubClassroom.statsd).to receive(:increment).with("exercise_repo.create.fail")
        GroupAssignmentRepo::Creator.perform(group_assignment: group_assignment, group: group)
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

          result = GroupAssignmentRepo::Creator.perform(group_assignment: group_assignment, group: group)

          expect(result.failed?).to be_truthy
          expect(result.error).to start_with(GroupAssignmentRepo::Creator::REPOSITORY_STARTER_CODE_IMPORT_FAILED)
          expect(WebMock).to have_requested(:put, import_regex)
        end

        it "fails when the team could not be added to the repo" do
          # https://developer.github.com/v3/repos/collaborators/#add-user-as-a-collaborator
          USERNAME_REGEX = GitHub::USERNAME_REGEX
          REPOSITORY_REGEX = GitHub::REPOSITORY_REGEX
          regex = %r{#{github_url("/teams/#{group.github_team_id}/repos/")}#{USERNAME_REGEX}\/#{REPOSITORY_REGEX}$}
          stub_request(:put, regex).to_return(body: "{}", status: 401)

          result = GroupAssignmentRepo::Creator.perform(group_assignment: group_assignment, group: group)

          expect(result.failed?).to be_truthy
          expect(result.error).to start_with(GroupAssignmentRepo::Creator::REPOSITORY_TEAM_ADDITION_FAILED)
          expect(WebMock).to have_requested(:put, regex)
        end

        it "fails when the GroupAssignmentRepo object could not be created" do
          allow_any_instance_of(GroupAssignmentRepo).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)

          result = GroupAssignmentRepo::Creator.perform(group_assignment: group_assignment, group: group)

          expect(result.failed?).to be_truthy
          expect(result.error).to start_with(GroupAssignmentRepo::Creator::DEFAULT_ERROR_MESSAGE)
        end
      end
    end
  end
end

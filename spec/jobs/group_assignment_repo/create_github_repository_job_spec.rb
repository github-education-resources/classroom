# frozen_string_literal: true

require "rails_helper"

RSpec.describe GroupAssignmentRepo::CreateGitHubRepositoryJob, type: :job do
  include ActiveJob::TestHelper

  subject { described_class }

  # TODO: Implement GroupAssignmentRepo::PorterStatusJob (follow up PR)
  #
  # let(:cascading_job)      { GroupAssignmentRepo::PorterStatusJob }
  let(:group_repo_channel) { GroupRepositoryCreationStatusChannel }

  context "with created objects", :vcr do
    let(:organization)  { classroom_org }
    let(:student)       { classroom_student }
    let(:repo_access)   { RepoAccess.create(user: student, organization: organization) }
    let(:grouping)      { create(:grouping, organization: organization) }
    let(:group)         { Group.create(title: "Group 1", grouping: grouping) }
    let(:invite_status) { group_assignment.invitation.status(group) }
    let(:group_assignment) do
      group_assignment = create(
        :group_assignment,
        grouping: grouping,
        title: "Learn JavaScript",
        organization: organization,
        public_repo: true,
        starter_code_repo_id: 1_062_897
      )
      group_assignment.build_group_assignment_invitation
      group_assignment
    end

    after(:each) do
      RepoAccess.destroy_all
      GroupAssignmentRepo.destroy_all
      Group.destroy_all
      GroupAssignmentInvitation.destroy_all
      GroupAssignment.destroy_all
      clear_enqueued_jobs
      clear_performed_jobs
    end

    it "uses the create_repository queue" do
      subject.perform_later
      expect(subject).to have_been_enqueued.on_queue("create_repository")
    end

    context "invalid invitation status" do
      before(:each) do
        group.repo_accesses << repo_access
      end

      after(:each) do
        expect_any_instance_of(subject).to_not receive(:broadcast_message)
        subject.perform_now(group_assignment, group)
        expect { GroupAssignmentRepo.find_by!(group_assignment: group_assignment, group: group) }
          .to raise_error(ActiveRecord::RecordNotFound)
      end

      it "returns early when invitation status is unaccepted" do
        invite_status.unaccepted!
      end

      it "returns early when invitation status is accepted" do
        invite_status.accepted!
      end

      it "returns early when invitation status is creating_repo" do
        invite_status.creating_repo!
      end

      it "returns early when invitation status is importing_starter_code" do
        invite_status.importing_starter_code!
      end

      it "returns early when invitation status is errored_creating_repo" do
        invite_status.errored_creating_repo!
      end

      it "returns early when invitation status is errored_importing_starter_code" do
        invite_status.errored_importing_starter_code!
      end
    end

    context "valid invitation status" do
      before(:each) do
        group.repo_accesses << repo_access
        invite_status.waiting!
      end

      describe "successful creation" do
        let(:assignment_repo) { GroupAssignmentRepo.find_by!(group_assignment: group_assignment, group: group) }

        before do
          subject.perform_now(group_assignment, group)
        end

        it "changes the invite_status" do
          expect(invite_status.status).to_not eq(invite_status.reload.status)
        end

        it "group_assignment_repo not nil" do
          expect(assignment_repo.nil?).to be_falsy
        end

        it "is the same assignment" do
          expect(assignment_repo.assignment).to eql(group_assignment)
        end

        it "has the same group" do
          expect(assignment_repo.group).to eql(group)
        end

        it "created a GitHub repository" do
          expect(WebMock).to have_requested(:post, github_url("/organizations/#{organization.github_id}/repos"))
        end

        it "started a source import" do
          expect(WebMock).to have_requested(:put, github_url("/repositories/#{assignment_repo.github_repo_id}/import"))
        end

        it "added the team to the repository" do
          repo_name = assignment_repo.github_repository.full_name
          expect(WebMock).to have_requested(:put, github_url("/teams/#{group.github_team_id}/repos/#{repo_name}"))
        end

        # TODO: Implement GroupAssignmentRepo::PorterStatusJob (follow up PR)
        #
        # it "kicks off a cascading porter status job" do
        #   expect(cascading_job).to have_been_enqueued.on_queue("porter_status")
        # end
      end

      describe "successful creation" do
        it "broadcasts creating_repo" do
          expect { subject.perform_now(group_assignment, group) }
            .to have_broadcasted_to(group_repo_channel.channel(group_assignment_id: group_assignment.id, group_id: group.id))
            .with(
              text: subject::CREATE_REPO,
              status: "creating_repo"
            )
        end

        it "broadcasts importing_starter_code" do
          expect { subject.perform_now(group_assignment, group) }
            .to have_broadcasted_to(group_repo_channel.channel(group_assignment_id: group_assignment.id, group_id: group.id))
            .with(
              text: subject::IMPORT_STARTER_CODE,
              status: "importing_starter_code"
            )
        end

        describe "datadog stats" do
          after do
            subject.perform_now(group_assignment, group)
          end

          it "tracks create success" do
            expect(GitHubClassroom.statsd).to receive(:increment).with("v2_group_exercise_repo.create.success")
          end

          it "tracks elapsed time" do
            expect(GitHubClassroom.statsd).to receive(:timing)
          end
        end
      end
    end

    #   context "creates an GroupAssignmentRepo as an outside_collaborator" do
    #     before do
    #       subject.perform_now(assignment, student)
    #     end

    #     it "is not nil" do
    #       result = assignment.assignment_repos.first
    #       expect(result.nil?).to be_falsy
    #     end

    #     it "is the same assignment" do
    #       result = assignment.assignment_repos.first
    #       expect(result.assignment).to eql(assignment)
    #     end

    #     it "has the same user" do
    #       result = assignment.assignment_repos.first
    #       expect(result.user).to eql(student)
    #     end
    #   end

    #   context "creates an GroupAssignmentRepo as a member" do
    #     before do
    #       subject.perform_now(assignment, teacher)
    #     end

    #     it "is not nil" do
    #       result = assignment.assignment_repos.first
    #       expect(result.nil?).to be_falsy
    #     end

    #     it "is the same assignment" do
    #       result = assignment.assignment_repos.first
    #       expect(result.assignment).to eql(assignment)
    #     end

    #     it "has the same user" do
    #       result = assignment.assignment_repos.first
    #       expect(result.user).to eql(teacher)
    #     end
    #   end

    #   it "broadcasts status on channel" do
    #     expect { subject.perform_now(assignment, teacher) }
    #       .to have_broadcasted_to(RepositoryCreationStatusChannel.channel(user_id: teacher.id))
    #       .with(
    #         text: GroupAssignmentRepo::CreateGitHubRepositoryJob::CREATE_REPO,
    #         status: "creating_repo"
    #       )
    #       .with(
    #         text: GroupAssignmentRepo::CreateGitHubRepositoryJob::IMPORT_STARTER_CODE,
    #         status: "importing_starter_code"
    #       )
    #   end

    #   it "tracks create fail stat" do
    #     expect(GitHubClassroom.statsd).to receive(:increment).with("v2_exercise_repo.create.success")
    #     subject.perform_now(assignment, teacher)
    #   end

    #   it "tracks how long it too to be created" do
    #     expect(GitHubClassroom.statsd).to receive(:timing)
    #     subject.perform_now(assignment, teacher)
    #   end
    # end

    # describe "failure", :vcr do
    #   it "tracks create fail stat" do
    #     stub_request(:post, github_url("/organizations/#{organization.github_id}/repos"))
    #       .to_return(body: "{}", status: 401)

    #     expect(GitHubClassroom.statsd).to receive(:increment).with("v2_exercise_repo.create.repo.fail")
    #     subject.perform_now(assignment, student)
    #   end

    #   it "broadcasts create repo failure" do
    #     stub_request(:post, github_url("/organizations/#{organization.github_id}/repos"))
    #       .to_return(body: "{}", status: 401)

    #     expect { subject.perform_now(assignment, student) }
    #       .to have_broadcasted_to(RepositoryCreationStatusChannel.channel(user_id: student.id))
    #       .with(
    #         text: GroupAssignmentRepo::CreateGitHubRepositoryJob::CREATE_REPO,
    #         status: "creating_repo"
    #       )
    #       .with(
    #         error: GroupAssignmentRepo::Creator::REPOSITORY_CREATION_FAILED,
    #         status: "errored_creating_repo"
    #       )
    #   end

    #   it "fails and automatically retries" do
    #     import_regex = %r{#{github_url("/repositories/")}\d+/import$}
    #     stub_request(:put, import_regex)
    #       .to_return(body: "{}", status: 401)

    #     expect(subject).to receive(:perform_later).with(assignment, teacher, retries: 0)
    #     subject.perform_now(assignment, teacher, retries: 1)
    #   end

    #   it "fails and puts invite status in state to retry" do
    #     import_regex = %r{#{github_url("/repositories/")}\d+/import$}
    #     stub_request(:put, import_regex)
    #       .to_return(body: "{}", status: 401)

    #     subject.perform_now(assignment, teacher, retries: 1)
    #     expect(@teacher_invite_status.reload.waiting?).to be_truthy
    #   end

    #   context "with successful repo creation" do
    #     # Verify that we try to delete the GitHub repository
    #     # if part of the process fails.
    #     after(:each) do
    #       regex = %r{#{github_url("/repositories")}/\d+$}
    #       expect(WebMock).to have_requested(:delete, regex)
    #     end

    #     it "fails to import starter code and broadcasts" do
    #       import_regex = %r{#{github_url("/repositories/")}\d+/import$}
    #       stub_request(:put, import_regex)
    #         .to_return(body: "{}", status: 401)

    #       expect { subject.perform_now(assignment, student) }
    #         .to have_broadcasted_to(RepositoryCreationStatusChannel.channel(user_id: student.id))
    #         .with(
    #           text: GroupAssignmentRepo::CreateGitHubRepositoryJob::CREATE_REPO,
    #           status: "creating_repo"
    #         )
    #         .with(
    #           error: GroupAssignmentRepo::Creator::REPOSITORY_STARTER_CODE_IMPORT_FAILED,
    #           status: "errored_creating_repo"
    #         )
    #     end

    #     it "fails to import starter code and logs" do
    #       import_regex = %r{#{github_url("/repositories/")}\d+/import$}
    #       stub_request(:put, import_regex)
    #         .to_return(body: "{}", status: 401)

    #       expect(Rails.logger)
    #         .to receive(:warn)
    #         .with(GroupAssignmentRepo::Creator::REPOSITORY_STARTER_CODE_IMPORT_FAILED)
    #       subject.perform_now(assignment, student)
    #     end

    #     it "fails to import starter code and reports" do
    #       import_regex = %r{#{github_url("/repositories/")}\d+/import$}
    #       stub_request(:put, import_regex)
    #         .to_return(body: "{}", status: 401)

    #       expect(GitHubClassroom.statsd)
    #         .to receive(:increment)
    #         .with("v2_exercise_repo.create.importing_starter_code.fail")
    #       subject.perform_now(assignment, student)
    #     end

    #     it "fails to add the user to the repo and broadcasts" do
    #       repo_invitation_regex = %r{#{github_url("/repositories/")}\d+/collaborators/.+$}
    #       stub_request(:put, repo_invitation_regex)
    #         .to_return(body: "{}", status: 401)

    #       expect { subject.perform_now(assignment, student) }
    #         .to have_broadcasted_to(RepositoryCreationStatusChannel.channel(user_id: student.id))
    #         .with(
    #           text: GroupAssignmentRepo::CreateGitHubRepositoryJob::CREATE_REPO,
    #           status: "creating_repo"
    #         )
    #         .with(
    #           error: GroupAssignmentRepo::Creator::REPOSITORY_COLLABORATOR_ADDITION_FAILED,
    #           status: "errored_creating_repo"
    #         )
    #     end

    #     it "fails to add the user to the repo and logs" do
    #       repo_invitation_regex = %r{#{github_url("/repositories/")}\d+/collaborators/.+$}
    #       stub_request(:put, repo_invitation_regex)
    #         .to_return(body: "{}", status: 401)

    #       expect(Rails.logger)
    #         .to receive(:warn)
    #         .with(GroupAssignmentRepo::Creator::REPOSITORY_COLLABORATOR_ADDITION_FAILED)
    #       subject.perform_now(assignment, student)
    #     end

    #     it "fails to add the user to the repo and reports" do
    #       repo_invitation_regex = %r{#{github_url("/repositories/")}\d+/collaborators/.+$}
    #       stub_request(:put, repo_invitation_regex)
    #         .to_return(body: "{}", status: 401)

    #       expect(GitHubClassroom.statsd)
    #         .to receive(:increment)
    #         .with("v2_exercise_repo.create.adding_collaborator.fail")
    #       subject.perform_now(assignment, student)
    #     end

    #     it "fails to save the GroupAssignmentRepo and broadcasts" do
    #       allow_any_instance_of(GroupAssignmentRepo).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)

    #       expect { subject.perform_now(assignment, student) }
    #         .to have_broadcasted_to(RepositoryCreationStatusChannel.channel(user_id: student.id))
    #         .with(
    #           text: GroupAssignmentRepo::CreateGitHubRepositoryJob::CREATE_REPO,
    #           status: "creating_repo"
    #         )
    #         .with(
    #           error: GroupAssignmentRepo::Creator::DEFAULT_ERROR_MESSAGE,
    #           status: "errored_creating_repo"
    #         )
    #     end

    #     it "fails to save the GroupAssignmentRepo and logs" do
    #       allow_any_instance_of(GroupAssignmentRepo).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)

    #       expect(Rails.logger)
    #         .to receive(:warn)
    #         .with("Record invalid")
    #       expect(Rails.logger)
    #         .to receive(:warn)
    #         .with(GroupAssignmentRepo::Creator::DEFAULT_ERROR_MESSAGE)
    #       subject.perform_now(assignment, student)
    #     end

    #     it "fails to save the GroupAssignmentRepo and reports" do
    #       allow_any_instance_of(GroupAssignmentRepo).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)

    #       expect(GitHubClassroom.statsd).to receive(:increment).with("v2_exercise_repo.create.fail")
    #       subject.perform_now(assignment, student)
    #     end
    #   end
    # end
  end
end

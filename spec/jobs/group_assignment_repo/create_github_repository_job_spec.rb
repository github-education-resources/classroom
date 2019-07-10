# frozen_string_literal: true

require "rails_helper"

RSpec.describe GroupAssignmentRepo::CreateGitHubRepositoryJob, type: :job do
  include ActiveJob::TestHelper

  subject { described_class }
  let(:group_repo_channel) { GroupRepositoryCreationStatusChannel }

  context "with created objects", :vcr do
    let(:organization)  { classroom_org }
    let(:student)       { classroom_student }
    let(:repo_access)   { RepoAccess.create(user: student, organization: organization) }
    let(:grouping)      { create(:grouping, organization: organization) }
    let(:github_team_id) { organization.github_organization.create_team(Faker::Team.name).id }
    let(:group)         { create(:group, grouping: grouping, github_team_id: github_team_id) }
    let(:invite_status) { group_assignment.invitation.status(group) }
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
    let(:channel) { group_repo_channel.channel(group_assignment_id: group_assignment.id, group_id: group.id) }

    after(:each) do
      organization.github_organization.delete_team(group.github_team_id)
      GroupAssignmentRepo.destroy_all
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
        expect_any_instance_of(GroupAssignmentRepo::Creator::Reporter).to_not receive(:broadcast_message)
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

        it "changes the invite_status to importing_starter_code" do
          expect(invite_status.reload.status).to eq("importing_starter_code")
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
      end

      describe "successful creation" do
        describe "datadog stats" do
          after do
            subject.perform_now(group_assignment, group)
          end

          it "tracks create success and import started" do
            expect(GitHubClassroom.statsd).to receive(:increment).with("group_exercise_repo.create.success")
            expect(GitHubClassroom.statsd).to receive(:increment).with("exercise_repo.create.success")
            expect(GitHubClassroom.statsd).to receive(:increment).with("v2_group_exercise_repo.create.success")
            expect(GitHubClassroom.statsd).to receive(:increment).with("group_exercise_repo.import.started")
          end

          it "tracks elapsed time" do
            expect(GitHubClassroom.statsd).to receive(:timing)
          end
        end
      end

      describe "context no starter code" do
        describe "successful creation" do
          let(:assignment_repo) { GroupAssignmentRepo.find_by!(group_assignment: group_assignment, group: group) }

          before do
            group_assignment.starter_code_repo_id = nil
            group_assignment.save
            invite_status.waiting!
            subject.perform_now(group_assignment, group)
          end

          after do
            group_assignment.starter_code_repo_id = 1_062_897
            group_assignment.save
          end
          it "changes the invite_status to completed" do
            expect(invite_status.reload.status).to eq("completed")
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
            expect(WebMock)
              .to have_requested(:post, github_url("/organizations/#{organization.github_id}/repos"))
          end

          it "did not start a source import" do
            expect(WebMock)
              .to_not have_requested(:put, github_url("/repositories/#{assignment_repo.github_repo_id}/import"))
          end

          it "added the team to the repository" do
            repo_name = assignment_repo.github_repository.full_name
            expect(WebMock)
              .to have_requested(:put, github_url("/teams/#{group.github_team_id}/repos/#{repo_name}"))
          end
        end

        describe "successful creation" do
          describe "datadog stats" do
            after do
              subject.perform_now(group_assignment, group)
            end

            it "tracks create success" do
              expect(GitHubClassroom.statsd).to receive(:increment).with("group_exercise_repo.create.success")
              expect(GitHubClassroom.statsd).to receive(:increment).with("group_exercise_repo.import.started")
              expect(GitHubClassroom.statsd).to receive(:increment).with("v2_group_exercise_repo.create.success")
              expect(GitHubClassroom.statsd).to receive(:increment).with("exercise_repo.create.success")
            end

            it "tracks elapsed time" do
              expect(GitHubClassroom.statsd).to receive(:timing)
            end
          end
        end
      end

      describe "creation failure" do
        describe "positive retries" do
          before do
            stub_request(:post, github_url("/organizations/#{organization.github_id}/repos"))
              .to_return(status: 500)
          end

          it "fails and automatically retries" do
            expect(subject).to receive(:perform_later).with(group_assignment, group, retries: 0)
            subject.perform_now(group_assignment, group, retries: 1)
          end

          it "fails and puts invite status in state to retry" do
            subject.perform_now(group_assignment, group, retries: 1)
            expect(invite_status.reload.status).to eq("waiting")
          end
        end

        context "fails to create a GitHub repo" do
          before do
            stub_request(:post, github_url("/organizations/#{organization.github_id}/repos"))
              .to_return(status: 500)
          end

          describe "broadcasts" do
            it "creating_repo" do
              expect { subject.perform_now(group_assignment, group) }
                .to have_broadcasted_to(channel)
                .with(text: GroupAssignmentRepo::Creator::CREATE_REPO, status: "creating_repo", repo_url: nil)
            end

            it "errored_creating_repo" do
              expect { subject.perform_now(group_assignment, group) }
                .to have_broadcasted_to(channel)
                .with(
                  hash_including(
                    :error,
                    status: "errored_creating_repo"
                  )
                )
            end
          end

          context "perform before" do
            before do
              subject.perform_now(group_assignment, group)
            end

            it "doesn't create a GroupAssignmentRepo" do
              expect { GroupAssignmentRepo.find_by!(group_assignment: group_assignment, group: group) }
                .to raise_error(ActiveRecord::RecordNotFound)
            end

            it "changes invite_status to be errored_creating_repo" do
              expect(invite_status.reload.errored_creating_repo?).to be_truthy
            end
          end

          context "perform after" do
            after do
              subject.perform_now(group_assignment, group)
            end

            it "tracks create fail" do
              expect(GitHubClassroom.statsd).to receive(:increment).with("group_exercise_repo.create.fail")
              expect(GitHubClassroom.statsd).to receive(:increment).with("github.error.InternalServerError")
              expect(GitHubClassroom.statsd).to receive(:increment).with("exercise_repo.create.fail")
              expect(GitHubClassroom.statsd).to receive(:increment).with("v2_group_exercise_repo.create.fail")
            end

            it "logs error" do
              expect(Rails.logger)
                .to receive(:warn)
                .with(a_string_starting_with(GroupAssignmentRepo::Creator::REPOSITORY_CREATION_FAILED))
            end
          end
        end

        context "fails to start a source import" do
          before do
            stub_request(:put, %r{#{github_url("/repositories")}/\d+/import$})
              .to_return(status: 500)
          end

          describe "broadcasts" do
            it "creating_repo" do
              expect { subject.perform_now(group_assignment, group) }
                .to have_broadcasted_to(channel)
                .with(text: GroupAssignmentRepo::Creator::CREATE_REPO, status: "creating_repo", repo_url: nil)
            end

            it "errored_creating_repo" do
              expect { subject.perform_now(group_assignment, group) }
                .to have_broadcasted_to(channel)
                .with(
                  hash_including(
                    :error,
                    status: "errored_creating_repo"
                  )
                )
            end
          end

          context "perform before" do
            before do
              subject.perform_now(group_assignment, group)
            end

            it "doesn't create a GroupAssignmentRepo" do
              expect { GroupAssignmentRepo.find_by!(group_assignment: group_assignment, group: group) }
                .to raise_error(ActiveRecord::RecordNotFound)
            end

            it "changes invite_status to be errored_creating_repo" do
              expect(invite_status.reload.errored_creating_repo?).to be_truthy
            end
          end

          context "perform after" do
            after do
              subject.perform_now(group_assignment, group)
            end

            it "tracks create fail" do
              expect(GitHubClassroom.statsd).to receive(:increment).with("group_exercise_repo.create.fail")
              expect(GitHubClassroom.statsd).to receive(:increment).with("github.error.InternalServerError")
              expect(GitHubClassroom.statsd).to receive(:increment).with("exercise_repo.create.fail")
              expect(GitHubClassroom.statsd).to receive(:increment).with("v2_group_exercise_repo.create.fail")
            end

            it "logs error" do
              expect(Rails.logger)
                .to receive(:warn)
                .with(a_string_starting_with(GroupAssignmentRepo::Creator::REPOSITORY_STARTER_CODE_IMPORT_FAILED))
            end
          end
        end

        context "fails to add the team to the repository" do
          before do
            username_regex = GitHub::USERNAME_REGEX
            repository_regex = GitHub::REPOSITORY_REGEX
            regex = %r{#{github_url("/teams/#{group.github_team_id}/repos/")}#{username_regex}\/#{repository_regex}$}
            stub_request(:put, regex)
              .to_return(status: 500)
          end

          after(:each) do
            expect(WebMock).to have_requested(:delete, %r{#{github_url("/repositories")}/\d+$})
          end

          describe "broadcasts" do
            it "creating_repo" do
              expect { subject.perform_now(group_assignment, group) }
                .to have_broadcasted_to(channel)
                .with(text: GroupAssignmentRepo::Creator::CREATE_REPO, status: "creating_repo", repo_url: nil)
            end

            it "errored_creating_repo" do
              expect { subject.perform_now(group_assignment, group, retries: 0) }
                .to have_broadcasted_to(channel)
                .with(
                  hash_including(
                    :error,
                    status: "errored_creating_repo"
                  )
                )
            end
          end

          context "perform before" do
            before do
              subject.perform_now(group_assignment, group, retries: 0)
            end

            it "doesn't create a GroupAssignmentRepo" do
              expect { GroupAssignmentRepo.find_by!(group_assignment: group_assignment, group: group) }
                .to raise_error(ActiveRecord::RecordNotFound)
            end

            it "changes invite_status to be errored_creating_repo" do
              expect(invite_status.reload.errored_creating_repo?).to be_truthy
            end
          end

          context "perform after" do
            after do
              subject.perform_now(group_assignment, group)
            end

            it "tracks create fail" do
              expect(GitHubClassroom.statsd).to receive(:increment).with("group_exercise_repo.create.fail")
              expect(GitHubClassroom.statsd).to receive(:increment).with("github.error.InternalServerError")
              expect(GitHubClassroom.statsd).to receive(:increment).with("exercise_repo.create.fail")
              expect(GitHubClassroom.statsd).to receive(:increment).with("v2_group_exercise_repo.create.fail")
            end

            it "logs error" do
              expect(Rails.logger)
                .to receive(:warn)
                .with(a_string_starting_with(GroupAssignmentRepo::Creator::REPOSITORY_TEAM_ADDITION_FAILED))
            end
          end
        end

        context "fails to save the record" do
          before do
            allow_any_instance_of(GroupAssignmentRepo).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
          end

          describe "broadcasts" do
            it "creating_repo" do
              expect { subject.perform_now(group_assignment, group) }
                .to have_broadcasted_to(channel)
                .with(text: GroupAssignmentRepo::Creator::CREATE_REPO, status: "creating_repo", repo_url: nil)
            end

            it "errored_creating_repo" do
              expect { subject.perform_now(group_assignment, group) }
                .to have_broadcasted_to(channel)
                .with(
                  hash_including(
                    :error,
                    status: "errored_creating_repo"
                  )
                )
            end
          end

          context "perform before" do
            before do
              subject.perform_now(group_assignment, group)
            end

            it "doesn't create a GroupAssignmentRepo" do
              expect { GroupAssignmentRepo.find_by!(group_assignment: group_assignment, group: group) }
                .to raise_error(ActiveRecord::RecordNotFound)
            end

            it "changes invite_status to be errored_creating_repo" do
              expect(invite_status.reload.errored_creating_repo?).to be_truthy
            end
          end

          context "perform after" do
            after do
              subject.perform_now(group_assignment, group)
            end

            it "tracks create fail" do
              expect(GitHubClassroom.statsd).to receive(:increment).with("group_exercise_repo.create.fail")
              expect(GitHubClassroom.statsd).to receive(:increment).with("exercise_repo.create.fail")
              expect(GitHubClassroom.statsd).to receive(:increment).with("v2_group_exercise_repo.create.fail")
            end
          end
        end
      end
    end
  end
end

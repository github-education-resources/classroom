# frozen_string_literal: true

require "rails_helper"

RSpec.describe RepositoryImportEventJob, type: :job do
  subject { described_class }

  let(:individual_channel)  { RepositoryCreationStatusChannel.channel(user_id: user.id, assignment_id: assignment.id) }
  let(:group_channel) do
    GroupRepositoryCreationStatusChannel
      .channel(
        group_assignment_id: group_assignment.id,
        group_id: group.id
      )
  end
  let(:success_payload)     { json_payload("webhook_events/repository_import_success.json") }
  let(:failure_payload)     { json_payload("webhook_events/repository_import_failure.json") }
  let(:cancelled_payload)   { json_payload("webhook_events/repository_import_cancelled.json") }
  let(:organization)        { classroom_org }
  let(:user)                { classroom_student }
  let(:grouping)            { create(:grouping, organization: organization) }
  let(:group)               { create(:group, grouping: grouping, github_team_id: 2_977_000) }
  let(:assignment)          { create(:assignment, organization: organization) }
  let(:group_assignment) do
    group_assignment = create(
      :group_assignment,
      organization: organization
    )
    group_assignment.build_group_assignment_invitation
    group_assignment
  end
  let(:invitation)          { assignment.invitation }
  let(:group_invitation)    { group_assignment.invitation }
  let(:invite_status)       { invitation.status(user) }
  let(:group_invite_status) { group_invitation.status(group) }

  context "with created assignment_repo", :vcr do
    let(:assignment_repo) do
      create(
        :assignment_repo,
        assignment: assignment,
        github_repo_id: success_payload.dig("repository", "id"),
        user: user
      )
    end

    before do
      assignment_repo
    end

    after(:each) do
      AssignmentInvitation.destroy_all
      AssignmentRepo.destroy_all
      InviteStatus.destroy_all
      Assignment.destroy_all
    end

    context "with source import success" do
      it "sets invite_status to completed" do
        subject.perform_now(success_payload)
        expect(invite_status.status).to eq("completed")
      end

      it "reports success stat" do
        expect(GitHubClassroom.statsd).to receive(:increment).with("v3_exercise_repo.import.success")
        subject.perform_now(success_payload)
      end

      it "broadcasts completion" do
        expect { subject.perform_now(success_payload) }
          .to have_broadcasted_to(individual_channel)
          .with(
            text: subject::CREATE_COMPLETE,
            status: "completed",
            status_text: "Done"
          )
      end
    end

    context "with source import failure" do
      it "sets invite_status to errored_importing_starter_code" do
        subject.perform_now(failure_payload)
        expect(invite_status.status).to eq("errored_importing_starter_code")
      end

      it "reports failure stat" do
        expect(GitHubClassroom.statsd).to receive(:increment).with("v3_exercise_repo.import.failure")
        subject.perform_now(failure_payload)
      end

      it "broadcasts failure" do
        expect { subject.perform_now(failure_payload) }
          .to have_broadcasted_to(individual_channel)
          .with(
            error: subject::IMPORT_FAILED,
            status: "errored_importing_starter_code",
            status_text: "Failed"
          )
      end
    end

    context "with source import cancelled" do
      it "sets invite_status to errored_importing_starter_code" do
        subject.perform_now(cancelled_payload)
        expect(invite_status.status).to eq("errored_importing_starter_code")
      end

      it "reports cancelled stat" do
        expect(GitHubClassroom.statsd).to receive(:increment).with("v3_exercise_repo.import.cancelled")
        subject.perform_now(cancelled_payload)
      end

      it "broadcasts cancelled" do
        expect { subject.perform_now(cancelled_payload) }
          .to have_broadcasted_to(individual_channel)
          .with(
            error: subject::IMPORT_CANCELLED,
            status: "errored_importing_starter_code",
            status_text: "Failed"
          )
      end
    end
  end

  context "with created group_assignment_repo", :vcr do
    let(:group_assignment_repo) do
      GroupAssignmentRepo.new(
        organization: organization,
        group_assignment: group_assignment,
        github_repo_id: success_payload.dig("repository", "id"),
        group: group
      )
    end

    before do
      group_invitation
      allow(GroupAssignmentRepo)
        .to receive(:find_by)
        .with(github_repo_id: success_payload.dig("repository", "id"))
        .and_return(group_assignment_repo)
    end

    after(:each) do
      GroupAssignmentInvitation.destroy_all
      GroupAssignmentRepo.destroy_all
      GroupInviteStatus.destroy_all
      GroupAssignment.destroy_all
    end

    it "doesn't change the invite_status" do
      status = group_invite_status.status
      subject.perform_now(success_payload)
      expect(group_invite_status.reload.status).to eq(status)
    end

    it "doesn't report any stats" do
      expect(GitHubClassroom.statsd).to_not receive(:increment)
      subject.perform_now(success_payload)
    end

    it "doesn't broadcast" do
      expect { subject.perform_now(success_payload) }
        .to_not have_broadcasted_to(individual_channel)
    end

    context "with group_import_resiliency enabled" do
      context "with source import success" do
        it "sets invite_status to completed" do
          subject.perform_now(success_payload)
          expect(group_invite_status.status).to eq("completed")
        end

        it "reports success stat" do
          expect(GitHubClassroom.statsd).to receive(:increment).with("v3_group_exercise_repo.import.success")
          subject.perform_now(success_payload)
        end

        it "broadcasts completion" do
          expect { subject.perform_now(success_payload) }
            .to have_broadcasted_to(group_channel)
            .with(
              text: subject::CREATE_COMPLETE,
              status: "completed",
              status_text: "Done"
            )
        end
      end

      context "with source import failure" do
        it "sets invite_status to errored_importing_starter_code" do
          subject.perform_now(failure_payload)
          expect(group_invite_status.status).to eq("errored_importing_starter_code")
        end

        it "reports failure stat" do
          expect(GitHubClassroom.statsd).to receive(:increment).with("v3_group_exercise_repo.import.failure")
          subject.perform_now(failure_payload)
        end

        it "broadcasts failure" do
          expect { subject.perform_now(failure_payload) }
            .to have_broadcasted_to(group_channel)
            .with(
              error: subject::IMPORT_FAILED,
              status: "errored_importing_starter_code",
              status_text: "Failed"
            )
        end
      end

      context "with source import cancelled" do
        it "sets invite_status to errored_importing_starter_code" do
          subject.perform_now(cancelled_payload)
          expect(group_invite_status.status).to eq("errored_importing_starter_code")
        end

        it "reports cancelled stat" do
          expect(GitHubClassroom.statsd).to receive(:increment).with("v3_group_exercise_repo.import.cancelled")
          subject.perform_now(cancelled_payload)
        end

        it "broadcasts cancelled" do
          expect { subject.perform_now(cancelled_payload) }
            .to have_broadcasted_to(group_channel)
            .with(
              error: subject::IMPORT_CANCELLED,
              status: "errored_importing_starter_code",
              status_text: "Failed"
            )
        end
      end
    end
  end
end

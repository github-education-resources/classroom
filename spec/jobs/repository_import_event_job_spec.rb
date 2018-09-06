# frozen_string_literal: true

require "rails_helper"

RSpec.describe RepositoryImportEventJob, type: :job do
  subject { described_class }

  let(:individual_channel) { RepositoryCreationStatusChannel.channel(user_id: user.id) }

  let(:success_payload) { json_payload("webhook_events/repository_import_success.json") }
  let(:failure_payload) { json_payload("webhook_events/repository_import_failure.json") }

  let(:organization)  { classroom_org }
  let(:user)          { classroom_student }
  let(:assignment)    { create(:assignment, organization: organization) }
  let(:invitation)    { assignment.invitation }
  let(:invite_status) { invitation.status(user) }

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
            percent: 100,
            status_text: "Done",
            repo_url: "https://github.com/Codertocat/Hello-World"
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
            percent: nil,
            status_text: "Failed",
            repo_url: "https://github.com/Codertocat/Hello-World"
          )
      end
    end
  end
end

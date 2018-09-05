# frozen_string_literal: true

require "rails_helper"

RSpec.describe GroupAssignmentRepo::PorterStatusJob, type: :job do
  include ActiveJob::TestHelper

  subject { described_class }
  let(:group_repo_channel) { GroupRepositoryCreationStatusChannel }

  def request_stub(status)
    {
      status: status.to_s,
      status_text: "Importing...",
    }.to_json
  end

  context "with created objects", :vcr do
    let(:organization)  { classroom_org }
    let(:student)       { classroom_student }
    let(:repo_access)   { RepoAccess.create(user: student, organization: organization) }
    let(:grouping)      { create(:grouping, organization: organization) }
    let(:group)         { Group.create(title: "#{Faker::Company.name} team", grouping: grouping) }
    let(:invite_status) { group_assignment.invitation.status(group) }
    let(:channel)       { group_repo_channel.channel(group_assignment_id: group_assignment.id, group_id: group.id) }
    let(:group_assignment) do
      group_assignment = create(
        :group_assignment,
        grouping: grouping,
        title: "batman.js",
        organization: organization,
        public_repo: true,
        starter_code_repo_id: 1_062_897
      )
      group_assignment.build_group_assignment_invitation
      group_assignment
    end
    let(:group_assignment_repo) { GroupAssignmentRepo.create!(group_assignment: group_assignment, group: group) }

    after(:each) do
      RepoAccess.destroy_all
      GroupAssignmentRepo.destroy_all
      Group.destroy_all
      GroupAssignmentInvitation.destroy_all
      GroupAssignment.destroy_all
      clear_enqueued_jobs
      clear_performed_jobs
    end

    it "uses the porter_status queue" do
      subject.perform_later
      expect(subject).to have_been_enqueued.on_queue("porter_status")
    end

    context "import completes" do
      context "finishes immediately" do
        before do
          stub_request(:get, github_url("/repos/#{group_assignment_repo.github_repository.full_name}/import"))
          .to_return(
            status: 200,
            body: request_stub("complete"),
            headers: { "Content-Type": "application/json" }
          )
        end

        it "sets group_invite_status to completed" do
          subject.perform_now(group_assignment_repo, group)
          expect(invite_status.status).to eq("completed")
        end

        it "broadcasts completion" do
          expect { subject.perform_now(group_assignment_repo, group) }
            .to have_broadcasted_to(channel)
            .with(
              text: GroupAssignmentRepo::CreateGitHubRepositoryJob::CREATE_COMPLETE,
              status: "completed",
              percent: 100,
              status_text: "Done",
              repo_url: "https://github.com/#{group_assignment_repo.github_repository.full_name}"
            )
        end

        it "reports success stat" do
          expect(GitHubClassroom.statsd).to receive(:increment).with("v2_group_exercise_repo.import.success")
          subject.perform_now(group_assignment_repo, group)
        end
      end

      context "finishes after 2 requests" do
        before do
          stub_request(:get, github_url("/repos/#{group_assignment_repo.github_repository.full_name}/import"))
          .to_return(
            status: 201,
            body: request_stub("importing"),
            headers: { "Content-Type": "application/json" }
          ).times(2).then
          .to_return(
            status: 200,
            body: request_stub("complete"),
            headers: { "Content-Type": "application/json" }
          )
        end

        it "sets group_invite_status to completed" do
          subject.perform_now(group_assignment_repo, group)
          expect(invite_status.status).to eq("completed")
        end

        it "broadcasts completion" do
          expect { subject.perform_now(group_assignment_repo, group) }
            .to have_broadcasted_to(channel)
            .with(
              text: subject::IMPORT_ONGOING,
              status: "importing_starter_code",
              percent: 40,
              status_text: "Importing...",
              repo_url: "https://github.com/#{group_assignment_repo.github_repository.full_name}"
            )
            .with(
              text: GroupAssignmentRepo::CreateGitHubRepositoryJob::CREATE_COMPLETE,
              status: "completed",
              percent: 100,
              status_text: "Done",
              repo_url: "https://github.com/#{group_assignment_repo.github_repository.full_name}"
            )
        end

        it "reports success stat" do
          expect(GitHubClassroom.statsd).to receive(:increment).with("v2_group_exercise_repo.import.success")
          subject.perform_now(group_assignment_repo, group)
        end
      end
    end
  end
end

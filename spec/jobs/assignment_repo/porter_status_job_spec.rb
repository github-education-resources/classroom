# frozen_string_literal: true

require "rails_helper"

RSpec.describe AssignmentRepo::PorterStatusJob, type: :job do
  include ActiveJob::TestHelper

  subject { AssignmentRepo::PorterStatusJob }

  let(:organization) { classroom_org }
  let(:user)         { classroom_student }
  let(:assignment) do
    options = {
      title: "small-test-repo",
      starter_code_repo_id: 2_276_615,
      organization: organization,
      students_are_repo_admins: true
    }
    create(:assignment, options)
  end
  let(:invitation)    { create(:assignment_invitation, assignment: assignment) }
  let(:invite_status) { invitation.status(user) }

  before(:each) do
    subject::WAIT_TIME = 0.001
    @repo = organization.github_organization.create_repository(assignment.title, private: true)
    invite_status.importing_starter_code!
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  after(:each) do
    AssignmentRepo.destroy_all
  end

  describe "successful repo creation", :vcr do
    it "uses the porter_status queue" do
      subject.perform_later
      expect(subject).to have_been_enqueued.on_queue("porter_status")
    end

    context "started importing starter code" do
      before do
        creator = AssignmentRepo::Creator.new(assignment: assignment, user: user)
        creator.push_starter_code!(@repo.id)
        @assignment_repo = AssignmentRepo.new(assignment: assignment)
        @assignment_repo.github_repo_id = @repo.id
        @assignment_repo.save!
      end

      it "completes when porter status is 'complete'" do
        stub_request(:get, github_url("/repos/#{@repo.full_name}/import"))
          .to_return(
            status: 201,
            body: request_stub("importing"),
            headers: { "Content-Type": "application/json" }
          ).times(2).then
          .to_return(
            status: 200,
            body: request_stub("complete"),
            headers: { "Content-Type": "application/json" }
          ).times(2)
        subject.perform_now(@assignment_repo, user)
        expect(invite_status.reload.status).to eq("completed")
      end

      it "broadcasts when porter status is 'complete'" do
        stub_request(:get, github_url("/repos/#{@repo.full_name}/import"))
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
        expect { subject.perform_now(@assignment_repo, user) }
          .to have_broadcasted_to(RepositoryCreationStatusChannel.channel(user_id: user.id))
          .with(
            text: AssignmentRepo::Creator::IMPORT_ONGOING,
            status: "importing_starter_code",
            percent: 40,
            status_text: "Importing...",
            repo_url: "https://github.com/#{@repo.full_name}"
          )
          .with(
            text: AssignmentRepo::Creator::REPOSITORY_CREATION_COMPLETE,
            status: "completed",
            percent: 100,
            status_text: "Done",
            repo_url: "https://github.com/#{@repo.full_name}"
          )
      end

      it "reports success stat when porter status is 'complete'" do
        stub_request(:get, github_url("/repos/#{@repo.full_name}/import"))
          .to_return(
            status: 201,
            body: request_stub("importing"),
            headers: { "Content-Type": "application/json" }
          ).times(2).then
          .to_return(
            status: 200,
            body: request_stub("complete"),
            headers: { "Content-Type": "application/json" }
          ).times(2)
        expect(GitHubClassroom.statsd).to receive(:increment).with("v2_exercise_repo.import.poll").exactly(3).times
        expect(GitHubClassroom.statsd).to receive(:increment).with("v2_exercise_repo.import.success")
        subject.perform_now(@assignment_repo, user)
      end

      it "fails when porter status is 'error'" do
        stub_request(:get, github_url("/repos/#{@repo.full_name}/import"))
          .to_return(
            status: 201,
            body: request_stub("importing"),
            headers: { "Content-Type": "application/json" }
          ).times(2).then
          .to_return(
            status: 201,
            body: request_stub("error"),
            headers: { "Content-Type": "application/json" }
          ).times(2)
        subject.perform_now(@assignment_repo, user)
        expect(@assignment_repo.github_repository.imported?).to be_falsy
      end

      it "broadcasts failure when porter status is 'error'" do
        stub_request(:get, github_url("/repos/#{@repo.full_name}/import"))
          .to_return(
            status: 201,
            body: request_stub("importing"),
            headers: { "Content-Type": "application/json" }
          ).times(2).then
          .to_return(
            status: 201,
            body: request_stub("error"),
            headers: { "Content-Type": "application/json" }
          )
        expect { subject.perform_now(@assignment_repo, user) }
          .to have_broadcasted_to(RepositoryCreationStatusChannel.channel(user_id: user.id))
          .with(
            text: AssignmentRepo::Creator::IMPORT_ONGOING,
            status: "importing_starter_code",
            percent: 40,
            status_text: "Importing...",
            repo_url: "https://github.com/#{@repo.full_name}"
          )
          .with(
            error: AssignmentRepo::Creator::REPOSITORY_STARTER_CODE_IMPORT_FAILED,
            status: "errored_importing_starter_code"
          )
      end

      it "destroys assignment_repo when porter status is 'error'" do
        stub_request(:get, github_url("/repos/#{@repo.full_name}/import"))
          .to_return(
            status: 201,
            body: request_stub("importing"),
            headers: { "Content-Type": "application/json" }
          ).times(2).then
          .to_return(
            status: 201,
            body: request_stub("error"),
            headers: { "Content-Type": "application/json" }
          ).times(2)
        expect(@assignment_repo).to receive(:destroy)
        subject.perform_now(@assignment_repo, user)
      end

      it "makes DELETE request to GitHub repository associated with assignment_repo when porter status is 'error" do
        stub_request(:get, github_url("/repos/#{@repo.full_name}/import"))
          .to_return(
            status: 201,
            body: request_stub("importing"),
            headers: { "Content-Type": "application/json" }
          ).times(2).then
          .to_return(
            status: 201,
            body: request_stub("error"),
            headers: { "Content-Type": "application/json" }
          ).times(2)
        subject.perform_now(@assignment_repo, user)
        regex = %r{#{github_url("/repositories")}/\d+$}
        expect(WebMock).to have_requested(:delete, regex)
      end

      it "logs failure when porter status is 'error'" do
        stub_request(:get, github_url("/repos/#{@repo.full_name}/import"))
          .to_return(
            status: 201,
            body: request_stub("importing"),
            headers: { "Content-Type": "application/json" }
          ).times(2).then
          .to_return(
            status: 201,
            body: request_stub("error"),
            headers: { "Content-Type": "application/json" }
          )
        expect(Rails.logger)
          .to receive(:warn)
          .with(AssignmentRepo::Creator::REPOSITORY_STARTER_CODE_IMPORT_FAILED)
        subject.perform_now(@assignment_repo, user)
      end

      it "reports failure stat when porter status is 'error'" do
        stub_request(:get, github_url("/repos/#{@repo.full_name}/import"))
          .to_return(
            status: 201,
            body: request_stub("importing"),
            headers: { "Content-Type": "application/json" }
          ).times(2).then
          .to_return(
            status: 201,
            body: request_stub("error"),
            headers: { "Content-Type": "application/json" }
          )
        expect(GitHubClassroom.statsd).to receive(:increment).with("v2_exercise_repo.import.poll").exactly(3).times
        expect(GitHubClassroom.statsd).to receive(:increment).with("v2_exercise_repo.import.fail")
        subject.perform_now(@assignment_repo, user)
      end

      it "fails when porter API errors" do
        stub_request(:get, github_url("/repos/#{@repo.full_name}/import"))
          .to_return(
            status: 201,
            body: request_stub("importing"),
            headers: { "Content-Type": "application/json" }
          ).times(2).then
          .to_return(
            status: 500
          ).times(2)
        subject.perform_now(@assignment_repo, user)
        expect { @assignment_repo.github_repository.import_progress }.to raise_error(GitHub::Error)
      end

      it "broadcasts failure when porter API errors" do
        stub_request(:get, github_url("/repos/#{@repo.full_name}/import"))
          .to_return(
            status: 201,
            body: request_stub("importing"),
            headers: { "Content-Type": "application/json" }
          ).times(2).then
          .to_return(
            status: 500
          )
        expect { subject.perform_now(@assignment_repo, user) }
          .to have_broadcasted_to(RepositoryCreationStatusChannel.channel(user_id: user.id))
          .with(
            text: AssignmentRepo::Creator::IMPORT_ONGOING,
            status: "importing_starter_code",
            percent: 40,
            status_text: "Importing...",
            repo_url: "https://github.com/#{@repo.full_name}"
          )
          .with(
            error: AssignmentRepo::Creator::REPOSITORY_STARTER_CODE_IMPORT_FAILED,
            status: "errored_importing_starter_code"
          )
      end

      it "destroys assignment_repo when porter API errors" do
        stub_request(:get, github_url("/repos/#{@repo.full_name}/import"))
          .to_return(
            status: 201,
            body: request_stub("importing"),
            headers: { "Content-Type": "application/json" }
          ).times(2).then
          .to_return(
            status: 500
          )
        expect(@assignment_repo).to receive(:destroy)
        subject.perform_now(@assignment_repo, user)
      end

      it "makes DELETE request to GitHub repository associated with assignment_repo when porter API errors" do
        stub_request(:get, github_url("/repos/#{@repo.full_name}/import"))
          .to_return(
            status: 201,
            body: request_stub("importing"),
            headers: { "Content-Type": "application/json" }
          ).times(2).then
          .to_return(
            status: 500
          )
        subject.perform_now(@assignment_repo, user)
        regex = %r{#{github_url("/repositories")}/\d+$}
        expect(WebMock).to have_requested(:delete, regex)
      end

      it "logs failure when porter API errors" do
        stub_request(:get, github_url("/repos/#{@repo.full_name}/import"))
          .to_return(
            status: 201,
            body: request_stub("importing"),
            headers: { "Content-Type": "application/json" }
          ).times(2).then
          .to_return(
            status: 500
          )

        expect(Rails.logger)
          .to receive(:warn)
          .with(AssignmentRepo::Creator::REPOSITORY_STARTER_CODE_IMPORT_FAILED)
        expect(Rails.logger)
          .to receive(:warn)
          .with("There seems to be a problem on github.com, please try again.")
        subject.perform_now(@assignment_repo, user)
      end

      it "kicks off another porter status job when octopoller timesout" do
        expect(Octopoller).to receive(:poll).with(wait: 0.001, retries: 3).and_raise(Octopoller::TooManyAttemptsError)
        assert_enqueued_jobs 1, only: AssignmentRepo::PorterStatusJob do
          subject.perform_now(@assignment_repo, user)
        end
      end

      it "reports timeout stat when porter status job timesout" do
        expect(Octopoller).to receive(:poll).with(wait: 0.001, retries: 3).and_raise(Octopoller::TooManyAttemptsError)
        expect(GitHubClassroom.statsd).to receive(:increment).with("v2_exercise_repo.import.timeout")
        subject.perform_now(@assignment_repo, user)
      end
    end
  end

  def request_stub(status)
    {
      status: status.to_s,
      status_text: "Importing..."
    }.to_json
  end
end

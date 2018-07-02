# frozen_string_literal: true

require "rails_helper"

RSpec.describe AssignmentRepo::PorterStatusJob, type: :job do
  include ActiveJob::TestHelper

  subject { AssignmentRepo::PorterStatusJob }

  let(:organization)  { classroom_org }
  let(:student)       { classroom_student }
  let(:teacher)       { classroom_teacher }

  let(:assignment) do
    options = {
      title: "small-test-repo",
      starter_code_repo_id: 2_276_615,
      organization: organization,
      students_are_repo_admins: true
    }

    create(:assignment, options)
  end

  before do
    Octokit.reset!
    @client = oauth_client
  end

  before(:each) do
    github_organization = GitHubOrganization.new(@client, organization.github_id)
    @repo = github_organization.create_repository(assignment.title, private: true)
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  after(:each) do
    @client.delete_repository(@repo.id)
    AssignmentRepo.destroy_all
  end

  describe "successful repo creation", :vcr do
    it "uses the porter_status queue" do
      subject.perform_later
      expect(subject).to have_been_enqueued.on_queue("porter_status")
    end

    context "started importing starter code" do
      before do
        creator = AssignmentRepo::Creator.new(assignment: assignment, user: student)
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
        subject.perform_now(@assignment_repo, student)
        expect(@assignment_repo.github_repository.imported?).to be_truthy
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
        expect { subject.perform_now(@assignment_repo, student) }
          .to have_broadcasted_to(RepositoryCreationStatusChannel.channel(user_id: student.id))
          .with(text: AssignmentRepo::Creator::REPOSITORY_CREATION_COMPLETE)
      end

      it "logs until porter status is 'complete'" do
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
        expect(Rails.logger).to receive(:warn).with(AssignmentRepo::Creator::IMPORT_ONGOING).exactly(2)
        subject.perform_now(@assignment_repo, student)
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
        subject.perform_now(@assignment_repo, student)
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
        expect { subject.perform_now(@assignment_repo, student) }
          .to have_broadcasted_to(RepositoryCreationStatusChannel.channel(user_id: student.id))
          .with(text: AssignmentRepo::Creator::REPOSITORY_STARTER_CODE_IMPORT_FAILED)
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
          .with(AssignmentRepo::Creator::IMPORT_ONGOING)
          .exactly(2)
        expect(Rails.logger)
          .to receive(:warn)
          .with(AssignmentRepo::Creator::REPOSITORY_STARTER_CODE_IMPORT_FAILED)
        subject.perform_now(@assignment_repo, student)
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
        subject.perform_now(@assignment_repo, student)
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
        expect { subject.perform_now(@assignment_repo, student) }
          .to have_broadcasted_to(RepositoryCreationStatusChannel.channel(user_id: student.id))
          .with(text: AssignmentRepo::Creator::REPOSITORY_STARTER_CODE_IMPORT_FAILED)
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
          .with(AssignmentRepo::Creator::IMPORT_ONGOING)
          .exactly(2)
        expect(Rails.logger)
          .to receive(:warn)
          .with(AssignmentRepo::Creator::REPOSITORY_STARTER_CODE_IMPORT_FAILED)
        subject.perform_now(@assignment_repo, student)
      end
    end
  end

  # rubocop:disable MethodLength
  def request_stub(status)
    {
      "vcs": "git",
      "use_lfs": "undecided",
      "vcs_url": "https://github.com/rtyley/small-test-repo",
      "status": status.to_s,
      "commit_count": nil,
      "status_text": "Importing...",
      "authors_count": 0,
      "import_percent": nil,
      "url": "https://api.github.com/repos/classroom-test-org-edon/small-test-repo/import",
      "html_url": "https://github.com/classroom-test-org-edon/small-test-repo/import",
      "authors_url": "https://api.github.com/repos/classroom-test-org-edon/small-test-repo/import/authors",
      "repository_url": "https://api.github.com/repos/classroom-test-org-edon/small-test-repo"
    }.to_json
  end
  # rubocop:enable MethodLength
end

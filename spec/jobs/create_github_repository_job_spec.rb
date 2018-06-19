# frozen_string_literal: true

require "rails_helper"

RSpec.describe AssignmentRepo::CreateGitHubRepositoryJob, type: :job do
  include ActiveJob::TestHelper

  subject { AssignmentRepo::CreateGitHubRepositoryJob }

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

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  after(:each) do
    AssignmentRepo.destroy_all
  end

  describe "successful creation", :vcr do
    it "uses the :create_repository queue" do
      assert_performed_with(job: subject, args: [assignment, student], queue: "create_repository") do
        subject.perform_later(assignment, student)
      end
    end

    it "creates an AssignmentRepo as an outside_collaborator" do
      subject.perform_now(assignment, student)

      result = assignment.assignment_repos.first
      expect(result.nil?).to be_falsy
      expect(result.assignment).to eql(assignment)
      expect(result.user).to eql(student)
    end

    it "creates an AssignmentRepo as a member" do
      subject.perform_now(assignment, teacher)

      result = assignment.assignment_repos.first
      expect(result.nil?).to be_falsy
      expect(result.assignment).to eql(assignment)
      expect(result.user).to eql(teacher)
    end
  end

  describe "retries job", :vcr do
    it "handles repoistory creation failure" do
      stub_request(:post, github_url("/organizations/#{organization.github_id}/repos"))
        .to_return(body: "{}", status: 401)

      perform_enqueued_jobs do
        expect_any_instance_of(AssignmentRepo::CreateGitHubRepositoryJob)
          .to receive(:retry_job)
          .with(wait: 3, queue: :create_repository, priority: nil)

        subject.perform_later(assignment, student)
      end
    end

    context "with successful repo creation" do
      # Verify that we try to delete the GitHub repository
      # if part of the process fails.
      after(:each) do
        regex = %r{#{github_url("/repositories")}/\d+$}
        expect(WebMock).to have_requested(:delete, regex)
      end

      it "fails when the user could not be added to the repo" do
        repo_invitation_regex = %r{#{github_url("/repositories/")}\d+/collaborators/.+$}
        stub_request(:put, repo_invitation_regex)
          .to_return(body: "{}", status: 401)

        perform_enqueued_jobs do
          expect_any_instance_of(AssignmentRepo::CreateGitHubRepositoryJob)
            .to receive(:retry_job)
            .with(wait: 3, queue: :create_repository, priority: nil)

          subject.perform_later(assignment, student)
        end
      end

      it "fails when the AssignmentRepo object could not be created" do
         allow_any_instance_of(AssignmentRepo).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)

        perform_enqueued_jobs do
          expect_any_instance_of(AssignmentRepo::CreateGitHubRepositoryJob)
            .to receive(:retry_job)
            .with(wait: 3, queue: :create_repository, priority: nil)

          subject.perform_later(assignment, teacher)
        end
      end
    end
  end
end

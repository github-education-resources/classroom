# frozen_string_literal: true

require "rails_helper"

RSpec.describe AssignmentRepo::CreateGitHubRepositoryJob, type: :job do
  include ActiveJob::TestHelper

  subject { AssignmentRepo::CreateGitHubRepositoryJob }

  let(:cascading_job) { AssignmentRepo::PorterStatusJob }
  let(:organization)  { classroom_org }
  let(:student)       { classroom_student }
  let(:teacher)       { classroom_teacher }

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

  describe "invalid invitation statuses", :vcr do
    before do
      @invitation = AssignmentInvitation.create(assignment: assignment)
    end

    after do
      AssignmentInvitation.create(assignment: assignment).accepted!
    end

    it "returns early when invitation status is unaccepted" do
      @invitation.unaccepted!
      expect(@invitation).not_to receive(:creating_repo!)
      subject.perform_now(assignment, teacher)
    end

    it "returns early when invitation status is creating_repo" do
      @invitation.creating_repo!
      expect(@invitation).not_to receive(:creating_repo!)
      subject.perform_now(assignment, teacher)
    end

    it "returns early when invitation status is importing_starter_code" do
      @invitation.importing_starter_code!
      expect(@invitation).not_to receive(:creating_repo!)
      subject.perform_now(assignment, teacher)
    end

    it "returns early when invitation status is completed" do
      @invitation.completed!
      expect(@invitation).not_to receive(:creating_repo!)
      subject.perform_now(assignment, teacher)
    end
  end

  describe "successful creation", :vcr do
    after(:each) do
      AssignmentRepo.destroy_all
    end

    it "uses the create_repository queue" do
      subject.perform_later
      expect(subject).to have_been_enqueued.on_queue("create_repository")
    end

    it "kicks off a cascading porter status job" do
      subject.perform_now(assignment, teacher)
      expect(cascading_job).to have_been_enqueued.on_queue("porter_status")
    end

    context "creates an AssignmentRepo as an outside_collaborator" do
      before do
        subject.perform_now(assignment, student)
      end

      it "is not nil" do
        result = assignment.assignment_repos.first
        expect(result.nil?).to be_falsy
      end

      it "is the same assignment" do
        result = assignment.assignment_repos.first
        expect(result.assignment).to eql(assignment)
      end

      it "has the same user" do
        result = assignment.assignment_repos.first
        expect(result.user).to eql(student)
      end
    end

    context "creates an AssignmentRepo as a member" do
      before do
        subject.perform_now(assignment, teacher)
      end

      it "is not nil" do
        result = assignment.assignment_repos.first
        expect(result.nil?).to be_falsy
      end

      it "is the same assignment" do
        result = assignment.assignment_repos.first
        expect(result.assignment).to eql(assignment)
      end

      it "has the same user" do
        result = assignment.assignment_repos.first
        expect(result.user).to eql(teacher)
      end
    end

    it "broadcasts status on channel" do
      AssignmentInvitation.create(assignment: assignment).accepted!
      expect { subject.perform_now(assignment, teacher) }
        .to have_broadcasted_to(RepositoryCreationStatusChannel.channel(user_id: teacher.id))
        .with(
          text: AssignmentRepo::CreateGitHubRepositoryJob::CREATE_REPO,
          status: "creating_repo"
        )
        .with(
          text: AssignmentRepo::CreateGitHubRepositoryJob::IMPORT_STARTER_CODE,
          status: "importing_starter_code"
        )
    end

    it "tracks create fail stat" do
      expect(GitHubClassroom.statsd).to receive(:increment).with("v2_exercise_repo.create.success")
      subject.perform_now(assignment, teacher)
    end

    it "tracks how long it too to be created" do
      expect(GitHubClassroom.statsd).to receive(:timing)
      subject.perform_now(assignment, teacher)
    end
  end

  describe "failure", :vcr do
    it "fails to create repo and retries" do
      stub_request(:post, github_url("/organizations/#{organization.github_id}/repos"))
        .to_return(body: "{}", status: 401)

      perform_enqueued_jobs do
        expect_any_instance_of(AssignmentRepo::CreateGitHubRepositoryJob)
          .to receive(:retry_job)
          .with(wait: 3, queue: :create_repository, priority: nil)

        subject.perform_later(assignment, student)
      end
    end

    it "tracks create fail stat" do
      stub_request(:post, github_url("/organizations/#{organization.github_id}/repos"))
        .to_return(body: "{}", status: 401)

      expect(GitHubClassroom.statsd).to receive(:increment).with("v2_exercise_repo.create.fail")
      subject.perform_now(assignment, student)
    end

    it "broadcasts create repo failure" do
      AssignmentInvitation.create(assignment: assignment).accepted!
      stub_request(:post, github_url("/organizations/#{organization.github_id}/repos"))
        .to_return(body: "{}", status: 401)

      expect { subject.perform_now(assignment, student) }
        .to have_broadcasted_to(RepositoryCreationStatusChannel.channel(user_id: student.id))
        .with(
          text: AssignmentRepo::CreateGitHubRepositoryJob::CREATE_REPO,
          status: "creating_repo"
        )
        .with(
          text: AssignmentRepo::Creator::REPOSITORY_CREATION_FAILED,
          status: "errored"
        )
    end

    context "with successful repo creation" do
      before do
        AssignmentInvitation.create(assignment: assignment).accepted!
      end

      # Verify that we try to delete the GitHub repository
      # if part of the process fails.
      after(:each) do
        regex = %r{#{github_url("/repositories")}/\d+$}
        expect(WebMock).to have_requested(:delete, regex)
      end

      it "fails to import starter code and retries" do
        import_regex = %r{#{github_url("/repositories/")}\d+/import$}
        stub_request(:put, import_regex)
          .to_return(body: "{}", status: 401)

        perform_enqueued_jobs do
          expect_any_instance_of(AssignmentRepo::CreateGitHubRepositoryJob)
            .to receive(:retry_job)
            .with(wait: 3, queue: :create_repository, priority: nil)

          subject.perform_later(assignment, student)
        end
      end

      it "fails to import starter code and broadcasts" do
        import_regex = %r{#{github_url("/repositories/")}\d+/import$}
        stub_request(:put, import_regex)
          .to_return(body: "{}", status: 401)

        expect { subject.perform_now(assignment, student) }
          .to have_broadcasted_to(RepositoryCreationStatusChannel.channel(user_id: student.id))
          .with(
            text: AssignmentRepo::CreateGitHubRepositoryJob::CREATE_REPO,
            status: "creating_repo"
          )
          .with(
            text: AssignmentRepo::Creator::REPOSITORY_STARTER_CODE_IMPORT_FAILED,
            status: "errored"
          )
      end

      it "fails to add the user to the repo and retries" do
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

      it "fails to add the user to the repo and broadcasts" do
        repo_invitation_regex = %r{#{github_url("/repositories/")}\d+/collaborators/.+$}
        stub_request(:put, repo_invitation_regex)
          .to_return(body: "{}", status: 401)

        expect { subject.perform_now(assignment, student) }
          .to have_broadcasted_to(RepositoryCreationStatusChannel.channel(user_id: student.id))
          .with(
            text: AssignmentRepo::CreateGitHubRepositoryJob::CREATE_REPO,
            status: "creating_repo"
          )
          .with(
            text: AssignmentRepo::Creator::REPOSITORY_COLLABORATOR_ADDITION_FAILED,
            status: "errored"
          )
      end

      it "fails to save the AssignmentRepo and retries" do
        allow_any_instance_of(AssignmentRepo).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)

        perform_enqueued_jobs do
          expect_any_instance_of(AssignmentRepo::CreateGitHubRepositoryJob)
            .to receive(:retry_job)
            .with(wait: 3, queue: :create_repository, priority: nil)

          subject.perform_later(assignment, teacher)
        end
      end

      it "fails to save the AssignmentRepo and broadcasts" do
        allow_any_instance_of(AssignmentRepo).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)

        expect { subject.perform_now(assignment, student) }
          .to have_broadcasted_to(RepositoryCreationStatusChannel.channel(user_id: student.id))
          .with(
            text: AssignmentRepo::CreateGitHubRepositoryJob::CREATE_REPO,
            status: "creating_repo"
          )
          .with(
            text: AssignmentRepo::Creator::DEFAULT_ERROR_MESSAGE,
            status: "errored"
          )
      end
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe AssignmentRepo::CreateGitHubRepositoryJob, type: :job do
  include ActiveJob::TestHelper

  subject { described_class }

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

  before do
    @invitation = AssignmentInvitation.create(assignment: assignment)
    @teacher_invite_status = @invitation.status(teacher)
    @student_invite_status = @invitation.status(student)
  end

  before(:each) do
    @teacher_invite_status.waiting!
    @student_invite_status.waiting!
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
    AssignmentRepo.destroy_all
  end

  describe "invalid invitation statuses", :vcr do
    it "returns early when invitation status is unaccepted" do
      @teacher_invite_status.unaccepted!
      expect(@teacher_invite_status).not_to receive(:creating_repo!)
      subject.perform_now(assignment, teacher)
    end

    it "returns early when invitation status is creating_repo" do
      @teacher_invite_status.creating_repo!
      expect(@teacher_invite_status).not_to receive(:creating_repo!)
      subject.perform_now(assignment, teacher)
    end

    it "returns early when invitation status is importing_starter_code" do
      @teacher_invite_status.importing_starter_code!
      expect(@teacher_invite_status).not_to receive(:creating_repo!)
      subject.perform_now(assignment, teacher)
    end

    it "returns early when invitation status is completed" do
      @teacher_invite_status.completed!
      expect(@teacher_invite_status).not_to receive(:creating_repo!)
      subject.perform_now(assignment, teacher)
    end
  end

  describe "successful creation", :vcr do
    it "uses the create_repository queue" do
      subject.perform_later
      expect(subject).to have_been_enqueued.on_queue("create_repository")
    end

    context "creates an AssignmentRepo as an outside_collaborator" do
      let(:assignment_repo) { AssignmentRepo.find_by(user: student, assignment: assignment) }

      before do
        subject.perform_now(assignment, student)
      end

      it "is not nil" do
        expect(assignment_repo.present?).to be_truthy
      end

      it "is the same assignment" do
        expect(assignment_repo.assignment).to eql(assignment)
      end

      it "has the same user" do
        expect(assignment_repo.user).to eql(student)
      end

      it "has a github_global_relay_id" do
        expect(assignment_repo.github_global_relay_id).to_not be_nil
      end
    end

    context "creates an AssignmentRepo as a member" do
      let(:assignment_repo) { AssignmentRepo.find_by(user: teacher, assignment: assignment) }

      before do
        subject.perform_now(assignment, teacher)
      end

      it "is not nil" do
        expect(assignment_repo.present?).to be_truthy
      end

      it "is the same assignment" do
        expect(assignment_repo.assignment).to eql(assignment)
      end

      it "has the same user" do
        expect(assignment_repo.user).to eql(teacher)
      end

      it "has a github_global_relay_id" do
        expect(assignment_repo.github_global_relay_id).to_not be_nil
      end
    end

    it "broadcasts status on channel" do
      expect { subject.perform_now(assignment, teacher) }
        .to have_broadcasted_to(
          RepositoryCreationStatusChannel.channel(user_id: teacher.id, assignment_id: assignment.id)
        )
        .with(
          text: subject::CREATE_REPO,
          status: "creating_repo",
          status_text: "Creating GitHub repository",
          repo_url: nil
        )
        .with(
          text: subject::IMPORT_STARTER_CODE,
          status: "importing_starter_code",
          status_text: "Import started",
          repo_url: "https://github.com/#{organization.github_organization.login}/learn-elm-EDONTestTeacher"
        )
    end

    it "tracks create success stat" do
      expect(GitHubClassroom.statsd).to receive(:increment).with("exercise_repo.create.success")
      expect(GitHubClassroom.statsd).to receive(:increment).with("v2_exercise_repo.create.success")
      expect(GitHubClassroom.statsd).to receive(:increment).with("exercise_repo.import.started")
      subject.perform_now(assignment, teacher)
    end

    it "tracks how long it too to be created" do
      expect(GitHubClassroom.statsd).to receive(:timing).with("exercise_repo.create.time", anything)
      expect(GitHubClassroom.statsd).to receive(:timing).with("v2_exercise_repo.create.time", anything)
      subject.perform_now(assignment, teacher)
    end
  end

  describe "failure", :vcr do
    it "tracks create fail stat" do
      stub_request(:post, github_url("/organizations/#{organization.github_id}/repos"))
        .to_return(body: "{}", status: 401)
      expect(GitHubClassroom.statsd).to receive(:increment).with("exercise_repo.create.fail")
      expect(GitHubClassroom.statsd).to receive(:increment).with("v2_exercise_repo.create.repo.fail")
      expect(GitHubClassroom.statsd).to receive(:increment).with("github.error.Unauthorized")
      subject.perform_now(assignment, student)
    end

    it "broadcasts create repo failure" do
      stub_request(:post, github_url("/organizations/#{organization.github_id}/repos"))
        .to_return(body: "{}", status: 401)

      expect { subject.perform_now(assignment, student) }
        .to have_broadcasted_to(
          RepositoryCreationStatusChannel.channel(user_id: student.id, assignment_id: assignment.id)
        )
        .with(
          text: subject::CREATE_REPO,
          status: "creating_repo",
          status_text: "Creating GitHub repository",
          repo_url: nil
        )
        .with(
          hash_including(
            :error,
            status: "errored_creating_repo",
            status_text: "Failed",
            repo_url: nil
          )
        )
    end

    it "fails and automatically retries" do
      import_regex = %r{#{github_url("/repositories/")}\d+/import$}
      stub_request(:put, import_regex)
        .to_return(body: "{}", status: 401)

      expect(subject).to receive(:perform_later).with(assignment, teacher, retries: 0)
      subject.perform_now(assignment, teacher, retries: 1)
    end

    it "fails and puts invite status in state to retry" do
      import_regex = %r{#{github_url("/repositories/")}\d+/import$}
      stub_request(:put, import_regex)
        .to_return(body: "{}", status: 401)

      subject.perform_now(assignment, teacher, retries: 1)
      expect(@teacher_invite_status.reload.waiting?).to be_truthy
    end

    context "with successful repo creation" do
      # Verify that we try to delete the GitHub repository
      # if part of the process fails.
      after(:each) do
        regex = %r{#{github_url("/repositories")}/\d+$}
        expect(WebMock).to have_requested(:delete, regex)
      end

      it "fails to import starter code and broadcasts" do
        import_regex = %r{#{github_url("/repositories/")}\d+/import$}
        stub_request(:put, import_regex)
          .to_return(body: "{}", status: 401)

        expect { subject.perform_now(assignment, student) }
          .to have_broadcasted_to(
            RepositoryCreationStatusChannel.channel(user_id: student.id, assignment_id: assignment.id)
          )
          .with(
            text: subject::CREATE_REPO,
            status: "creating_repo",
            status_text: "Creating GitHub repository",
            repo_url: nil
          )
          .with(
            hash_including(
              :error,
              status: "errored_creating_repo",
              status_text: "Failed",
              repo_url: nil
            )
          )
      end

      it "fails to import starter code and logs" do
        import_regex = %r{#{github_url("/repositories/")}\d+/import$}
        stub_request(:put, import_regex)
          .to_return(body: "{}", status: 401)

        expect(Rails.logger)
          .to receive(:warn)
          .with(a_string_starting_with(AssignmentRepo::Creator::REPOSITORY_STARTER_CODE_IMPORT_FAILED))
        subject.perform_now(assignment, student)
      end

      it "fails to import starter code and reports" do
        import_regex = %r{#{github_url("/repositories/")}\d+/import$}
        stub_request(:put, import_regex)
          .to_return(body: "{}", status: 401)
        expect(GitHubClassroom.statsd)
          .to receive(:increment)
          .with("exercise_repo.create.fail")
        expect(GitHubClassroom.statsd)
          .to receive(:increment)
          .with("github.error.Unauthorized")
        expect(GitHubClassroom.statsd)
          .to receive(:increment)
          .with("v2_exercise_repo.create.importing_starter_code.fail")
        subject.perform_now(assignment, student)
      end

      it "fails to add the user to the repo and broadcasts" do
        repo_invitation_regex = %r{#{github_url("/repositories/")}\d+/collaborators/.+$}
        stub_request(:put, repo_invitation_regex)
          .to_return(body: "{}", status: 401)

        expect { subject.perform_now(assignment, student) }
          .to have_broadcasted_to(
            RepositoryCreationStatusChannel.channel(user_id: student.id, assignment_id: assignment.id)
          )
          .with(
            text: subject::CREATE_REPO,
            status: "creating_repo",
            status_text: "Creating GitHub repository",
            repo_url: nil
          )
          .with(
            hash_including(
              :error,
              status: "errored_creating_repo",
              status_text: "Failed",
              repo_url: nil
            )
          )
      end

      it "fails to add the user to the repo and logs" do
        repo_invitation_regex = %r{#{github_url("/repositories/")}\d+/collaborators/.+$}
        stub_request(:put, repo_invitation_regex)
          .to_return(body: "{}", status: 401)

        expect(Rails.logger)
          .to receive(:warn)
          .with(a_string_starting_with(AssignmentRepo::Creator::REPOSITORY_COLLABORATOR_ADDITION_FAILED))
        subject.perform_now(assignment, student)
      end

      it "fails to add the user to the repo and reports" do
        repo_invitation_regex = %r{#{github_url("/repositories/")}\d+/collaborators/.+$}
        stub_request(:put, repo_invitation_regex)
          .to_return(body: "{}", status: 401)
        expect(GitHubClassroom.statsd)
          .to receive(:increment)
          .with("exercise_repo.create.fail")
        expect(GitHubClassroom.statsd)
          .to receive(:increment)
          .with("github.error.Unauthorized")
        expect(GitHubClassroom.statsd)
          .to receive(:increment)
          .with("v2_exercise_repo.create.adding_collaborator.fail")
        subject.perform_now(assignment, student)
      end

      it "fails to save the AssignmentRepo and broadcasts" do
        allow_any_instance_of(AssignmentRepo).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)

        expect { subject.perform_now(assignment, student) }
          .to have_broadcasted_to(
            RepositoryCreationStatusChannel.channel(user_id: student.id, assignment_id: assignment.id)
          )
          .with(
            text: subject::CREATE_REPO,
            status: "creating_repo",
            status_text: "Creating GitHub repository",
            repo_url: nil
          )
          .with(
            hash_including(
              :error,
              status: "errored_creating_repo",
              status_text: "Failed",
              repo_url: nil
            )
          )
      end

      it "fails to save the AssignmentRepo and logs" do
        allow_any_instance_of(AssignmentRepo).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)

        expect(Rails.logger)
          .to receive(:warn)
          .with("Record invalid")
        expect(Rails.logger)
          .to receive(:warn)
          .with(a_string_starting_with(AssignmentRepo::Creator::DEFAULT_ERROR_MESSAGE))
        subject.perform_now(assignment, student)
      end

      it "fails to save the AssignmentRepo and reports" do
        allow_any_instance_of(AssignmentRepo).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
        expect(GitHubClassroom.statsd).to receive(:increment).with("exercise_repo.create.fail")
        expect(GitHubClassroom.statsd).to receive(:increment).with("v2_exercise_repo.create.fail")
        subject.perform_now(assignment, student)
      end
    end
  end
end

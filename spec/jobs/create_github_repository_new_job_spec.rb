# frozen_string_literal: true

require "rails_helper"

RSpec.describe CreateGitHubRepositoryNewJob, type: :job do
  include ActiveJob::TestHelper
  subject { described_class }

  let(:organization)  { classroom_org }
  let(:student)       { classroom_student }
  let(:teacher)       { classroom_teacher }

  let(:assignment) do
    options = {
      title: "Learn Elm",
      starter_code_repo_id: nil,
      organization: organization,
      students_are_repo_admins: true
    }
    create(:assignment, options)
  end

  let(:service) { CreateGitHubRepoService.new(assignment, student) }
  let(:invite_status) { assignment.invitation.status(student) }

  describe "#perform", :vcr do
    before(:each) do
      invite_status.waiting!
    end

    after(:each) do
      clear_enqueued_jobs
      clear_performed_jobs
    end

    context "invalid invitation statuses" do
      it "returns early when invitation status is unaccepted" do
        invite_status.unaccepted!
        expect(invite_status).not_to receive(:creating_repo!)
        subject.perform_now(assignment, student)
      end

      it "returns early when invitation status is creating_repo" do
        invite_status.creating_repo!
        expect(invite_status).not_to receive(:creating_repo!)
        subject.perform_now(assignment, student)
      end

      it "returns early when invitation status is importing_starter_code" do
        invite_status.importing_starter_code!
        expect(invite_status).not_to receive(:creating_repo!)
        subject.perform_now(assignment, student)
      end

      it "returns early when invitation status is completed" do
        invite_status.completed!
        expect(invite_status).not_to receive(:creating_repo!)
        subject.perform_now(assignment, student)
      end
    end

    describe "performs the service", :vcr do
      context "and returns a valid result" do
        it "without calling #handle_error" do
          expect_any_instance_of(subject).not_to receive(:handle_error)
          subject.perform_now(assignment, student)
        end
      end
      context "and raises a Result::Error if service failed" do
        it "if #verify_organization_has_private_repos_available! fails" do
          allow_any_instance_of(CreateGitHubRepoService)
            .to receive(:verify_organization_has_private_repos_available!)
            .and_raise(
              CreateGitHubRepoService::Result::Error,
              service.send(:errors, :private_repos_not_available, private_repos: 1)
            )
          error_message = <<-ERROR
      Cannot make this private assignment, your limit of 1
       repository has been reached. You can request
       a larger plan for free at https://education.github.com/discount
       ERROR
          expect_any_instance_of(subject)
            .to receive(:handle_error)
            .with(error_message, instance_of(CreateGitHubRepoService), anything)
          subject.perform_now(assignment, student)
        end

        it "if #create_github_repository! fails" do
          allow_any_instance_of(CreateGitHubRepoService)
            .to receive(:create_github_repository!)
            .and_raise(
              CreateGitHubRepoService::Result::Error,
              service.send(:errors, :repository_creation_failed)
            )
          error_message = "GitHub repository could not be created, please try again."
          expect_any_instance_of(subject)
            .to receive(:handle_error)
            .with(error_message, instance_of(CreateGitHubRepoService), anything)
          subject.perform_now(assignment, student)
        end

        it "if #create_assignment_repo! fails" do
          allow_any_instance_of(CreateGitHubRepoService)
            .to receive(:create_assignment_repo!)
            .and_raise(
              CreateGitHubRepoService::Result::Error,
              service.send(:errors, :default)
            )
          error_message = "Assignment could not be created, please try again."
          expect_any_instance_of(subject)
            .to receive(:handle_error)
            .with(error_message, instance_of(CreateGitHubRepoService), anything)
          subject.perform_now(assignment, student)
        end

        it "if #add_collaborator_to_github_repository! fails" do
          allow_any_instance_of(CreateGitHubRepoService)
            .to receive(:add_collaborator_to_github_repository!)
            .and_raise(
              CreateGitHubRepoService::Result::Error,
              service.send(:errors, :collaborator_addition_failed)
            )
          error_message = "We were not able to add the user to the Assignment, please try again."
          expect_any_instance_of(subject)
            .to receive(:handle_error)
            .with(error_message, instance_of(CreateGitHubRepoService), anything)
          subject.perform_now(assignment, student)
        end

        it "if #push_starter_code! fails" do
          allow_any_instance_of(Assignment)
            .to receive("starter_code?").and_return(true)
          allow_any_instance_of(CreateGitHubRepoService)
            .to receive(:push_starter_code!)
            .and_raise(
              CreateGitHubRepoService::Result::Error,
              service.send(:errors, :starter_code_import_failed)
            )
          error_message = "We were not able to import you the starter code to your Assignment, please try again."
          expect_any_instance_of(subject)
            .to receive(:handle_error)
            .with(error_message, instance_of(CreateGitHubRepoService), anything)
          subject.perform_now(assignment, student)
        end
      end
    end
  end
  describe "#handle_error", :vcr do
    before(:each) do
      invite_status.waiting!
      allow_any_instance_of(CreateGitHubRepoService)
        .to receive(:create_assignment_repo!)
        .and_raise(
          CreateGitHubRepoService::Result::Error,
          service.send(:errors, :default)
        )
    end

    it "logs the error on failure" do
      expect(subject.logger).to receive(:warn).with("Assignment could not be created, please try again.")
      subject.perform_now(assignment, student)
    end

    it "enqueues a new job if retries are positive" do
      expect { subject.perform_now(assignment, student, retries: 2) }
        .to have_enqueued_job(CreateGitHubRepositoryNewJob)
        .with(assignment, student, retries: 1)
    end

    it "sets invite_status to be #error_creating_repo if retries are exhausted" do
      allow_any_instance_of(CreateGitHubRepoService).to receive_message_chain("invite_status.creating_repo!")
      expect_any_instance_of(CreateGitHubRepoService).to receive_message_chain("invite_status.errored_creating_repo!")
      subject.perform_now(assignment, student)
    end
    it "calls Broadcaster with error message" do
      allow(CreateGitHubRepoService::Broadcaster).to receive(:call).with(anything, :create_repo, :text)
      expect(CreateGitHubRepoService::Broadcaster)
        .to receive(:call)
        .with(
          instance_of(CreateGitHubRepoService::IndividualExercise),
          "Assignment could not be created, please try again.",
          :error
        )
      subject.perform_now(assignment, student)
    end
  end
end

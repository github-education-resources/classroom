# frozen_string_literal: true

require "rails_helper"

RSpec.describe Assignment::Editor do
  subject { Assignment::Editor }

  let(:organization) { classroom_org }
  let(:assignment) { create(:assignment, organization: organization) }

  describe "#perform" do
    describe "attribute updating" do
      it "can update attributes" do
        subject.perform(assignment: assignment, options: { title: "New Title" })
        expect(assignment.title).to eq("New Title")
      end
    end

    describe "deadlines" do
      context "assignment has no deadline" do
        before do
          assignment.deadline = nil
          assignment.save
        end

        context "deadline is valid" do
          it "sets the deadline" do
            subject.perform(assignment: assignment, options: { deadline: "05/25/2100 13:17-0800" })
            expect(assignment.deadline).to be_present
          end

          it "enqueues job" do
            ActiveJob::Base.queue_adapter = :test

            expect do
              subject.perform(assignment: assignment, options: { deadline: "05/25/2100 13:17-0800" })
            end.to have_enqueued_job(DeadlineJob)
          end
        end

        context "deadline is not set" do
          it "does not set deadline" do
            subject.perform(assignment: assignment, options: {})
            expect(assignment.reload.deadline).to be_nil
          end

          it "does not enqueue job" do
            ActiveJob::Base.queue_adapter = :test

            expect do
              subject.perform(assignment: assignment, options: {})
            end.to_not have_enqueued_job(DeadlineJob)
          end
        end

        context "deadline is in the past" do
          let!(:result) { subject.perform(assignment: assignment, options: { deadline: "05/25/2005 13:17-0800" }) }

          it "does not set deadline" do
            expect(assignment.reload.deadline).to be_nil
          end

          it "returns failed result" do
            expect(result.failed?).to be_truthy
          end
        end

        context "deadline is invalid" do
          let!(:result) { subject.perform(assignment: assignment, options: { deadline: "I am not a deadline" }) }

          it "does not set deadline" do
            expect(assignment.reload.deadline).to be_nil
          end
        end
      end

      context "assignment has deadline" do
        let(:original_deadline) { Deadline::Factory.build_from_string(deadline_at: "05/25/2050 13:17-0800") }

        before do
          assignment.deadline = original_deadline
          assignment.save
        end

        context "new deadline is valid and in future" do
          it "sets the deadline" do
            subject.perform(assignment: assignment, options: { deadline: "05/25/2100 13:17-0800" })
            expect(assignment.deadline).to be_present
          end

          it "enqueues job" do
            ActiveJob::Base.queue_adapter = :test

            expect do
              subject.perform(assignment: assignment, options: { deadline: "05/25/2100 13:17-0800" })
            end.to have_enqueued_job(DeadlineJob)
          end
        end

        context "new deadline is invalid" do
          before do
            subject.perform(assignment: assignment, options: { deadline: "Not a deadlien!" })
          end

          it "does not modify the deadline" do
            expect(assignment.reload.deadline).to eq(original_deadline)
          end
        end

        context "new deadline is empty" do
          let!(:result) { subject.perform(assignment: assignment, options: { deadline: "" }) }

          it "nullifies the deadline" do
            expect(assignment.reload.deadline).to be_nil
          end

          it "returns a successful result" do
            expect(result.success?).to be_truthy
          end
        end
      end
    end

    describe "setting to private", :vcr do
      let(:plan_with_private_repos) { { owned_private_repos: 0, private_repos: 2 } }
      let(:plan_without_private_repos) { { owned_private_repos: 0, private_repos: 0 } }

      context "when we don't have private repos" do
        before do
          allow_any_instance_of(GitHubOrganization).to receive(:plan).and_return(plan_without_private_repos)

          create(:assignment_repo, assignment: assignment, github_repo_id: 2)
          assignment.public_repo = true
          assignment.save
        end

        it "does not enqueue repository visibility job" do
          ActiveJob::Base.queue_adapter = :test

          expect do
            subject.perform(assignment: assignment, options: { public_repo: false })
          end.to_not have_enqueued_job(Assignment::RepositoryVisibilityJob)
        end

        it "returns failed result" do
          result = subject.perform(assignment: assignment, options: { public_repo: false })

          expect(result.failed?).to be_truthy
        end
      end

      context "when we have private repos" do
        before do
          allow_any_instance_of(GitHubOrganization).to receive(:plan).and_return(plan_with_private_repos)

          create(:assignment_repo, assignment: assignment, github_repo_id: 2)
          assignment.public_repo = true
          assignment.save
        end

        it "does not enqueue repository visibility job" do
          ActiveJob::Base.queue_adapter = :test

          expect do
            subject.perform(assignment: assignment, options: { public_repo: false })
          end.to have_enqueued_job(Assignment::RepositoryVisibilityJob)
        end

        it "returns success result" do
          result = subject.perform(assignment: assignment, options: { public_repo: false })

          expect(result.success?).to be_truthy
        end
      end
    end
  end
end

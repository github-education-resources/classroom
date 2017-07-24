# frozen_string_literal: true

require "rails_helper"

RSpec.describe Assignment::Editor do
  subject { Assignment::Editor }

  let(:assignment) { create(:assignment) }

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

    describe "repository visibility job" do
      before do
        create(:assignment_repo, assignment: assignment)
        assignment.public_repo = false
        assignment.save
      end

      it "enqueues repository visibility job if public_repo is updated" do
        expect do
          subject.perform(assignment: assignment, options: { public_repo: true })
        end.to have_enqueued_job(Assignment::RepositoryVisibilityJob)
      end
    end
  end
end

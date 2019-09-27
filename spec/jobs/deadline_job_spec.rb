# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeadlineJob, type: :job do
  include ActiveJob::TestHelper

  let(:organization) { classroom_org }
  let(:assignment) { create(:assignment, organization: organization) }
  let(:deadline) { create(:deadline, assignment: assignment) }
  let!(:assignment_repo) { create(:assignment_repo, assignment: assignment, github_repo_id: 8514) }
  before do
    Octokit.reset!
  end

  after(:each) do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "uses the :deadline queue" do
    ActiveJob::Base.queue_adapter = :test
    expect do
      DeadlineJob.perform_later(deadline.id)
    end.to have_enqueued_job.on_queue("deadline")
  end

  it "does not throw if the deadline no longer exists" do
    id = deadline.id
    deadline.destroy

    expect { DeadlineJob.perform_now(id) }.not_to raise_error
  end

  it "sets submission sha for assignment repos", :vcr do
    DeadlineJob.perform_now(deadline.id)
    expect(assignment_repo.reload.submission_sha).to be_truthy
  end

  it "rescues Active::Record error and logs the error" do
    allow_any_instance_of(AssignmentRepo).to receive(:default_branch).and_return("master")
    allow_any_instance_of(AssignmentRepo).to receive(:commits).and_return([{ sha: "dummy-sha" }])
    allow_any_instance_of(AssignmentRepo).to receive(:save!).and_raise(ActiveRecord::ActiveRecordError)
    expect_any_instance_of(DeadlineJob).to receive(:log_error).with(assignment_repo, anything)
    DeadlineJob.perform_now(deadline.id)
  end

  it "rescues Active::Record error and logs the error" do
    allow_any_instance_of(AssignmentRepo).to receive(:default_branch).and_return("master")
    allow_any_instance_of(AssignmentRepo).to receive(:commits).and_raise(Octokit::InvalidRepository)

    expect_any_instance_of(DeadlineJob).to receive(:log_error).with(assignment_repo, anything)
    DeadlineJob.perform_now(deadline.id)
  end
end

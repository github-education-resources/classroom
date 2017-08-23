# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeadlineJob, type: :job do
  let(:organization) { classroom_org }
  let(:assignment) { create(:assignment, organization: organization) }
  let(:deadline) { create(:deadline, assignment: assignment) }

  before do
    Octokit.reset!
  end

  it "uses the :deadline queue" do
    assert_performed_with(job: DeadlineJob, args: [deadline.id], queue: "deadline") do
      DeadlineJob.perform_later(deadline.id)
    end
  end

  it "does not throw if the deadline no longer exists" do
    id = deadline.id
    deadline.destroy

    DeadlineJob.perform_now(id)
  end

  it "sets submission sha for assignment repos", :vcr do
    assignment_repo = create(:assignment_repo, assignment: assignment, github_repo_id: 8514) # rails/rails
    DeadlineJob.perform_now(deadline.id)

    expect(assignment_repo.reload.submission_sha).to be_truthy
  end
end

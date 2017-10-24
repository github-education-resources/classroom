# frozen_string_literal: true

require "rails_helper"

RSpec.describe RepoSetupJob, type: :job do
  let(:organization) { classroom_org }

  let(:assignment_repo) { create(:assignment_repo, github_repo_id: 848, organization: organization) }

  let(:unconfigured_repo) { stub_repository("template") }
  let(:configured_repo)   { stub_repository("configured-repo") }

  let(:grouping)     { create(:grouping, organization: organization) }
  let(:group)        { Group.create(title: "Group 1", grouping: grouping) }

  let(:group_assignment) do
    create(:group_assignment, title: "Learn JavaScript", organization: organization, starter_code_repo_id: 1_062_897)
  end

  let(:group_assignment_repo) do
    GroupAssignmentRepo.create(group_assignment: group_assignment, group: group)
  end

  before do
    Octokit.reset!
  end

  after do
    group.destroy
    AssignmentRepo.destroy_all
    GroupAssignmentRepo.destroy_all
  end

  it "uses the :repo_setup queue", :vcr do
    allow_any_instance_of(AssignmentRepo).to receive(:github_repository).and_return(configured_repo)
    allow_any_instance_of(GroupAssignmentRepo).to receive(:github_repository).and_return(configured_repo)

    assignment_repo.configured!
    group_assignment_repo.configured!

    assert_performed_with(job: RepoSetupJob, args: [assignment_repo], queue: "repo_setup") do
      RepoSetupJob.perform_later(assignment_repo)
    end
    assert_performed_with(job: RepoSetupJob, args: [group_assignment_repo], queue: "repo_setup") do
      RepoSetupJob.perform_later(group_assignment_repo)
    end
  end

  it "schedules another job if import is ongoing", :vcr do
    allow_any_instance_of(AssignmentRepo).to receive(:github_repository).and_return(unconfigured_repo)
    allow_any_instance_of(GroupAssignmentRepo).to receive(:github_repository).and_return(unconfigured_repo)

    state = GitHubRepository::IMPORT_ONGOING.sample

    allow(assignment_repo.github_repository).to receive(:import_progress).and_return(status: state)
    allow(group_assignment_repo.github_repository).to receive(:import_progress).and_return(status: state)

    ActiveJob::Base.queue_adapter = :test

    expect do
      RepoSetupJob.perform_now(assignment_repo)
    end.to have_enqueued_job(RepoSetupJob).with(assignment_repo)

    expect do
      RepoSetupJob.perform_now(group_assignment_repo)
    end.to have_enqueued_job(RepoSetupJob).with(group_assignment_repo)
  end

  it "does not schedule another job if configured", :vcr do
    allow_any_instance_of(AssignmentRepo).to receive(:github_repository).and_return(configured_repo)
    allow_any_instance_of(GroupAssignmentRepo).to receive(:github_repository).and_return(configured_repo)

    assignment_repo.configured!
    group_assignment_repo.configured!
    ActiveJob::Base.queue_adapter = :test

    expect do
      RepoSetupJob.perform_now(assignment_repo)
    end.not_to have_enqueued_job(RepoSetupJob).with(assignment_repo)

    expect do
      RepoSetupJob.perform_now(group_assignment_repo)
    end.not_to have_enqueued_job(RepoSetupJob).with(group_assignment_repo)
  end
end

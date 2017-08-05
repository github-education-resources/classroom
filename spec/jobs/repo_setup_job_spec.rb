# frozen_string_literal: true

require "rails_helper"

RSpec.describe RepoSetupJob, type: :job do
  let(:organization) { classroom_org }
  let(:user)         { classroom_student }

  let(:assignment)      { create(:assignment, organization: organization) }
  let(:assignment_repo) { create(:assignment_repo, assignment: assignment, user: user, github_repo_id: 848) }

  let(:unconfigured_repo) { stub_repository("template") }
  let(:configured_repo)   { stub_repository("configured-repo") }

  let(:repo_access)  { RepoAccess.create(user: user, organization: organization) }

  let(:grouping)     { create(:grouping, organization: organization) }
  let(:group)        { Group.create(title: "Group 1", grouping: grouping) }

  let(:group_assignment) do
    create(:group_assignment,
           grouping: grouping,
           title: "Learn JavaScript",
           organization: organization,
           public_repo: true,
           starter_code_repo_id: 1_062_897)
  end

  let(:group_assignment_repo) do
    group.repo_accesses << repo_access
    GroupAssignmentRepo.create(group_assignment: group_assignment, group: group)
  end

  before do
    Octokit.reset!
  end

  after(:each) do
    group.destroy
    repo_access.destroy
    AssignmentRepo.destroy_all
    GroupAssignmentRepo.destroy_all
  end

  it "uses the :repo_setup queue", :vcr do
    allow_any_instance_of(AssignmentRepo).to receive(:github_repository).and_return(configured_repo)
    allow_any_instance_of(GroupAssignmentRepo).to receive(:github_repository).and_return(configured_repo)

    assignment_repo.configured!
    group_assignment_repo.configured!

    assert_performed_with(job: RepoSetupJob, args: [AssignmentRepo.name, assignment_repo.id], queue: "repo_setup") do
      RepoSetupJob.perform_later(AssignmentRepo.name, assignment_repo.id)
    end
    assert_performed_with(job: RepoSetupJob, args: [GroupAssignmentRepo.name,
                                                    group_assignment_repo.id], queue: "repo_setup") do
      RepoSetupJob.perform_later(GroupAssignmentRepo.name, group_assignment_repo.id)
    end
  end

  it "does not throw if the assignment_repo no longer exists", :vcr do
    id   = assignment_repo.id
    g_id = group_assignment_repo.id
    assignment_repo.destroy
    group_assignment_repo.destroy

    RepoSetupJob.perform_now(AssignmentRepo.name, id)
    RepoSetupJob.perform_now(GroupAssignmentRepo.name, g_id)
  end

  it "schedules another job if import not complete", :vcr do
    allow_any_instance_of(AssignmentRepo).to receive(:github_repository).and_return(unconfigured_repo)
    allow_any_instance_of(GroupAssignmentRepo).to receive(:github_repository).and_return(unconfigured_repo)

    allow(assignment_repo.github_repository).to receive(:import_progress).and_return(status: "importing")
    allow(group_assignment_repo.github_repository).to receive(:import_progress).and_return(status: "importing")

    ActiveJob::Base.queue_adapter = :test

    expect do
      RepoSetupJob.perform_now(AssignmentRepo.name, assignment_repo.id)
    end.to have_enqueued_job(RepoSetupJob).with(AssignmentRepo.name, assignment_repo.id)

    expect do
      RepoSetupJob.perform_now(GroupAssignmentRepo.name, group_assignment_repo.id)
    end.to have_enqueued_job(RepoSetupJob).with(GroupAssignmentRepo.name, group_assignment_repo.id)
  end

  it "does not schedule another job if configured", :vcr do
    allow_any_instance_of(AssignmentRepo).to receive(:github_repository).and_return(configured_repo)
    allow_any_instance_of(GroupAssignmentRepo).to receive(:github_repository).and_return(configured_repo)

    assignment_repo.configured!
    group_assignment_repo.configured!
    ActiveJob::Base.queue_adapter = :test

    expect do
      RepoSetupJob.perform_now(AssignmentRepo.name, assignment_repo.id)
    end.not_to have_enqueued_job(RepoSetupJob).with(AssignmentRepo.name, assignment_repo.id)

    expect do
      RepoSetupJob.perform_now(GroupAssignmentRepo.name, group_assignment_repo.id)
    end.not_to have_enqueued_job(RepoSetupJob).with(GroupAssignmentRepo.name, group_assignment_repo.id)
  end
end

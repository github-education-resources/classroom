# frozen_string_literal: true

require "rails_helper"

RSpec.describe MembershipEventJob, type: :job do
  let(:payload)      { json_payload("webhook_events/team_member_removed.json") }
  let(:organization) { classroom_org }
  let(:student)      { create(:user, uid: payload.dig("member", "id")) }
  let(:repo_access)  { RepoAccess.create(user: student, organization: organization) }
  let(:group)        { Group.create(title: "Group 2", github_team_id: payload.dig("team", "id")) }

  let(:group_assignment) do
    create(:group_assignment, title: "Learn Ruby", organization: organization, public_repo: false)
  end

  let(:group_assignment_repo) do
    GroupAssignmentRepo.create(group_assignment: group_assignment, group: group)
  end

  it "removes user from team", :vcr do
    group.repo_accesses << repo_access

    MembershipEventJob.perform_now(payload)
    expect { group.repo_accesses.find_by(user_id: student.id) }.to raise_error(ActiveRecord::RecordNotFound)
  end
end

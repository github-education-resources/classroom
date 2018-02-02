# frozen_string_literal: true

require "rails_helper"

RSpec.describe MembershipEventJob, type: :job do
  let(:payload)      { json_payload("webhook_events/team_member_removed.json") }
  let(:organization) { create(:organization, github_id: payload.dig("organization", "id")) }
  let(:student)      { create(:user, uid: payload.dig("member", "id")) }
  let(:repo_access)  { RepoAccess.create(user: student, organization: organization) }
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

  before(:each) do
    group.repo_accesses << repo_access
    @group_assignment_repo = GroupAssignmentRepo.create(group_assignment: group_assignment, group: group)
  end

  context "Action removed", :vcr do
    it "removes user from team" do
      MembershipEventJob.perform_now(payload)
      expect { organization.users.find_by(uid: student.uid) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end

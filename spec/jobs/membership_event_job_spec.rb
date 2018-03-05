# frozen_string_literal: true

require "rails_helper"

RSpec.describe MembershipEventJob, type: :job do
  let(:payload)      { json_payload("webhook_events/team_member_removed.json") }
  let(:organization) { classroom_org }
  let(:student)      { classroom_student }

  context "ACTION member_removed", :vcr do
    before do
      Group.destroy_all
    end

    it "removes user from team" do
      group_assignment = create(:group_assignment, title: "Intro to Rails #2", organization: organization)
      group = Group.create(title: "GROUP",
                           github_team_id: payload.dig("team", "id"),
                           grouping: group_assignment.grouping)
      repo_access = RepoAccess.find_or_create_by!(user: student, organization: organization)

      group.repo_accesses << repo_access

      payload["member"]["id"] = student.github_user.id
      payload["member"]["login"] = student.github_user.login
      payload["team"]["id"] = group.github_team_id

      MembershipEventJob.perform_now(payload)

      expect(group.repo_accesses.find_by(user_id: student.id)).to be_nil
    end
  end
end

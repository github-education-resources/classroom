# frozen_string_literal: true

require "rails_helper"

RSpec.describe MembershipEventJob, type: :job do
  let(:payload)      { json_payload("webhook_events/team_member_removed.json") }
  let(:organization) { classroom_org }
  let(:student)      { classroom_student }

  context "ACTION member_removed", :vcr do
    it "removes user from team" do
      group_assignment = create(:group_assignment, title: "Intro to Rails #2", organization: organization)
      group = create(
        :group,

        grouping: group_assignment.grouping,
        github_team_id: payload.dig("team", "id")
      )
      repo_access = RepoAccess.find_or_create_by!(user: student, organization: organization)

      group.repo_accesses << repo_access

      payload["member"]["id"] = student.github_user.id
      payload["member"]["login"] = student.github_user.login
      payload["team"]["id"] = group.github_team_id

      MembershipEventJob.perform_now(payload)

      expect(group.repo_accesses.find_by(user_id: student.id)).to be_nil
    end

    it "returns early if user not found" do
      allow(payload).to receive(:dig).with("member", "id").and_return(nil)
      allow(payload).to receive(:dig).with("team", "id").and_return(:default)
      expect(MembershipEventJob.perform_now(payload)).to be true
    end

    it "returns early if group not found" do
      allow(payload).to receive(:dig).with("member", "id").and_return(:default)
      allow(payload).to receive(:dig).with("team", "id").and_return(nil)
      expect(MembershipEventJob.perform_now(payload)).to be true
    end

    it "returns early if repo_access not found" do
      allow_any_instance_of(Group).to receive_message_chain("repo_accesses.find_by").and_return(nil)
      expect(MembershipEventJob.perform_now(payload)).to be true
    end
  end
end

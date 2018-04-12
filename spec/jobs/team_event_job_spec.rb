# frozen_string_literal: true

require "rails_helper"

RSpec.describe TeamEventJob, type: :job do
  let(:payload)      { json_payload("webhook_events/team_deleted.json") }
  let(:organization) { classroom_org }

  context "ACTION member_removed", :vcr do
    before(:each) do
      Group.destroy_all
    end

    it "deletes team" do
      group_assignment = create(:group_assignment, title: "Intro to Rails #1", organization: organization)
      group = Group.create(title: "First group",
                           github_team_id: payload.dig("team", "id"),
                           grouping: group_assignment.grouping)

      payload["team"]["id"] = group.github_team_id

      MembershipEventJob.perform_now(payload)

      expect{ Group.find(github_team_id: group.github_team_id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end

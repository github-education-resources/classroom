# frozen_string_literal: true

require "rails_helper"

RSpec.describe TeamEventJob, type: :job do
  let(:payload)      { json_payload("webhook_events/team_deleted.json") }
  let(:organization) { classroom_org }
  let(:student) { classroom_student }

  context "ACTION team_deleted", :vcr do
    before(:each) do
      group_assignment = create(:group_assignment, title: "Intro to Go", organization: organization)
      @group = Group.create(
        title: "Random",
        github_team_id: payload.dig("team", "id"),
        grouping: group_assignment.grouping
      )
    end

    after(:each) do
      Group.destroy_all
    end

    it "deletes empty team" do
      payload["team"]["id"] = @group.github_team_id

      TeamEventJob.perform_now(payload)

      expect { Group.find(github_team_id: @group.github_team_id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "deletes team with students" do
      payload["team"]["id"] = @group.github_team_id
      repo_access = RepoAccess.find_or_create_by!(user: student, organization: organization)
      @group.repo_accesses << repo_access

      TeamEventJob.perform_now(payload)

      expect { Group.find(github_team_id: @group.github_team_id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect { @group.repo_accesses.find(user_id: student.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end

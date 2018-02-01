# frozen_string_literal: true

require "rails_helper"

RSpec.describe RepositoryEventJob, type: :job do
  let(:payload)      { json_payload("webhook_events/member_removed.json") }
 https://developer.github.com/v3/activity/events/types/#membershipevent
  context "ACTION removed", :vcr do
    after do
      Group.destroy_all
    end

    it "deletes the matching RepasAccess" do
      # group_assignment = create(:group_assignment, title: "Intro to Rails", organization: organization)
      # group            = Group.create(title: "Group 1", grouping: group_assignment.grouping)
      #
      # group_assignment_repo = GroupAssignmentRepo.create(group_assignment: group_assignment, group: group)
      #
      # payload["repository"]["id"] = group_assignment_repo.github_repo_id
      #
      # RepositoryEventJob.perform_now(payload)
      # expect { group_assignment_repo.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end

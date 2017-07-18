# frozen_string_literal: true

require "rails_helper"

RSpec.describe RepositoryEventJob, type: :job do
  let(:organization) { classroom_org                                          }
  let(:payload)      { json_payload("webhook_events/repository_deleted.json") }

  context "ACTION deleted", :vcr do
    after do
      Group.destroy_all
    end

    it "deletes the matching AssignmentRepo" do
      assignment_repo = create(:assignment_repo,
                               assignment: create(:assignment, organization: organization),
                               github_repo_id: payload.dig("repository", "id"))

      RepositoryEventJob.perform_now(payload)
      expect { assignment_repo.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    # TODO: Fixup this test so we don't have this many dependencies.
    # This is kind of ridiculous.
    it "deletes the matching GroupAssignmentRepo" do
      group_assignment = create(:group_assignment, title: "Intro to Rails", organization: organization)
      group            = Group.create(title: "Group 1", grouping: group_assignment.grouping)

      group_assignment_repo = GroupAssignmentRepo.create(group_assignment: group_assignment, group: group)

      payload["repository"]["id"] = group_assignment_repo.github_repo_id

      RepositoryEventJob.perform_now(payload)
      expect { group_assignment_repo.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end

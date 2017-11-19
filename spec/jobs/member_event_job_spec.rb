# frozen_string_literal: true

require "rails_helper"

RSpec.describe RemoveUserJob, type: :job do
  let(:organization) { classroom_org }
  let(:payload)      { json_payload("webhook_events/user_removed.json") }

  context "Action removed", :vcr do
    it "deletes user from organization" do
      github_user_id = payload.dig("member", "id")

      RemoveUserJob.perform_now(payload)
      expect { organization.users.find_by(github_id: github_user_id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end

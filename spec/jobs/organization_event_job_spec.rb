# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrganizationEventJob, type: :job do
  let(:payload) { json_payload("webhook_events/member_removed.json") }

  context "Member removed", :vcr do
    it "deletes user from organization" do
      github_user_id = payload.dig("membership", "user", "id")
      organization = create(:organization, github_id: payload.dig("organization", "id"))
      user = create(:user, uid: github_user_id, organization_ids: organization.id)
      organization.users << user

      OrganizationEventJob.perform_now(payload)
      expect { organization.users.find(uid: user.uid) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end

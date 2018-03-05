# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrganizationEventJob, type: :job do
  let(:payload) { json_payload("webhook_events/member_removed.json") }

  context "ACTION member_removed", :vcr do
    before(:each) do
      github_user_id = payload.dig("membership", "user", "id")
      @organization = create(:organization, github_id: payload.dig("organization", "id"))
      @user = create(:user, uid: github_user_id, organization_ids: @organization.id)
    end

    it "deletes user from organization" do
      @organization.users << @user

      OrganizationEventJob.perform_now(payload)

      expect { @organization.users.find(uid: @user.uid) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "deletes user from organization and transfers assignment ownership" do
      @organization.users << @user
      assignment = create(:assignment, organization: @organization, creator: @user)

      OrganizationEventJob.perform_now(payload)

      expect { @organization.users.find(uid: @user.uid) }.to raise_error(ActiveRecord::RecordNotFound)
      expect(assignment.reload.creator_id).not_to eq(@user.id)
    end
  end
end

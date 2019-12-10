# frozen_string_literal: true

require "rails_helper"
RSpec.describe OrganizationEventJob, type: :job do
  let(:payload) { json_payload("webhook_events/member_removed.json") }

  context "organization doesn't exist in classroom" do
    it "returns false" do
      expect(OrganizationEventJob.perform_now(payload)).to be_falsey
    end
  end

  context "ACTION member_removed", :vcr do
    before(:each) do
      @organization = create(:organization, github_id: payload.dig("organization", "id"))
    end

    describe "successfully" do
      before(:each) do
        github_user_id = payload.dig("membership", "user", "id")
        @user = create(:user, uid: github_user_id, organization_ids: @organization.id)
      end

      after(:each) do
        @organization.users.destroy_all
      end

      it "deletes user from organization" do
        OrganizationEventJob.perform_now(payload)

        expect { @organization.users.find(uid: @user.uid) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "deletes user from organization even if user is the only member" do
        expect(OrganizationEventJob.perform_now(payload)).to be_truthy
      end

      it "deletes user from organization and transfers assignment ownership" do
        assignment = create(:assignment, organization: @organization, creator: @user)

        OrganizationEventJob.perform_now(payload)

        expect(@organization.users).not_to include(@user)
        expect(assignment.reload.creator_id).not_to eq(@user.id)
      end

      it "deletes user from multiple organizations (classrooms) mapped to the same GitHub organization" do
        org2 = create(:organization, github_id: payload.dig("organization", "id"))
        @user.organizations << org2
        @user.save

        expect(@organization.users).to include(@user)
        expect(org2.users).to include(@user)

        OrganizationEventJob.perform_now(payload)

        expect(@organization.users).not_to include(@user)
        expect(org2.users).not_to include(@user)
      end
    end
  end
end

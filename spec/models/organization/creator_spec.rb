# frozen_string_literal: true

require "rails_helper"

RSpec.describe Organization::Creator, type: :model do
  let(:github_organization_id) { classroom_owner_organization_github_id.to_i }
  let(:user)                   { classroom_teacher                           }

  after(:each) do
    @organization.try(:destroy)
  end

  describe "::perform", :vcr do
    describe "successful creation" do
      it "creates an Organization with a webhook_id" do
        result = Organization::Creator.perform(github_id: github_organization_id, users: [user])

        expect(result.success?).to be_truthy
        expect(result.organization.github_id).to eql(github_organization_id)
      end

      it "sends an event to statd" do
        expect(GitHubClassroom.statsd).to receive(:increment).with("classroom.created")

        Organization::Creator.perform(github_id: github_organization_id, users: [user])
      end
    end

    describe "unsucessful creation" do
      it "does not allow non admins to be added" do
        non_admin_user = create(:user, uid: 1)
        result = Organization::Creator.perform(github_id: github_organization_id, users: [non_admin_user])
        expect(result.failed?).to be_truthy
      end

      it "deletes the webhook if the process could not be completed" do
        result = Organization::Creator.perform(github_id: github_organization_id, users: [])
        expect(result.failed?).to be_truthy
      end

      it "deletes the organization if the repository permissions cannot be set to none" do
        stub_request(:patch, github_url("/organizations/#{github_organization_id}"))
          .to_return(body: "{}", status: 401)

        result = Organization::Creator.perform(github_id: github_organization_id, users: [user])

        expect(result.failed?).to be_truthy
        expect(Organization.count).to eql(0)
      end
    end
  end
end

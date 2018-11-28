# frozen_string_literal: true

require "rails_helper"

RSpec.describe Organization::Creator, type: :model do
  let(:github_organization_id) { classroom_owner_organization_github_id.to_i }
  let(:user)                   { classroom_teacher                           }

  after(:each) do
    Organization.find_each(&:destroy)
  end

  describe "::perform", :vcr do
    describe "successful creation" do
      it "creates an Organization with a webhook_id" do
        result = Organization::Creator.perform(github_id: github_organization_id, users: [user])

        expect(result.success?).to be_truthy
        expect(result.organization.github_id).to eql(github_organization_id)
        expect(result.organization.webhook_id).to_not be_nil
        expect(result.organization.github_global_relay_id).to_not be_nil
      end

      it "sends an event to statd" do
        expect(GitHubClassroom.statsd).to receive(:increment).with("classroom.created")

        Organization::Creator.perform(github_id: github_organization_id, users: [user])
      end

      describe "organization_webhook model with same github_organization_id does not exist" do
        let(:organization) do
          Organization::Creator.perform(github_id: github_organization_id, users: [user]).organization
        end

        it "belongs to a new organization webhook" do
          expect(organization.organization_webhook).to be_truthy
        end

        it "has an organization webhook with a github_id" do
          expect(organization.organization_webhook.github_id).to be_truthy
        end

        it "has an organization webhook with a github_organization_id" do
          expect(organization.organization_webhook.github_organization_id).to be_truthy
        end
      end

      context "organization_webhook model with same github_organization_id exists" do
        let(:organization_webhook) { create(:organization_webhook, github_organization_id: github_organization_id) }
        let(:organization) do
          Organization::Creator.perform(github_id: github_organization_id, users: [user]).organization
        end

        before do
          organization_webhook
        end

        it "belongs to the pre existing organization webhook" do
          expect(organization.organization_webhook_id).to eq(organization_webhook.id)
        end

        it "updates the organization webhook's github_id with a more up to date github_id" do
          expected_new_webhook_id = 1_000_000
          expect_any_instance_of(Organization::Creator)
            .to receive(:create_organization_webhook!)
            .and_return(expected_new_webhook_id)

          expect(organization.organization_webhook.github_id).to eq(expected_new_webhook_id)
          expect(organization_webhook.reload.github_id).to eq(expected_new_webhook_id)
        end
      end

      context "multiple classrooms on same organization" do
        before do
          result = Organization::Creator.perform(github_id: github_organization_id, users: [user])
          @org = result.organization
        end

        it "creates a classroom with the same webhook id as the existing one" do
          result = Organization::Creator.perform(github_id: github_organization_id, users: [user])
          expect(result.organization.webhook_id).to eql(@org.webhook_id)
        end

        it "creates a classroom with the default title but incremented id" do
          result = Organization::Creator.perform(github_id: github_organization_id, users: [user])
          expect(result.organization.title).to eql("#{@org.title[0...-2]}-2")
        end
      end

      context "already created webhook on GitHub org" do
        before do
          GitHubOrganization
            .any_instance.stub(:create_organization_webhook)
            .and_raise GitHub::Error, "Hook: Hook already exists on this organization"

          @dummy_webhook_id = 12_345
          Organization::Creator
            .any_instance.stub(:get_organization_webhook_id)
            .and_return @dummy_webhook_id
        end

        it "sets webhook id to what it is already set on org" do
          result = Organization::Creator.perform(github_id: github_organization_id, users: [user])
          expect(result.organization.webhook_id).to eql(@dummy_webhook_id)
        end
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

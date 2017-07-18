# frozen_string_literal: true

require "rails_helper"

describe OrganizationDefaultRepositoryPermissionMigrator do
  describe "::perform", :vcr do
    describe "successful migration" do
      let(:org) { classroom_org }

      it "returns a success Result" do
        result = OrganizationDefaultRepositoryPermissionMigrator.perform(organization: org)

        expect(result.success?).to be_truthy
        expect(WebMock).to have_requested(:patch, github_url("/organizations/#{org.github_id}"))
          .with(body: '{"default_repository_permission":"none"}')
      end
    end

    describe "unsuccessful migration" do
      let(:org) { create(:organization, github_id: 99_999_999) }

      it "returns a failed result if the organization doesn't have users" do
        org.users = []

        result = OrganizationDefaultRepositoryPermissionMigrator.perform(organization: org)

        expect(result.failed?).to be_truthy
        expect(result.error).to eql("Organization: #{org.id} doesn't have any users")
      end

      it "returns a failed result if the organization doesn't have any authenticated admins" do
        non_admin_user = create(:user, uid: 8_675_309, token: "12345678910")
        org.users      = [non_admin_user]

        result = OrganizationDefaultRepositoryPermissionMigrator.perform(organization: org)

        expect(result.failed?).to be_truthy
        expect(result.error).to eql("Organization: #{org.id} doesn't have any users that are org admins")
      end
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe GroupsController, type: :controller do
  let(:organization)  { classroom_org     }
  let(:user)          { classroom_teacher }

  let(:grouping) { create(:grouping, organization: organization)         }
  let(:group)    { Group.create(title: "The Group", grouping: grouping)  }

  before do
    sign_in_as(user)
  end

  after(:each) do
    RepoAccess.destroy_all
    Group.destroy_all
  end

  context "flipper is enabled for the user" do
    before do
      GitHubClassroom.flipper[:team_management].enable
    end

    describe "PATCH #add_membership", :vcr do
      before do
        RepoAccess.find_or_create_by!(user: user, organization: organization)
      end

      it "correctly adds the user" do
        expect(group.repo_accesses.count).to eql(0)

        patch :add_membership, params: {
          organization_id: organization.slug,
          grouping_id: grouping.slug,
          id: group.slug,
          user_id: user.id
        }

        expect(group.repo_accesses.count).to eql(1)
      end
    end

    describe "DELETE #remove_membership", :vcr do
      before do
        repo_access = RepoAccess.find_or_create_by!(user: user, organization: organization)
        group.repo_accesses << repo_access
      end

      it "correctly removes the user" do
        expect(group.repo_accesses.count).to eql(1)

        delete :remove_membership, params: {
          organization_id: organization.slug,
          grouping_id: grouping.slug,
          id: group.slug,
          user_id: user.id
        }

        expect(group.repo_accesses.count).to eql(0)
      end

      after do
        repo_access = RepoAccess.find_or_create_by!(user: user, organization: organization)
        group.repo_accesses.delete(repo_access)
      end
    end

    after do
      GitHubClassroom.flipper[:team_management].disable
    end
  end

  context "flipper is not enabled for the user" do
    describe "PATCH #remove_membership", :vcr do
      it "returns a 404" do
        patch :add_membership, params: {
          organization_id: organization.slug,
          grouping_id: grouping.slug,
          id: group.slug, user_id: user.id
        }
        expect(response.status).to eq(404)
      end
    end

    describe "DELETE #remove_membership", :vcr do
      it "returns a 404" do
        delete :remove_membership, params: {
          organization_id: organization.slug,
          grouping_id: grouping.slug,
          id: group.slug,
          user_id: user.id
        }
        expect(response.status).to eq(404)
      end
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe API::GroupAssignmentsController, type: :controller do
  let(:organization)          { classroom_org }
  let(:user)                  { classroom_teacher }

  before do
    GitHubClassroom.flipper[:download_repositories].enable

    @group_assignment = create(:group_assignment, organization: organization)
  end

  describe "GET #index", :vcr do
    before do
      get :index, params: { organization_id: organization.slug, access_token: user.api_token }
    end

    it "returns success" do
      expect(response).to have_http_status(:success)
    end

    it "returns only one assignment" do
      expect(json.length).to eql(1)
    end
  end

  describe "GET #show", :vcr do
    before do
      get :show, params: {
        organization_id: organization.slug,
        id: @group_assignment.slug,
        access_token: user.api_token,
      }
    end

    it "returns success" do
      expect(response).to have_http_status(:success)
    end

    context "group assignment serializer returns correct attributes" do
      it "returns assignment id" do
        expect(json["id"]).to eq(@group_assignment.id)
      end

      it "returns assignment title" do
        expect(json["title"]).to eq(@group_assignment.title)
      end

      it "returns assignment type" do
        expect(json["type"]).to eq("group")
      end

      it "returns organization github id" do
        expect(json["organizationGithubId"]).to eq(organization.github_id)
      end
    end
  end

  after do
    GitHubClassroom.flipper[:download_repositories].disable
  end
end

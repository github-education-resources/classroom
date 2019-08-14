# frozen_string_literal: true

require "rails_helper"

RSpec.describe API::GroupAssignmentReposController, type: :controller do
  let(:organization)      { classroom_org }
  let(:user)              { classroom_teacher }
  let(:student)      { classroom_student }
  let(:grouping)     { create(:grouping, organization: organization) }
  let(:github_team_id) { 3_284_880 }
  let(:group) { create(:group, grouping: grouping, github_team_id: github_team_id) }
  let(:group_assignment) do
    create(
      :group_assignment,
      grouping: grouping,
      title: "Learn JavaScript",
      organization: organization,
      public_repo: true,
      starter_code_repo_id: 1_062_897
    )
  end
  let(:group_assignment_repo) do
    create(
      :group_assignment_repo,
      group_assignment: group_assignment,
      group: group,
      organization: organization,
      github_repo_id: 42
    )
  end
  let(:params) do
    {
      organization_id: organization.slug,
      group_assignment_id: group_assignment.slug,
      group_assignment_repo_id: group_assignment_repo.id,
      access_token: user.api_token
    }
  end
  describe "GET #index", :vcr do
    before do
      get :index, params: {
        organization_id: organization.slug,
        group_assignment_id: group_assignment.slug,
        access_token: user.api_token,
        group_assignment_repo_id: group_assignment_repo.id
      }
    end

    after do
      GroupAssignmentRepo.destroy_all
    end

    it "returns success" do
      expect(response).to have_http_status(:success)
    end

    it "returns correct attributes in group assignment repo serializer" do
      expect(json.first["username"]).to eq(group.title)
      expect(json.first["displayName"]).to eq("")
    end
  end

  describe "GET #clone_url", :vcr do
    after do
      GroupAssignmentRepo.destroy_all
    end

    it "returns success" do
      get :clone_url, params: params
      expect(response).to have_http_status(:success)
    end

    it "returns json with temp clone url" do
      get :clone_url, params: params
      expect(json["temp_clone_url"]).to_not be_nil
    end

    it "returns 404 if invalid repository found" do
      allow_any_instance_of(GroupAssignmentRepo).to receive(:present?).and_return(false)
      get :clone_url, params: params
      expect(json).to eq("error" => "not_found")
      expect(response.status).to eq(404)
    end
  end
end

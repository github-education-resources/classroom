# frozen_string_literal: true

require "rails_helper"

RSpec.describe API::GroupAssignmentReposController, type: :controller do
  let(:organization)      { classroom_org }
  let(:user)              { classroom_teacher }
  let(:student)      { classroom_student }
  let(:grouping)     { create(:grouping, organization: organization) }
  let(:github_team_id) { organization.github_organization.create_team(Faker::Team.name).id }
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
  describe "GET #index", :vcr do
    before do
      GroupAssignmentRepo::Creator.perform(group_assignment: group_assignment, group: group)
      get :index, params: {
        organization_id: organization.slug,
        group_assignment_id: group_assignment.slug,
        access_token: user.api_token
      }
    end

    after do
      organization.github_organization.delete_team(group.github_team_id)
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
    before do
      result = GroupAssignmentRepo::Creator.perform(group_assignment: group_assignment, group: group)
      group_assignment_repo = result.group_assignment_repo
      get :clone_url, params: {
        organization_id: organization.slug,
        group_assignment_id: group_assignment.slug,
        group_assignment_repo_id: group_assignment_repo.id,
        access_token: user.api_token
      }
    end

    after do
      GroupAssignmentRepo.destroy_all
    end

    it "returns success" do
      expect(response).to have_http_status(:success)
    end

    it "returns json with temp clone url" do
      expect(json["temp_clone_url"]).to_not be_nil
    end
  end
end

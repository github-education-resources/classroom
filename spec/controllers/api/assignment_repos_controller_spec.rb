# frozen_string_literal: true

require "rails_helper"

RSpec.describe API::AssignmentReposController, type: :controller do
  let(:organization)      { classroom_org }
  let(:user)              { classroom_teacher }
  let(:assignment)        { create(:assignment, organization: organization, title: "Learn Clojure") }

  describe "GET #index", :vcr do
    before do
      @assignment_repo = create(:assignment_repo, assignment: assignment, github_repo_id: 42, user: user)

      get :index, params: {
        organization_id: organization.slug,
        assignment_id: assignment.slug,
        access_token: user.api_token
      }
    end

    after do
      AssignmentRepo.destroy_all
    end

    it "returns success" do
      expect(response).to have_http_status(:success)
    end

    it "returns all of the assignment repos" do
      expect(json.length).to eql(1)
    end

    it "returns correct attributes in assignment repo serializer" do
      expect(json.first["username"]).to eq(user.github_user.login)
      expect(json.first["displayName"]).to eq(user.github_user.name)
    end
  end

  describe "GET #clone_url", :vcr do
    let(:assignment_repo) { create(:assignment_repo, assignment: assignment, github_repo_id: 42, user: user) }
    let(:params) do
      {
        organization_id: organization.slug,
        assignment_id: assignment.slug,
        assignment_repo_id: assignment_repo.id,
        access_token: user.api_token
      }
    end

    after do
      AssignmentRepo.destroy_all
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
      allow_any_instance_of(AssignmentRepo).to receive(:present?).and_return(false)
      get :clone_url, params: params
      expect(json).to eq("error" => "not_found")
      expect(response.status).to eq(404)
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe API::AssignmentReposController, type: :controller do
  let(:organization)      { classroom_org }
  let(:user)              { classroom_teacher }
  let(:assignment)        { create(:assignment, organization: organization, title: "Learn Clojure") }

  before do
    GitHubClassroom.flipper[:download_repositories].enable
  end

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

    context "assignment repo serializer returns correct attributes" do
      it "returns repo username" do
        expect(json.first["username"]).to eq(user.github_user.login)
      end

      it "returns repo url" do
        expect(json.first["repoUrl"]).to eq(@assignment_repo.github_repository.html_url)
      end

      it "returns user display name" do
        expect(json.first["displayName"]).to eq(user.github_user.name)
      end
    end
  end

  after do
    GitHubClassroom.flipper[:download_repositories].disable
  end
end

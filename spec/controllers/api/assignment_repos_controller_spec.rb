# frozen_string_literal: true

require "rails_helper"

RSpec.describe API::AssignmentReposController, type: :controller do
  let(:organization)      { classroom_org                                                           }
  let(:user)              { classroom_teacher                                                       }
  let(:assignment)        { create(:assignment, organization: organization, title: "Learn Clojure") }

  before do
    sign_in_as(user)
  end

  describe "GET #index", :vcr do
    before do
      @assignment_repo = create(:assignment_repo, assignment: assignment, github_repo_id: 42, user: user)
      @assignment_repo_json = AssignmentRepoSerializer.new(@assignment_repo).to_json

      get :index, params: { organization_id: organization.slug, assignment_id: assignment.slug }
    end

    after do
      AssignmentRepo.destroy_all
    end

    it "returns success" do
      expect(response).to have_http_status(:success)
    end

    it "returns serialized individual assignment repo" do
      expect(json.first.to_json).to eq(@assignment_repo_json)
    end
  end
end

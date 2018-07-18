# frozen_string_literal: true

require "rails_helper"

RSpec.describe API::GroupAssignmentReposController, type: :controller do
  let(:organization)      { classroom_org                                                                   }
  let(:user)              { classroom_teacher                                                               }
  let(:group_assignment)  { create(:group_assignment, organization: organization, title: "Learn Clojure")   }
  let(:group)             { Group.create(title: "The Group", grouping: group_assignment.grouping)           }

  before do
    GitHubClassroom.flipper[:download_repositories].enable
    sign_in_as(user)
  end

  describe "GET #index", :vcr do
    before do
      @group_assignment_repo = GroupAssignmentRepo.create(group_assignment: group_assignment, group: group)
      @group_assignment_repo_json = GroupAssignmentRepoSerializer.new(@group_assignment_repo).to_json

      get :index, params: { organization_id: organization.slug, group_assignment_id: group_assignment.slug }
    end

    after do
      GroupAssignmentRepo.destroy_all
      Grouping.destroy_all
    end

    it "returns success" do
      expect(response).to have_http_status(:success)
    end

    it "returns serialized group assignment repo" do
      expect(json.first.to_json).to eq(@group_assignment_repo_json)
    end
  end

  after do
    GitHubClassroom.flipper[:download_repositories].disable
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Stafftools::GroupAssignmentReposController, type: :controller do
  let(:user)         { classroom_teacher }
  let(:organization) { classroom_org     }
  let(:student)      { classroom_student }
  let(:repo_access)  { RepoAccess.create(user: student, organization: organization) }
  let(:group_assignment) do
    create(:group_assignment, title: "Learn Ruby", organization: organization, public_repo: false)
  end
  let(:github_team_id) { organization.github_organization.create_team(Faker::Team.name[0..39]).id }
  let(:group) { create(:group, grouping: group_assignment.grouping, github_team_id: github_team_id) }
  let(:result) { GroupAssignmentRepo::Creator.perform(group_assignment: group_assignment, group: group) }
  let(:group_assignment_repo) { result.group_assignment_repo }

  before(:each) do
    sign_in_as(user)
  end

  after do
    GroupAssignmentRepo.destroy_all
  end

  after(:each) do
    organization.github_organization.delete_team(group.github_team_id)
  end

  describe "GET #show", :vcr do
    context "as an unauthorized user" do
      it "returns a 404" do
        get :show, params: { id: group_assignment_repo.id }
        expect(response.status).to eq(404)
      end
    end

    context "as an authorized user" do
      before do
        user.update_attributes(site_admin: true)
        get :show, params: { id: group_assignment_repo.id }
      end

      it "succeeds" do
        expect(response).to have_http_status(:success)
      end

      it "sets the GroupAssignmentRepo" do
        expect(assigns(:group_assignment_repo).id).to eq(group_assignment_repo.id)
      end
    end
  end

  describe "DELETE #destroy", :vcr do
    context "as an unauthorized user" do
      it "returns a 404" do
        delete :destroy, params: { id: group_assignment_repo.id }
        expect(response.status).to eq(404)
      end
    end

    context "as an authorized user" do
      before do
        user.update_attributes(site_admin: true)
        delete :destroy, params: { id: group_assignment_repo.id }
      end

      it "deletes the assignment repo" do
        expect { group_assignment_repo.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "redirects to the assignment show page" do
        expect(response).to redirect_to(stafftools_group_assignment_path(group_assignment.id))
      end
    end
  end
end

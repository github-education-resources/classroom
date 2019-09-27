# frozen_string_literal: true

require "rails_helper"

RSpec.describe Stafftools::GroupsController, type: :controller do
  let(:user)         { classroom_teacher }
  let(:organization) { classroom_org     }

  let(:grouping) { create(:grouping, organization: organization) }
  let(:github_team_id) { organization.github_organization.create_team(Faker::Team.name[0..39]).id }
  let(:group) { create(:group, grouping: grouping, github_team_id: github_team_id) }

  before(:each) do
    sign_in_as(user)
  end

  after(:each) do
    organization.github_organization.delete_team(group.github_team_id)
  end

  describe "GET #show", :vcr do
    context "as an unauthorized user" do
      it "returns a 404" do
        get :show, params: { id: group.id }
        expect(response.status).to eq(404)
      end
    end

    context "as an authorized user" do
      before do
        user.update_attributes(site_admin: true)
        get :show, params: { id: group.id }
      end

      it "succeeds" do
        expect(response).to have_http_status(200)
      end

      it "sets the GroupAssignment" do
        expect(assigns(:group).id).to eq(group.id)
      end
    end
  end

  describe "DELETE #destroy", :vcr do
    context "as an unauthorized user" do
      before do
        delete :destroy, params: { id: group.id }
      end

      it "returns a 404" do
        expect(response.status).to eq(404)
      end
    end

    context "as an authorized user" do
      before do
        user.update_attributes(site_admin: true)
        delete :destroy, params: { id: group.id }
      end

      it "deletes the group" do
        expect(Group.find_by(id: group.id)).to be_nil
      end

      it "shows an informative message" do
        expect(flash[:success]).to eq("Group was destroyed")
      end

      it "redirects to grouping page" do
        expect(response).to redirect_to(stafftools_grouping_path(group.grouping.id))
      end
    end
  end
end

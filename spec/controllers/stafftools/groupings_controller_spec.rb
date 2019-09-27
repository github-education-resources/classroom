# frozen_string_literal: true

require "rails_helper"

RSpec.describe Stafftools::GroupingsController, type: :controller do
  let(:organization) { classroom_org }
  let(:user)         { organization.users.first }
  let(:grouping)     { Grouping.create(organization: organization, title: "Grouping 1") }

  let(:group_assignment) do
    create(:group_assignment, creator: user, organization: organization, grouping: grouping)
  end

  before(:each) do
    sign_in_as(user)
  end

  describe "GET #show", :vcr do
    context "as an unauthorized user" do
      it "returns a 404" do
        get :show, params: { id: grouping.id }
        expect(response.status).to eq(404)
      end
    end

    context "as an authorized user" do
      before do
        user.update_attributes(site_admin: true)
        get :show, params: { id: grouping.id }
      end

      it "succeeds" do
        expect(response).to have_http_status(200)
      end

      it "sets the Grouping" do
        expect(assigns(:grouping).id).to eq(grouping.id)
      end
    end
  end

  describe "DELETE #destroy", :vcr do
    context "as an unauthorized user" do
      before do
        delete :destroy, params: { id: grouping.id }
      end

      it "returns a 404" do
        expect(response.status).to eq(404)
      end
    end

    context "as an authorized user" do
      before do
        group_assignment.save
        user.update_attributes(site_admin: true)

        delete :destroy, params: { id: grouping.id }
      end

      it "destroys grouping" do
        expect(Grouping.find_by(id: grouping.id)).to be_nil
      end

      it "destroys group assignments" do
        expect(GroupAssignment.find_by(id: group_assignment.id)).to be_nil
      end

      it "shows a success message" do
        expect(flash[:success]).to eq("Grouping was destroyed")
      end

      it "redirects to org path" do
        expect(response).to redirect_to(stafftools_organization_path(organization.id))
      end
    end
  end
end

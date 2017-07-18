# frozen_string_literal: true

require "rails_helper"

RSpec.describe Stafftools::GroupsController, type: :controller do
  let(:user)         { classroom_teacher }
  let(:organization) { classroom_org     }

  let(:grouping) { create(:grouping, organization: organization)         }
  let(:group)    { Group.create(grouping: grouping, title: "The B Team") }

  before(:each) do
    sign_in_as(user)
  end

  after do
    Group.destroy_all
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
        expect(response).to have_http_status(:success)
      end

      it "sets the GroupAssignment" do
        expect(assigns(:group).id).to eq(group.id)
      end
    end
  end
end

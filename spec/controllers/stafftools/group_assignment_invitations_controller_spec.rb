# frozen_string_literal: true

require "rails_helper"

RSpec.describe Stafftools::GroupAssignmentInvitationsController, type: :controller do
  let(:organization) { classroom_org     }
  let(:user)         { classroom_teacher }

  let(:group_assignment_invitation) { create(:group_assignment_invitation) }

  before(:each) do
    sign_in_as(user)
  end

  describe "GET #show", :vcr do
    context "as an unauthorized user" do
      it "returns a 404" do
        get :show, params: { id: group_assignment_invitation.id }
        expect(response.status).to eq(404)
      end
    end

    context "as an authorized user" do
      before do
        user.update_attributes(site_admin: true)
        get :show, params: { id: group_assignment_invitation.id }
      end

      it "succeeds" do
        expect(response).to have_http_status(:success)
      end

      it "sets the GroupAssignmentInvitation" do
        expect(assigns(:group_assignment_invitation).id).to eq(group_assignment_invitation.id)
      end
    end
  end
end

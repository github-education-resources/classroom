# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Stafftools::AssignmentInvitationsController, type: :controller do
  let(:user) { GitHubFactory.create_owner_classroom_org.users.first }

  before do
    assignment = build(:assignment, creator: user, organization: user.organizations.first)
    @assignment_invitation = assignment.build_assignment_invitation
    assignment.save!
  end

  before(:each) do
    sign_in(user)
  end

  describe 'GET #show', :vcr do
    context 'as an unauthorized user' do
      it 'returns a 404' do
        expect { get :show, params: { id: @assignment_invitation.id } }.to raise_error(ActionController::RoutingError)
      end
    end

    context 'as an authorized user' do
      before do
        user.update_attributes(site_admin: true)
        get :show, params: { id: @assignment_invitation.id }
      end

      it 'succeeds' do
        expect(response).to have_http_status(:success)
      end

      it 'sets the AssignmentInvitation' do
        expect(assigns(:assignment_invitation).id).to eq(@assignment_invitation.id)
      end
    end
  end
end

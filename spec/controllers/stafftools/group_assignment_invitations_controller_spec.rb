require 'rails_helper'

RSpec.describe Stafftools::GroupAssignmentInvitationsController, type: :controller do
  let(:user) { GitHubFactory.create_owner_classroom_org.users.first }

  before do
    group_assignment = build(:group_assignment, creator: user, organization: user.organizations.first)
    @group_assignment_invitation = group_assignment.build_group_assignment_invitation
    group_assignment.save!
  end

  before(:each) do
    sign_in(user)
  end

  describe 'GET #show', :vcr do
    context 'as an unauthorized user' do
      it 'returns a 404' do
        expect { get :show, id: @group_assignment_invitation.id }.to raise_error(ActionController::RoutingError)
      end
    end

    context 'as an authorized user' do
      before do
        user.update_attributes(site_admin: true)
        get :show, id: @group_assignment_invitation.id
      end

      it 'succeeds' do
        expect(response).to have_http_status(:success)
      end

      it 'sets the GroupAssignmentInvitation' do
        expect(assigns(:group_assignment_invitation).id).to eq(@group_assignment_invitation.id)
      end
    end
  end
end

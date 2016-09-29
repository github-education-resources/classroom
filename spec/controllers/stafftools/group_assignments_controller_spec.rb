# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Stafftools::GroupAssignmentsController, type: :controller do
  let(:user)         { GitHubFactory.create_owner_classroom_org.users.first }
  let(:organization) { user.organizations.first                             }

  let(:grouping) { Grouping.create(organization: organization, title: 'Grouping 1') }

  let(:group_assignment) do
    GroupAssignment.create(creator: user,
                           title: 'Learn Ruby',
                           slug: 'learn-ruby',
                           organization: organization,
                           grouping: grouping,
                           public_repo: false)
  end

  before(:each) do
    sign_in(user)
  end

  describe 'GET #show', :vcr do
    context 'as an unauthorized user' do
      it 'returns a 404' do
        expect do
          get :show, params: { id: group_assignment.id }
        end.to raise_error(ActionController::RoutingError)
      end
    end

    context 'as an authorized user' do
      before do
        user.update_attributes(site_admin: true)
        get :show, params: { id: group_assignment.id }
      end

      it 'succeeds' do
        expect(response).to have_http_status(:success)
      end

      it 'sets the GroupAssignment' do
        expect(assigns(:group_assignment).id).to eq(group_assignment.id)
      end
    end
  end
end

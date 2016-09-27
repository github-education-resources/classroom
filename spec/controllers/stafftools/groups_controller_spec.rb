# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Stafftools::GroupsController, type: :controller do
  let(:user)         { GitHubFactory.create_owner_classroom_org.users.first }
  let(:organization) { user.organizations.first                             }

  let(:grouping) { Grouping.create(organization: organization, title: 'Grouping 1') }
  let(:group)    { Group.create(grouping: grouping, title: 'The B Team')            }

  before(:each) do
    sign_in(user)
  end

  after do
    Group.destroy_all
  end

  describe 'GET #show', :vcr do
    context 'as an unauthorized user' do
      it 'returns a 404' do
        expect { get :show, params: { id: group.id } }.to raise_error(ActionController::RoutingError)
      end
    end

    context 'as an authorized user' do
      before do
        user.update_attributes(site_admin: true)
        get :show, params: { id: group.id }
      end

      it 'succeeds' do
        expect(response).to have_http_status(:success)
      end

      it 'sets the GroupAssignment' do
        expect(assigns(:group).id).to eq(group.id)
      end
    end
  end
end

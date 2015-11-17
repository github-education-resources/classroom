require 'rails_helper'

RSpec.describe StafftoolsController, type: :controller do
  let(:organization) { GitHubFactory.create_owner_classroom_org }
  let(:user)         { organization.users.first                 }

  before(:each) do
    sign_in(user)
  end

  describe 'GET #resources', :vcr do
    context 'as an unauthorized user' do
      it 'returns a 404' do
        expect { get :search }.to raise_error(ActionController::RoutingError)
      end
    end

    context 'as an authorized user' do
      before do
        user.update_attributes(site_admin: true)
      end

      before(:each) do
        get :resources
      end

      it 'returns a success status' do
        expect(response).to have_http_status(:success)
      end

      it 'has a StafftoolsIndex::User::Query of resources' do
        expect(assigns(:resources)).to_not be_nil
        expect(assigns(:resources)).to be_kind_of(StafftoolsIndex::User::Query)
      end
    end
  end

  describe 'GET #search', :vcr do
    context 'as an unauthorized user' do
      it 'returns a 404' do
        expect { get :search }.to raise_error(ActionController::RoutingError)
      end
    end

    context 'as an authorized user' do
      before do
        user.update_attributes(site_admin: true)
      end

      before(:each) do
        get :search
      end

      it 'returns a succcess status' do
        expect(response).to have_http_status(:success)
      end

      it 'has a StafftoolsIndex::User::Query of resources' do
        expect(assigns(:resources)).to_not be_nil
        expect(assigns(:resources)).to be_kind_of(StafftoolsIndex::User::Query)
      end
    end
  end
end

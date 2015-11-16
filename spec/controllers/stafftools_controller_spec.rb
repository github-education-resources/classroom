require 'rails_helper'

RSpec.describe StafftoolsController, type: :controller do
  let(:organization) { GitHubFactory.create_owner_classroom_org }
  let(:user)         { organization.users.first                 }

  before(:each) do
    sign_in(user)
  end

  describe 'GET #impersonate', :vcr do
    context 'as an unauthorized user' do
      it 'returns a 404' do
        expect { get :impersonate }.to raise_error(ActionController::RoutingError)
      end
    end

    context 'as an authorized user' do
      before do
        user.update_attributes(site_admin: true)
      end

      it 'returns a success status' do
        get :impersonate
        expect(response).to have_http_status(:success)
      end

      it 'as an array of user search results' do
        get :impersonate

        expect(assigns(:users)).to_not be_nil

        expect(assigns(:users)).to respond_to(:total_count)
        expect(assigns(:users)).to be_kind_of(UsersIndex::User::Query)
      end
    end
  end
end

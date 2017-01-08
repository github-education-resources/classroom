# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Stafftools::OrganizationsController, type: :controller do
  let(:organization) { classroom_org     }
  let(:user)         { classroom_teacher }

  before(:each) do
    sign_in(user)
  end

  describe 'GET #show', :vcr do
    context 'as an unauthorized user' do
      it 'returns a 404' do
        expect { get :show, params: { id: organization.id } }.to raise_error(ActionController::RoutingError)
      end
    end

    context 'as an authorized user' do
      before do
        user.update_attributes(site_admin: true)
        get :show, params: { id: organization.id }
      end

      it 'succeeds' do
        expect(response).to have_http_status(:success)
      end

      it 'sets the organization' do
        expect(assigns(:organization).id).to eq(organization.id)
      end
    end
  end
end

# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Stafftools::OrganizationsController, type: :controller do
  let(:organization) { GitHubFactory.create_owner_classroom_org }
  let(:user)         { organization.users.first }

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

  describe 'DELETE #remove_user', :vcr do
    context 'as an unauthorized user' do
      it 'returns a 404' do
        expect { delete :remove_user, params: { id: organization.id, user_id: user.id } }
          .to raise_error(ActionController::RoutingError)
      end
    end

    context 'as an authorized user, remove fails on GitHub end' do
      before do
        user.update_attributes(site_admin: true)
        allow_any_instance_of(GitHubOrganization).to receive(:remove_organization_member).and_return(false)
        delete :remove_user, params: { id: organization.id, user_id: user.id }
      end

      it 'shows informative flash message' do
        expect(flash[:error]).to eql('Could not remove the owner')
      end

      it 'does not remove user from the Organization' do
        expect(organization.users.reload.include?(user)).to be_truthy
      end
    end

    context 'as an authorized user, remove succeeds on GitHub end' do
      before do
        user.update_attributes(site_admin: true)
        allow_any_instance_of(GitHubOrganization).to receive(:remove_organization_member).and_return(true)
        delete :remove_user, params: { id: organization.id, user_id: user.id }
      end

      it 'deletes user from the Organization' do
        expect(organization.users.reload.include?(user)).to be_falsey
      end

      it 'redirects to stafftools organization path' do
        expect(response).to redirect_to(stafftools_organization_path(organization.id))
      end
    end
  end
end

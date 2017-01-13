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

    context 'as an authorized user' do
      before do
        user.update_attributes(site_admin: true)
      end

      context 'when user does not own any assignments' do
        before do
          delete :remove_user, params: { id: organization.id, user_id: user.id }
        end

        it 'deletes user from the Organization' do
          expect(organization.users.reload.include?(user)).to be_falsey
        end

        it 'displays a helpful flash success message' do
          expect(flash[:success]).to eq('The user has been removed from the classroom')
        end

        it 'redirects to stafftools organization path' do
          expect(response).to redirect_to(stafftools_organization_path(organization.id))
        end
      end

      context 'when user owns at least one assignment' do
        before do
          Assignment.create(creator: user,
                            organization: organization,
                            title: 'Title',
                            slug: 'ABCDE')

          delete :remove_user, params: { id: organization.id, user_id: user.id }
        end

        it 'does not delete the user from the Organization' do
          expect(organization.users.reload.include?(user)).to be_truthy
        end

        it 'displays an error flash message' do
          expect(flash[:error]).to eq('This user owns at least one assignment and cannot be deleted')
        end

        it 'redirects to stafftools organization path' do
          expect(response).to redirect_to(stafftools_organization_path(organization.id))
        end
      end
    end
  end
end

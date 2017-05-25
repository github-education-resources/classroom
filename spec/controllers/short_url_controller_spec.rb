# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ShortUrlController, type: :controller do
  describe 'authenticated request' do
    let(:user) { classroom_student }

    before do
      sign_in_as(user)
    end

    describe 'GET #accept_assignment', :vcr do
      let(:invitation) { create(:assignment_invitation) }

      context 'key is invalid' do
        it 'responds with a 404' do
          expect do
            get :accept_assignment, params: { short_key: 'WRONG' }
          end.to raise_error ActionController::RoutingError
        end
      end

      context 'key is valid' do
        before do
          key = invitation.short_key

          get :accept_assignment, params: { short_key: key }
        end

        it 'responds with a 302' do
          expect(response).to have_http_status(302)
        end

        it 'redirects to the accept assignment page' do
          expect(response).to redirect_to "/assignment-invitations/#{invitation.key}"
        end
      end
    end

    describe 'GET #accept_group_assignment', :vcr do
      let(:invitation) { create(:group_assignment_invitation) }

      context 'key is invalid' do
        it 'responds with a 404' do
          expect do
            get :accept_group_assignment, params: { short_key: 'WRONG' }
          end.to raise_error ActionController::RoutingError
        end
      end

      context 'key is valid' do
        before do
          key = invitation.short_key

          get :accept_group_assignment, params: { short_key: key }
        end

        it 'responds with a 302' do
          expect(response).to have_http_status(302)
        end

        it 'redirects to the accept group assignment page' do
          expect(response).to redirect_to "/group-assignment-invitations/#{invitation.key}"
        end
      end
    end
  end
end

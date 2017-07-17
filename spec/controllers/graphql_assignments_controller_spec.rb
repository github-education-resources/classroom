# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GraphqlAssignmentsController, type: :controller do
  let(:organization) { classroom_org     }
  let(:user)         { classroom_teacher }

  let(:assignment)   { create(:assignment, organization: organization) }

  before(:each) do
    sign_in_as(user)
  end

  describe 'GET #show', :vcr do
    context 'with the flipper not enabled' do
      context 'as an unauthorized user' do
        it 'returns a 404' do
          get :show, params: { id: assignment.slug, organization_id: organization.slug }
          expect(response).to have_http_status(:not_found)
        end
      end

      context 'as an authorized user' do
        before do
          user.update_attributes(site_admin: true)
          get :show, params: { id: assignment.slug, organization_id: organization.slug }
        end

        it 'returns a 404' do
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context 'with the flipper enabled' do
      before do
        GitHubClassroom.flipper[:graphql].enable
      end

      context 'as an unauthorized user' do
        it 'returns a 404' do
          get :show, params: { id: assignment.slug, organization_id: organization.slug }
          expect(response).to have_http_status(:not_found)
        end
      end

      context 'as an authorized user' do
        before do
          user.update_attributes(site_admin: true)
          get :show, params: { id: assignment.slug, organization_id: organization.slug }
        end

        it 'succeeds' do
          expect(response).to have_http_status(:success)
        end
      end

      after do
        GitHubClassroom.flipper[:graphql].disable
      end
    end
  end
end

# frozen_string_literal: true
require 'rails_helper'

RSpec.describe GroupingsController, type: :controller do
  include ActiveJob::TestHelper

  let(:organization)  { GitHubFactory.create_owner_classroom_org }
  let(:user)          { organization.users.first                 }
  let(:grouping)      { Grouping.create(title: 'Grouping 1', organization: organization) }

  before do
    sign_in(user)
  end

  context 'flipper is enabled for the user' do
    before do
      Classroom.flipper[:team_management].enable
    end

    describe 'GET #show', :vcr do
      it 'returns success status' do
        get :show, organization_id: organization.slug, id: grouping.slug

        expect(response.status).to eq(200)
        expect(assigns(:grouping)).to_not be_nil
      end
    end

    after do
      Classroom.flipper[:team_management].disable
    end
  end

  context 'flipper is not enabled for the user' do
    describe 'GET #show', :vcr do
      it 'returns a 404' do
        expect do
          get :show,
              organization_id: organization.slug,
              id: grouping.slug
        end.to raise_error(ActionController::RoutingError)
      end
    end
  end

  describe 'GET #edit', :vcr do
    it 'returns success status' do
      get :edit, organization_id: organization.slug, id: grouping.id

      expect(response.status).to eq(200)
      expect(assigns(:grouping)).to_not be_nil
    end
  end

  describe 'PATCH #update', :vcr do
    it 'correctly updates the grouping' do
      options = { title: 'Fall 2015' }
      patch :update, organization_id: organization.slug, id: grouping.id, grouping: options

      expect(response).to redirect_to(settings_teams_organization_path(organization))
    end
  end
end

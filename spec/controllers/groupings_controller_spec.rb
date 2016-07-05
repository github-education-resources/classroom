# frozen_string_literal: true
require 'rails_helper'

RSpec.describe GroupingsController, type: :controller do
  include ActiveJob::TestHelper

  let(:organization)  { GitHubFactory.create_owner_classroom_org }
  let(:user)          { organization.users.first                 }
  let(:grouping)      { Grouping.create(title: 'Grouping 1', organization: organization) }

  before do
    sign_in(user)
    Classroom.flipper[:team_management].enable
  end

  describe 'GET #show', :vcr do
    it 'returns success status' do
      get :show, organization_id: organization.slug, id: grouping.slug

      expect(response.status).to eq(200)
      expect(assigns(:grouping)).to_not be_nil
    end
  end
end

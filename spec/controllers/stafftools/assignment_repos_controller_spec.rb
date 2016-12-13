# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Stafftools::AssignmentReposController, type: :controller do
  let(:organization) { GitHubFactory.create_owner_classroom_org }
  let(:user)         { organization.users.first }

  let(:assignment_repo) do
    assignment = create(:assignment, organization: organization)
    create(:assignment_repo, github_repo_id: 42, assignment: assignment)
  end

  before(:each) do
    sign_in(user)
  end

  describe 'GET #show', :vcr do
    context 'as an unauthorized user' do
      it 'returns a 404' do
        expect do
          get :show, params: { id: assignment_repo.id }
        end.to raise_error(ActionController::RoutingError)
      end
    end

    context 'as an authorized user' do
      before do
        user.update_attributes(site_admin: true)
        get :show, params: { id: assignment_repo.id }
      end

      it 'succeeds' do
        expect(response).to have_http_status(:success)
      end

      it 'sets the AssignmentRepo' do
        expect(assigns(:assignment_repo).id).to eq(assignment_repo.id)
      end
    end
  end
end

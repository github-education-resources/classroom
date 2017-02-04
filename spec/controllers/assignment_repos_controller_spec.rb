# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AssignmentReposController, type: :controller do
  let(:organization) { classroom_org     }
  let(:user)         { classroom_teacher }

  let(:assignment)      { create(:assignment, organization: organization) }
  let(:assignment_repo) { create(:assignment_repo, github_repo_id: 42, assignment: assignment) }

  before(:each) do
    sign_in_as(user)
  end

  describe 'GET #show', :vcr do
    context 'unauthenticated user' do
      before do
        sign_out
      end

      it 'redirect to login path' do
        get :show, params: { organization_id: organization.slug, assignment_id: assignment.id, id: assignment_repo.id }
        expect(response).to redirect_to(login_path)
      end
    end

    context 'authenticated user' do
      before do
        get :show, params: { organization_id: organization.slug, assignment_id: assignment.id, id: assignment_repo.id }
      end

      it 'returns success status' do
        expect(response).to have_http_status(:success)
      end

      it 'sets the AssignmentRepo' do
        expect(assigns[:assignment_repo].id).to eql(assignment_repo.id)
      end
    end
  end
end

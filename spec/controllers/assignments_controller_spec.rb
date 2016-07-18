# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AssignmentsController, type: :controller do
  include ActiveJob::TestHelper

  let(:organization) { GitHubFactory.create_owner_classroom_org }
  let(:user)         { organization.users.first                 }

  let(:assignment) { Assignment.create(title: 'Assignment', creator: user, organization: organization) }

  before do
    sign_in(user)
  end

  describe 'GET #new', :vcr do
    before(:each) do
      get :new, params: { organization_id: organization.slug }
    end

    it 'returns success status' do
      expect(response).to have_http_status(:success)
    end

    it 'has a new Assignment' do
      expect(assigns(:assignment)).to_not be_nil
    end
  end

  describe 'POST #create', :vcr do
    it 'creates a new Assignment' do
      expect do
        post :create, params: {
          organization_id: organization.slug,
          assignment:      attributes_for(:assignment)
        }
      end.to change { Assignment.count }
    end

    context 'valid starter_code repo_name input' do
      before do
        post :create, params: {
          organization_id: organization.slug,
          assignment:      attributes_for(:assignment),
          repo_name:       'rails/rails'
        }
      end

      it 'creates a new Assignment' do
        expect(Assignment.count).to eql(1)
      end
    end

    context 'invalid starter_code repo_name input' do
      before do
        request.env['HTTP_REFERER'] = 'http://test.host/classrooms/new'

        post :create, params: {
          organization_id: organization.slug,
          assignment:      attributes_for(:assignment),
          repo_name:       'https://github.com/rails/rails'
        }
      end

      it 'fails to create a new Assignment' do
        expect(Assignment.count).to eql(0)
      end

      it 'does not return an internal server error' do
        expect(response).not_to have_http_status(:internal_server_error)
      end

      it 'provides a friendly error message' do
        expect(flash[:error]).to eql('Invalid repository name, use the format owner/name.')
      end
    end

    context 'valid repo_id for starter_code is passed' do
      before do
        post :create, params: {
          organization_id: organization.slug,
          assignment:      attributes_for(:assignment),
          repo_id:         8514 # 'rails/rails'
        }
      end

      it 'creates a new Assignment' do
        expect(Assignment.count).to eql(1)
      end

      it 'sets correct starter_code_repo for the new Assignment' do
        expect(Assignment.first.starter_code_repo_id).to be(8514)
      end
    end

    context 'invalid repo_id for starter_code is passed' do
      before do
        request.env['HTTP_REFERER'] = 'http://test.host/classrooms/new'

        post :create, params: {
          organization_id: organization.slug,
          assignment:      attributes_for(:assignment),
          repo_id:         'invalid_id' # id must be an integer
        }
      end

      it 'fails to create a new Assignment' do
        expect(Assignment.count).to eql(0)
      end

      it 'does not return an internal server error' do
        expect(response).not_to have_http_status(:internal_server_error)
      end

      it 'provides a friendly error message' do
        expect(flash[:error]).to eql('Invalid repository selection, please check it again.')
      end
    end
  end

  describe 'GET #show', :vcr do
    it 'returns success status' do
      get :show, params: { organization_id: organization.slug, id: assignment.slug }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #edit', :vcr do
    it 'returns success and sets the assignment' do
      get :edit, params: { id: assignment.slug, organization_id: organization.slug }

      expect(response).to have_http_status(:success)
      expect(assigns(:assignment)).to_not be_nil
    end
  end

  describe 'PATCH #update', :vcr do
    it 'correctly updates the assignment' do
      options = { title: 'Ruby on Rails' }
      patch :update, params: { id: assignment.slug, organization_id: organization.slug, assignment: options }

      expect(response).to redirect_to(organization_assignment_path(organization, Assignment.find(assignment.id)))
    end
  end

  describe 'DELETE #destroy', :vcr do
    it 'sets the `deleted_at` column for the assignment' do
      assignment
      expect do
        delete :destroy, params: { id: assignment.slug, organization_id: organization }
      end.to change { Assignment.all.count }

      expect(Assignment.unscoped.find(assignment.id).deleted_at).not_to be_nil
    end

    it 'calls the DestroyResource background job' do
      delete :destroy, params: { id: assignment.slug, organization_id: organization }

      assert_enqueued_jobs 1 do
        DestroyResourceJob.perform_later(assignment)
      end
    end

    it 'redirects back to the organization' do
      delete :destroy, params: { id: assignment.slug, organization_id: organization.slug }
      expect(response).to redirect_to(organization)
    end
  end
end

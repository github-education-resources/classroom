# frozen_string_literal: true
require 'rails_helper'

RSpec.describe StudentIdentifierTypesController, type: :controller do
  let(:organization)  { classroom_org       }
  let(:user)          { classroom_teacher   }
  let(:student)       { classroom_student   }

  let(:student_identifier_type) { create(:student_identifier_type, organization: organization) }

  before do
    sign_in_as(user)
  end

  context 'flipper is enabled for the user' do
    before do
      GitHubClassroom.flipper[:student_identifier].enable
    end

    describe 'GET #index', :vcr do
      it 'returns success status' do
        get :index, params: { organization_id: organization.slug }

        expect(response).to have_http_status(:success)
      end
    end

    describe 'GET #new', :vcr do
      it 'returns success status' do
        get :new, params: { organization_id: organization.slug }

        expect(response).to have_http_status(:success)
      end

      context 'different referring page' do
        let(:referer) { 'where_i_came_from' }

        before do
          request.env['HTTP_REFERER'] = referer
        end

        it 'sets the session correctly' do
          get :new, params: { organization_id: organization.slug }
          expect(session['return_to']).to equal(referer)
        end
      end
    end

    describe 'POST #create', :vcr do
      it 'creates a new StudentIdentifierType' do
        expect do
          post :create, params: {
            organization_id: organization.slug,
            student_identifier_type: { name: 'Test', description: 'Test', content_type: 'text' }
          }
        end.to change { StudentIdentifierType.count }
      end
    end

    describe 'GET #edit', :vcr do
      it 'returns success status' do
        student_identifier_type
        get :edit, params: { organization_id: organization.slug, id: student_identifier_type.id }

        expect(response).to have_http_status(:success)
      end
    end

    describe 'PATCH #update', :vcr do
      before(:each) do
        options = { name: 'Test2', description: 'Test2', content_type: 'email' }
        patch :update, params: {
          organization_id: organization.slug,
          id: student_identifier_type.id,
          student_identifier_type: options
        }
      end

      it 'correctly updates the student identifier type' do
        expect(StudentIdentifierType.find(student_identifier_type.id).name).to eql('Test2')
      end

      it 'redirects to the identifier index page on success' do
        expect(response).to redirect_to(organization_student_identifier_types_path(organization))
      end
    end

    describe 'DELETE #destroy', :vcr do
      it 'sets the `deleted_at` column' do
        student_identifier_type
        expect do
          delete :destroy, params: { id: student_identifier_type.id, organization_id: organization }
        end.to change { StudentIdentifierType.all.count }
        expect(StudentIdentifierType.unscoped.find(student_identifier_type.id).deleted_at).not_to be_nil
      end

      it 'calls the DestroyResource background job' do
        delete :destroy, params: { id: student_identifier_type.id, organization_id: organization }

        assert_enqueued_jobs 1 do
          DestroyResourceJob.perform_later(student_identifier_type)
        end
      end

      it 'redirects back to the student identifier type index' do
        delete :destroy, params: { id: student_identifier_type.id, organization_id: organization }
        expect(response).to redirect_to(organization_student_identifier_types_path(organization))
      end
    end

    after do
      GitHubClassroom.flipper[:student_identifier].disable
    end
  end

  context 'flipper is not enabled for the user' do
    describe 'GET #index', :vcr do
      it 'returns a 404' do
        expect do
          get :index, params: { organization_id: organization.slug }
        end.to raise_error(ActionController::RoutingError)
      end
    end

    describe 'GET #new', :vcr do
      it 'returns a 404' do
        expect do
          get :new, params: { organization_id: organization.slug }
        end.to raise_error(ActionController::RoutingError)
      end
    end

    describe 'POST #create', :vcr do
      it 'returns a 404' do
        expect do
          post :create, params: {
            organization_id: organization.slug,
            student_identifier_type: { name: 'Test', description: 'Test', content_type: 'text' }
          }
        end.to raise_error(ActionController::RoutingError)
      end
    end

    describe 'GET #edit', :vcr do
      it 'returns a 404' do
        student_identifier_type
        expect do
          get :edit, params: { organization_id: organization.slug, id: student_identifier_type.id }
        end.to raise_error(ActionController::RoutingError)
      end
    end

    describe 'PATCH #update', :vcr do
      it 'returns a 404' do
        options = { name: 'Test2', description: 'Test2', content_type: 'email' }
        expect do
          patch :update, params: {
            organization_id: organization.slug,
            id: student_identifier_type.id,
            student_identifier_type: options
          }
        end.to raise_error(ActionController::RoutingError)
      end
    end

    describe 'DELETE #destroy', :vcr do
      it 'returns a 404' do
        student_identifier_type
        expect do
          delete :destroy, params: {
            id: student_identifier_type.id, organization_id: organization
          }
        end.to raise_error(ActionController::RoutingError)
      end
    end
  end
end

# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AssignmentReposController, type: :controller do
  include ActiveJob::TestHelper

  let(:organization) { GitHubFactory.create_owner_classroom_org }
  let(:user)         { organization.users.first                 }

  let(:assignment) do
    Assignment.create(creator: organization.users.first,
                      title: 'ruby-project',
                      slug: 'ruby-project',
                      starter_code_repo_id: '1062897',
                      organization: organization,
                      public_repo: false)
  end

  before do
    GitHubClassroom.flipper[:teacher_dashboard].enable
    sign_in(user)
  end

  after do
    GitHubClassroom.flipper[:teacher_dashboard].disable
  end

  describe 'GET #status', :vcr do
    before(:each) do
      @assignment_repo = AssignmentRepo.create!(assignment: assignment, user: user)
    end

    context 'unauthenticated request' do
      before do
        sign_out
      end

      it 'redirects to the login page' do
        get :repo_status, params: {
          organization_id: organization.slug,
          assignment_id: assignment.slug,
          id: @assignment_repo.id
        }
        expect(response).to redirect_to(login_path)
      end
    end

    context 'user with admin privilege on the organization' do
      before do
        sign_in(user)
      end

      context 'valid parameters' do
        before(:each) do
          get :repo_status, params: {
            organization_id: organization.slug,
            assignment_id: assignment.slug,
            id: @assignment_repo.id
          }
        end

        it 'returns success' do
          expect(response).to have_http_status(:success)
        end

        it 'renders correct template' do
          expect(response).to render_template(partial: 'shared/github_repository/_status')
        end
      end

      context 'invalid parameters' do
        it 'returns a 404' do
          expect do
            get :repo_status, params: {
              organization_id: organization.slug,
              assignment_id: assignment.slug,
              id: @assignment_repo.id + 1
            }
          end.to raise_error(ActionController::RoutingError)
        end
      end
    end

    after(:each) do
      AssignmentRepo.destroy_all
    end
  end
end

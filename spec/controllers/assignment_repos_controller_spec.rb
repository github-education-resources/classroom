# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AssignmentReposController, type: :controller do
  let(:organization) { classroom_org     }
  let(:user)         { classroom_teacher }

  let(:assignment)      { create(:assignment, organization: organization) }
  let(:assignment_repo) { create(:assignment_repo, github_repo_id: 42, assignment: assignment) }

  before(:each) do
    p "before sign in: #{organization.users.count}"
    sign_in_as(user)
    p "after sign in: #{organization.users.count}"
  end

  # after do
  #   AssignmentRepo.destroy_all
  #   Assignment.destroy_all
  # end

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

  describe 'GET #status', :vcr do
    before do
      GitHubClassroom.flipper[:teacher_dashboard].enable
    end

    after do
      GitHubClassroom.flipper[:teacher_dashboard].disable
    end

    context 'unauthenticated request' do
      before do
        sign_out
      end

      it 'redirects to the login page' do
        get :repo_status, params: {
          organization_id: organization.slug,
          assignment_id: assignment.id,
          id: assignment_repo.id
        }
        expect(response).to redirect_to(login_path)
      end
    end

    context 'user with admin privilege on the organization' do
      context 'valid parameters' do
        before do
          puts "before get status: #{organization.users.count}"
          get :repo_status, params: {
            organization_id: organization.slug,
            assignment_id: assignment.id,
            id: assignment_repo.id
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
        it 'raises ActiveRecord::RecordNotFound' do
          expect do
            get :repo_status, params: {
              organization_id: organization.slug,
              assignment_id: assignment.id,
              id: assignment_repo.id + 1
            }
          end.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end
end

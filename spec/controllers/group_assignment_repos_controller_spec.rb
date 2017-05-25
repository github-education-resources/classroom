# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GroupAssignmentReposController, type: :controller do
  let(:user)         { classroom_teacher }
  let(:organization) { classroom_org     }
  let(:student)      { classroom_student }

  let(:repo_access)  { RepoAccess.create(user: student, organization: organization) }

  let(:group_assignment) do
    create(:group_assignment, title: 'Learn Ruby', organization: organization, public_repo: false)
  end

  let(:group) { Group.create(title: Time.zone.now, grouping: group_assignment.grouping) }

  let(:group_assignment_repo) do
    GroupAssignmentRepo.create(group_assignment: group_assignment, group: group)
  end

  before(:each) do
    sign_in_as(user)
  end

  after do
    GroupAssignmentRepo.destroy_all
    Grouping.destroy_all
  end

  describe 'GET #show', :vcr do
    context 'as an unauthorized user' do
      before do
        sign_out
      end

      it 'returns a 404' do
        params = {
          id: group_assignment_repo.id,
          organization_id: organization.slug,
          group_assignment_id: group_assignment.id
        }

        get :show, params: params
        expect(response).to redirect_to(login_path)
      end
    end

    context 'as an authorized user' do
      before do
        params = {
          id: group_assignment_repo.id,
          organization_id: organization.slug,
          group_assignment_id: group_assignment.id
        }

        get :show, params: params
      end

      it 'succeeds' do
        expect(response).to have_http_status(:success)
      end

      it 'sets the GroupAssignmentRepo' do
        expect(assigns[:group_assignment_repo].id).to eq(group_assignment_repo.id)
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
      before(:each) do
        sign_out
      end

      it 'redirects to the login page' do
        get :repo_status, params: {
          organization_id: organization.slug,
          group_assignment_id: group_assignment.slug,
          id: group_assignment_repo.id
        }
        expect(response).to redirect_to(login_path)
      end
    end

    context 'user with admin privilege on the organization' do
      before(:each) do
        sign_in_as(user)
      end

      context 'valid parameters' do
        before(:each) do
          get :repo_status, params: {
            organization_id: organization.slug,
            group_assignment_id: group_assignment.slug,
            id: group_assignment_repo.id
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
              group_assignment_id: group_assignment.slug,
              id: group_assignment_repo.id + 1
            }
          end.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end
end

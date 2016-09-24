# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Stafftools::GroupAssignmentReposController, type: :controller do
  let(:user)         { GitHubFactory.create_owner_classroom_org.users.first }
  let(:organization) { user.organizations.first                             }

  let(:student)      { GitHubFactory.create_classroom_student                       }
  let(:repo_access)  { RepoAccess.create(user: student, organization: organization) }

  let(:grouping) { Grouping.create(organization: organization, title: 'Grouping 1') }
  let(:group)    { Group.create(title: Time.zone.now, grouping: grouping)           }

  let(:group_assignment) do
    GroupAssignment.create(creator: user,
                           title: 'Learn Ruby',
                           slug: 'learn-ruby',
                           organization: organization,
                           grouping: grouping,
                           public_repo: false)
  end

  let(:group_assignment_repo) do
    GroupAssignmentRepo.create(group_assignment: group_assignment, group: group)
  end

  before(:each) do
    sign_in(user)
  end

  after do
    GroupAssignmentRepo.destroy_all
    Grouping.destroy_all
  end

  describe 'GET #show', :vcr do
    context 'as an unauthorized user' do
      it 'returns a 404' do
        expect { get :show, params: { id: group_assignment_repo.id } }.to raise_error(ActionController::RoutingError)
      end
    end

    context 'as an authorized user' do
      before do
        user.update_attributes(site_admin: true)
        get :show, params: { id: group_assignment_repo.id }
      end

      it 'succeeds' do
        expect(response).to have_http_status(:success)
      end

      it 'sets the GroupAssignmentRepo' do
        expect(assigns(:group_assignment_repo).id).to eq(group_assignment_repo.id)
      end
    end
  end
end

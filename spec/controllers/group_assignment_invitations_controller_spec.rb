require 'rails_helper'

RSpec.describe GroupAssignmentInvitationsController, type: :controller do
  describe 'GET #show' do
    let(:invitation) { create(:group_assignment_invitation) }

    context 'unauthenticated request' do
      it 'redirects the new user to sign in with GitHub' do
        get :show, id: invitation.key
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe 'PATCH #accept_invitation', :vcr do
    let(:organization)  { GitHubFactory.create_owner_classroom_org }
    let(:user)          { GitHubFactory.create_classroom_student   }
    let(:grouping)      { Grouping.create(title: 'Grouping 1', organization: organization) }

    let(:group_assignment) do
      GroupAssignment.create(creator: organization.users.first,
                             title: 'HTML5',
                             grouping: grouping,
                             organization: organization,
                             public_repo: false)
    end

    let(:invitation) { GroupAssignmentInvitation.create(group_assignment: group_assignment) }

    context 'authenticated request' do
      before(:each) do
        session[:user_id] = user.id
      end

      after(:each) do
        RepoAccess.destroy_all
        Group.destroy_all
        GroupAssignmentRepo.destroy_all
      end

      it 'redeems the users invitation' do
        patch :accept_invitation, id: invitation.key, group: { title: 'Code Squad' }

        assert_requested :post, github_url("/organizations/#{organization.github_id}/teams"), times: 2
        assert_requested :post, github_url("/organizations/#{organization.github_id}/repos")

        expect(group_assignment.group_assignment_repos.count).to eql(1)
        expect(user.repo_accesses.count).to eql(1)
      end
    end
  end
end

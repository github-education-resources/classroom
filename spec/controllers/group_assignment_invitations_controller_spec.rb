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
                             public_repo: true)
    end

    let(:invitation) { GroupAssignmentInvitation.create(group_assignment: group_assignment) }

    context 'authenticated request' do
      before(:each) do
        sign_in(user)
        request.env['HTTP_REFERER'] = "http://classroomtest.com/group-assignment-invitations/#{invitation.key}"
      end

      after(:each) do
        RepoAccess.destroy_all
        Group.destroy_all
        GroupAssignmentRepo.destroy_all
      end

      it 'redeems the users invitation' do
        patch :accept_invitation, id: invitation.key, group: { title: 'Code Squad' }

        expect(WebMock).to have_requested(:post, github_url("/organizations/#{organization.github_id}/teams"))
        expect(WebMock).to have_requested(:post, github_url("/organizations/#{organization.github_id}/repos"))

        expect(group_assignment.group_assignment_repos.count).to eql(1)
        expect(user.repo_accesses.count).to eql(1)
      end

      it 'does not allow users to join a group that is not apart of the grouping' do
        other_grouping = Grouping.create(title: 'Other Grouping', organization: organization)
        other_group    = Group.create(title: 'The Group', grouping: other_grouping)

        patch :accept_invitation, id: invitation.key, group: { id: other_group.id }

        expect(group_assignment.group_assignment_repos.count).to eql(0)
        expect(user.repo_accesses.count).to eql(0)
      end

      context 'group has reached maximum number of members' do
        let(:group)   { Group.create(title: 'The Group', grouping: grouping) }
        let(:student) { GitHubFactory.create_classroom_student }

        before(:each) do
          allow_any_instance_of(RepoAccess).to receive(:silently_remove_organization_member).and_return(true)
          group_assignment.update(max_members: 1)
          group.repo_accesses << RepoAccess.create(user: student, organization: organization)
        end

        it 'does not allow user to join' do
          expect_any_instance_of(ApplicationController).to receive(:flash_and_redirect_back_with_message)
          patch :accept_invitation, id: invitation.key, group: { id: group.id }
        end
      end

      context 'group has not reached maximum number of members' do
        let(:group)   { Group.create(title: 'The Group', grouping: grouping) }

        before(:each) do
          group_assignment.update(max_members: 1)
        end

        it 'allows user to join' do
          patch :accept_invitation, id: invitation.key, group: { id: group.id }
        end
      end

      context 'group does not have maximum number of members' do
        let(:group) { Group.create(title: 'The Group', grouping: grouping) }

        it 'allows user to join' do
          patch :accept_invitation, id: invitation.key, group: { id: group.id }
          expect(group_assignment.group_assignment_repos.count).to eql(1)
          expect(user.repo_accesses.count).to eql(1)
        end
      end
    end
  end
end

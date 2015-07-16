require 'rails_helper'

describe GroupAssignmentInvitationRedeemer do
  let(:invitee)          { GitHubFactory.create_classroom_student                         }
  let(:organization)     { GitHubFactory.create_owner_classroom_org                       }
  let(:github_client)    { organization.fetch_owner.github_client                         }
  let(:grouping)         { Grouping.create(title: 'Grouping', organization: organization) }

  let(:group_assignment)  do
    GroupAssignment.create(creator: organization.fetch_owner,
                           title: 'JavaScript',
                           organization: organization,
                           public_repo: false,
                           grouping: grouping)
  end

  describe '#redeem_for', :vcr do
    after(:each) do
      github_client.delete_team(RepoAccess.last.github_team_id) if RepoAccess.last.present?
      github_client.delete_team(Group.last.github_team_id) if Group.last.present?
      github_client.delete_repository(GroupAssignmentRepo.last.github_repo_id) if GroupAssignmentRepo.last.present?
    end

    context 'new User' do
      context 'GroupAssignment without groups' do
        it 'creates a new RepoAccess, Group, and GroupAssignmentRepo' do
          invitation_redeemer = GroupAssignmentInvitationRedeemer.new(group_assignment, nil, 'Code Squad')
          full_repo_name      = invitation_redeemer.redeem_for(invitee)

          expect(group_assignment.grouping.groups.count).to eql(1)
          expect(RepoAccess.count).to eql(1)
          expect(full_repo_name).to eql("#{organization.title}/#{group_assignment.title}-Code-Squad")
        end
      end

      context 'GroupAssignment with groups' do
        before(:each) do
          github_organization = GitHubOrganization.new(github_client, organization.github_id)
          github_team         = github_organization.create_team('Code Squad')
          github_repository   = github_organization.create_repository('JavaScript-Code-Squad', private: true)

          @group = Group.create(title: 'Code Squad', github_team_id: github_team.id, grouping: grouping)
          GroupAssignmentRepo.create(group_assignment: group_assignment,
                                     group: @group,
                                     github_repo_id: github_repository.id)
        end

        it 'creates a new RepoAccess then adds it to the Group' do
          invitation_redeemer = GroupAssignmentInvitationRedeemer.new(group_assignment, @group, nil)
          full_repo_name      = invitation_redeemer.redeem_for(invitee)

          expect(group_assignment.grouping.groups.count).to eql(1)
          expect(RepoAccess.count).to eql(1)
          expect(RepoAccess.last.groups.last).to eql(@group)

          expect(full_repo_name).to eql("#{organization.title}/#{group_assignment.title}-Code-Squad")
        end

        it 'raises a GitHub::Error if a team is created with a name that already exists' do
          invitation_redeemer = GroupAssignmentInvitationRedeemer.new(group_assignment, nil, 'Code Squad')

          begin
            invitation_redeemer.redeem_for(invitee)
          rescue => err
            expect(err.class).to eql(GitHub::Error)
          end

          expect(group_assignment.grouping.groups.count).to eql(1)
          expect(RepoAccess.count).to eql(1)
        end
      end
    end

    context 'existing User' do
      before(:each) do
        github_organization = GitHubOrganization.new(github_client, organization.github_id)
        github_team         = github_organization.create_team('Team 1')

        RepoAccess.create(github_team_id: github_team.id, organization: organization, user: invitee)
      end

      context 'GroupAssignment without groups' do
        it 'adds the Users RepoAccess to a new Group and GroupAssignmentRepo' do
          invitation_redeemer = GroupAssignmentInvitationRedeemer.new(group_assignment, nil, 'Code Squad')
          full_repo_name      = invitation_redeemer.redeem_for(invitee)

          expect(group_assignment.grouping.groups.count).to eql(1)
          expect(RepoAccess.count).to eql(1)

          expect(full_repo_name).to eql("#{organization.title}/#{group_assignment.title}-Code-Squad")
        end
      end

      context 'GroupAssignment with groups' do
        before(:each) do
          github_organization  = GitHubOrganization.new(github_client, organization.github_id)
          @github_team         = github_organization.create_team('Code Squad')
          @github_repository   = github_organization.create_repository('JavaScript-Code-Squad', private: true)

          @group = Group.create(title: 'Code Squad', github_team_id: @github_team.id, grouping: grouping)
          GroupAssignmentRepo.create(group_assignment: group_assignment,
                                     group: @group,
                                     github_repo_id: @github_repository.id)
        end

        it 'adds the Users RepoAccess to the existing Group' do
          invitation_redeemer = GroupAssignmentInvitationRedeemer.new(group_assignment, @group, nil)
          full_repo_name      = invitation_redeemer.redeem_for(invitee)

          expect(group_assignment.grouping.groups.count).to eql(1)
          expect(RepoAccess.count).to eql(1)
          expect(RepoAccess.last.groups.last).to eql(@group)

          expect(full_repo_name).to eql("#{organization.title}/#{group_assignment.title}-Code-Squad")
        end

        context 'User who has already joined a Group' do
          before do
            github_login = invitee.github_login
            @github_team.add_team_membership(github_login)

            users_github_team = GitHubTeam.new(github_client, RepoAccess.last.github_team_id)
            users_github_team.add_team_repository(@github_repository.full_name)

            @group.repo_accesses << RepoAccess.last
            @group.save!
          end

          it 'returns the name of the repository they have already joined' do
            invitation_redeemer = GroupAssignmentInvitationRedeemer.new(group_assignment, nil, 'Code Squad')
            full_repo_name      = invitation_redeemer.redeem_for(invitee)

            expect(group_assignment.grouping.groups.count).to eql(1)
            expect(RepoAccess.count).to eql(1)
            expect(RepoAccess.last.groups.last).to eql(@group)

            expect(full_repo_name).to eql("#{organization.title}/#{group_assignment.title}-Code-Squad")
          end
        end
      end
    end
  end
end

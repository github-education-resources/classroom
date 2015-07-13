require 'rails_helper'

describe GroupManager do
  let(:organization)  { GitHubFactory.create_owner_classroom_org                       }
  let(:github_client) { organization.fetch_owner.github_client                         }
  let(:user)          { GitHubFactory.create_classroom_student                         }
  let(:grouping)      { Grouping.create(title: 'Grouping', organization: organization) }

  let(:group_assignment) do
    GroupAssignment.new(creator: organization.fetch_owner,
                        title: 'JavaScript-Project',
                        grouping: grouping,
                        organization: organization,
                        public_repo: false)
  end

  before(:each) do
    @github_organization = GitHubOrganization.new(organization.fetch_owner.github_client, organization.github_id)
    @github_team         = @github_organization.create_team('Team')
    @repo_access         = RepoAccess.create(github_team_id: @github_team.id, user: user, organization: organization)
  end

  after(:each) do
    github_client.delete_team(RepoAccess.last.github_team_id)
    github_client.delete_team(Group.last.github_team_id)
  end

  describe '#add_repo_access_to_group', :vcr do
    before(:each) do
      group_github_team = @github_organization.create_team('Code Squad')
      @group            = Group.create(title: 'Code Squad', github_team_id: group_github_team.id, grouping: grouping)
      @group_manager    = GroupManager.new(group_assignment, @group)
    end

    context 'RepoAccess is not apart of the group' do
      it 'adds the RepoAccess and returns true' do
        expect(@group_manager.add_repo_access_to_group(@repo_access)).to be(true)
        assert_requested :put, github_url("teams/#{@group.github_team_id}/memberships/#{user.github_login}")
        expect(Group.last.repo_accesses.count).to be(1)
      end
    end

    context 'RepoAccess is already apart of the group' do
      before(:each) do
        @group_manager.group.repo_accesses << @repo_access
        @group_manager.group.save!
      end

      it 'returns true' do
        expect(@group_manager.add_repo_access_to_group(@repo_access)).to be(true)
        expect(Group.last.repo_accesses.count).to be(1)
      end
    end
  end

  describe '#create_group', :vcr do
    before do
      @group_manager = GroupManager.new(group_assignment)
    end

    it 'creates the group, and creates the team on GitHub' do
      @group_manager.create_group('Code Squad')

      assert_requested :post, github_url("/organizations/#{organization.github_id}/teams"), times: 2
      expect(Group.last).to_not be_nil
      expect(@group_manager.group.id).to eql(Group.last.id)
    end
  end
end

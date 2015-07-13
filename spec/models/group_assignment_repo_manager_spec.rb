require 'rails_helper'

describe GroupAssignmentRepoManager do
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

  describe '#add_repo_access_to_assignment_repo', :vcr do
    before(:each) do
      @github_organization = GitHubOrganization.new(organization.fetch_owner.github_client, organization.github_id)
      @github_team         = @github_organization.create_team('Team')
      repo_access          = RepoAccess.create(github_team_id: @github_team.id, user: user, organization: organization)
      @group               = Group.create(title: 'Code Squad',
                                          github_team_id: 12_345,
                                          grouping: grouping,
                                          repo_accesses: [repo_access])

      @group_assignment_repo_manager = GroupAssignmentRepoManager.new(group_assignment, @group, repo_access)
    end

    after(:each) do
      github_client.delete_team(RepoAccess.last.github_team_id)
      github_client.delete_repository(GroupAssignmentRepo.last.github_repo_id)
    end

    context 'team does not own the repository' do
      before do
        github_repo = @github_organization.create_repository('JavaScript-Project-1', private: true)
        group_assignment_repo = GroupAssignmentRepo.create(github_repo_id: github_repo.id,
                                                           group_assignment: group_assignment,
                                                           group: @group)

        @group_assignment_repo_manager.group_assignment_repo = group_assignment_repo
      end

      it 'adds the team to the repository' do
        github_repository = GitHubRepository.new(github_client, GroupAssignmentRepo.last.github_repo_id)
        full_repo_name    = github_repository.full_name

        @group_assignment_repo_manager.add_repo_access_to_assignment_repo

        url = "/teams/#{RepoAccess.last.github_team_id}/repos/#{full_repo_name}"
        assert_requested :put, github_url(url), times: 1
      end
    end

    context 'team owns the repository' do
      before do
        github_repository = @github_organization.create_repository('JavaScript-Project-1',
                                                                   team: RepoAccess.last.github_team_id,
                                                                   private: true)

        group_assignment_repo = GroupAssignmentRepo.create(group: @group,
                                                           group_assignment: group_assignment,
                                                           github_repo_id: github_repository.id)

        @group_assignment_repo_manager.group_assignment_repo = group_assignment_repo
      end

      it 'does not add the team to the repository' do
        github_repository = GitHubRepository.new(github_client, GroupAssignmentRepo.last.github_repo_id)
        full_repo_name    = github_repository.full_name

        @group_assignment_repo_manager.add_repo_access_to_assignment_repo

        url = "/teams/#{RepoAccess.last.github_team_id}/repos/#{full_repo_name}"
        assert_requested :put, github_url(url), times: 1
      end
    end
  end

  describe '#find_or_create_group_assignment_repo', :vcr do
    before(:each) do
      @github_organization = GitHubOrganization.new(organization.fetch_owner.github_client, organization.github_id)
      @github_team         = @github_organization.create_team('Team')
      repo_access          = RepoAccess.create(github_team_id: @github_team.id, user: user, organization: organization)
      @group               = Group.create(title: 'Code Squad',
                                          github_team_id: 12_345,
                                          grouping: grouping,
                                          repo_accesses: [repo_access])

      @group_assignment_repo_manager = GroupAssignmentRepoManager.new(group_assignment, @group, repo_access)
    end

    after(:each) do
      github_client.delete_team(RepoAccess.last.github_team_id)
      github_client.delete_repository(GroupAssignmentRepo.last.github_repo_id)
    end

    context 'GroupAssignmentRepo exists' do
      before(:each) do
        github_repository = @github_organization.create_repository('JavaScript-Project-1',
                                                                   team: RepoAccess.last.github_team_id,
                                                                   private: true)

        GroupAssignmentRepo.create(group: @group,
                                   group_assignment: group_assignment,
                                   github_repo_id: github_repository.id)
      end

      it 'finds the GroupAssignmentRepo' do
        group_assignment_repo = @group_assignment_repo_manager.find_or_create_group_assignment_repo
        expect(group_assignment_repo.id).to eql(GroupAssignmentRepo.last.id)
      end
    end

    context 'GroupAssignmentRepo does not exist' do
      it 'creates a new GroupAssignmentRepo' do
        expect(GroupAssignmentRepo.all.count).to eql(0)
        group_assignment_repo = @group_assignment_repo_manager.find_or_create_group_assignment_repo

        expect(group_assignment_repo.id).to_not be_nil
        expect(group_assignment_repo.class).to be(GroupAssignmentRepo)
      end
    end
  end

  describe '#group_assignment_description' do
    before(:each) do
      repo_access = RepoAccess.create(github_team_id: 123_456, user: user, organization: organization)
      @group      = Group.create(title: 'Code Squad',
                                 github_team_id: 12_345,
                                 grouping: grouping,
                                 repo_accesses: [repo_access])

      @group_assignment_repo_manager = GroupAssignmentRepoManager.new(group_assignment, @group, repo_access)
    end

    it 'gives the correct description' do
      expected_description = "#{group_assignment.title} created by GitHub Classroom for #{@group.title}"
      expect(@group_assignment_repo_manager.group_assignment_description).to eql(expected_description)
    end
  end

  describe '#group_assignment_title' do
    before(:each) do
      repo_access = RepoAccess.create(github_team_id: 123_456, user: user, organization: organization)
      @group      = Group.create(title: 'Code Squad',
                                 github_team_id: 12_345,
                                 grouping: grouping,
                                 repo_accesses: [repo_access])

      @group_assignment_repo_manager = GroupAssignmentRepoManager.new(group_assignment, @group, repo_access)
    end

    it 'gives the correct title' do
      expected_title = "#{group_assignment.title} #{@group.title}"
      expect(@group_assignment_repo_manager.group_assignment_title).to eql(expected_title)
    end
  end
end

require 'rails_helper'

RSpec.describe GroupAssignmentRepo, type: :model do
  context 'with created objects', :vcr do
    let(:organization) { GitHubFactory.create_owner_classroom_org                                      }
    let(:repo_access)  { RepoAccess.create(user: organization.users.first, organization: organization) }

    let(:grouping)     { Grouping.create(organization: organization, title: 'Grouping 1') }
    let(:group)        { Group.create(title: 'Group 1', grouping: grouping) }

    let(:group_assignment) do
      GroupAssignment.create(creator: organization.users.first,
                             grouping: grouping,
                             title: 'Learn JavaScript',
                             organization: organization,
                             public_repo: false)
    end

    before(:each) do
      group.repo_accesses << repo_access
      @group_assignment_repo = GroupAssignmentRepo.create(group_assignment: group_assignment, group: group)
    end

    after(:each) do
      group.destroy
      repo_access.destroy
      @group_assignment_repo.destroy if @group_assignment_repo
    end

    describe 'callbacks', :vcr do
      describe 'before_validation' do
        describe '#create_github_repository' do
          it 'creates the repository on GitHub' do
            assert_requested :post, github_url("/organizations/#{organization.github_id}/repos")
          end
        end
      end

      describe 'before_create' do
        describe '#add_team_to_github_repository' do
          it 'adds the team to the repository' do
            github_repo = GitHubRepository.new(organization.github_client, @group_assignment_repo.github_repo_id)
            assert_requested :put, github_url("/teams/#{group.github_team_id}/repos/#{github_repo.full_name}")
          end
        end
      end

      describe 'before_destroy' do
        describe '#destroy_github_repository' do
          it 'deletes the repository from GitHub' do
            repo_id = @group_assignment_repo.github_repo_id
            @group_assignment_repo.destroy

            assert_requested :delete, github_url("/repositories/#{repo_id}")
          end
        end
      end
    end

    describe '#creator' do
      it 'returns the group assignments creator' do
        expect(@group_assignment_repo.creator).to eql(group_assignment.creator)
      end
    end
  end
end

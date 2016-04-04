require 'rails_helper'

RSpec.describe GroupAssignmentRepo, type: :model do
  context 'with created objects', :vcr do
    let(:organization) { GitHubFactory.create_owner_classroom_org }
    let(:student)      { GitHubFactory.create_classroom_student   }
    let(:repo_access)  { RepoAccess.create(user: student, organization: organization) }

    let(:grouping)     { Grouping.create(organization: organization, title: 'Grouping 1') }
    let(:group)        { Group.create(title: 'Group 1', grouping: grouping) }

    let(:group_assignment) do
      GroupAssignment.create(creator: organization.users.first,
                             grouping: grouping,
                             title: 'Learn JavaScript',
                             organization: organization,
                             public_repo: false,
                             starter_code_repo_id: 1_062_897)
    end

    before(:each) do
      group.repo_accesses << repo_access
      @group_assignment_repo = GroupAssignmentRepo.create(group_assignment: group_assignment, group: group)
    end

    after(:each) do
      Group.destroy_all
      RepoAccess.destroy_all
      GroupAssignmentRepo.destroy_all
    end

    describe 'callbacks', :vcr do
      describe 'before_validation' do
        describe '#create_github_repository' do
          it 'creates the repository on GitHub' do
            expect(WebMock).to have_requested(:post, github_url("/organizations/#{organization.github_id}/repos"))
          end
        end

        describe '#push_starter_code' do
          it 'pushes the starter code to the GitHub repository' do
            import_github_repo_url = github_url("/repositories/#{@group_assignment_repo.github_repo_id}/import")
            expect(WebMock).to have_requested(:put, import_github_repo_url)
          end
        end

        describe '#add_team_to_github_repository' do
          it 'adds the team to the repository' do
            github_repo = @group_assignment_repo.github_repository
            add_github_team_url = github_url("/teams/#{group.github_team_id}/repos/#{github_repo.full_name}")
            expect(WebMock).to have_requested(:put, add_github_team_url)
          end
        end
      end

      describe 'before_destroy' do
        describe '#destroy_github_repository' do
          it 'deletes the repository from GitHub' do
            repo_id = @group_assignment_repo.github_repo_id
            @group_assignment_repo.destroy

            expect(WebMock).to have_requested(:delete, github_url("/repositories/#{repo_id}"))
          end
        end
      end
    end

    describe '#disabled?' do
      let(:github_organization) { @group_assignment_repo.github_organization }

      context 'repository is missing' do
        before do
          github_organization.delete_repository(github_repository: @group_assignment_repo.github_repository)
        end

        it 'returns true' do
          expect(@group_assignment_repo.disabled?).to be_truthy
        end
      end

      context 'team is missing' do
        before do
          github_organization.delete_team(github_team: @group_assignment_repo.github_team)
        end

        it 'returns true' do
          expect(@group_assignment_repo.disabled?).to be_truthy
        end
      end
    end

    context 'delegated from the GroupAssignment' do
      describe '#creator' do
        it 'returns the group assignments creator' do
          expect(@group_assignment_repo.creator).to eql(group_assignment.creator)
        end
      end

      describe '#starter_code?' do
        it 'returns true if the group_assignment has starter_code' do
          expect(@group_assignment_repo.starter_code?).to eql(@group_assignment_repo.group_assignment.starter_code?)
        end
      end

      describe '#starter_code_repo_id' do
        it 'returns the same id as the group_assignment' do
          expected_id = @group_assignment_repo.group_assignment.starter_code_repo_id
          actual_id   = @group_assignment_repo.starter_code_repo_id

          expect(actual_id).to eql(expected_id)
        end
      end
    end

    context 'delegated from the Group' do
      describe '#github_team' do
        it 'has a GitHubTeam' do
          expect(@group_assignment_repo.github_team).to be_instance_of(GitHubTeam)
        end
      end

      describe '#github_team_id' do
        it 'has the same github_team_id as it\'s group' do
          expect(@group_assignment_repo.github_team_id).to eql(@group_assignment_repo.group.github_team_id)
        end
      end
    end
  end
end

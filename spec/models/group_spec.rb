require 'rails_helper'

RSpec.describe Group, type: :model do
  let(:organization) { GitHubFactory.create_owner_classroom_org }
  let(:grouping)     { Grouping.create(title: 'Grouping 1', organization: organization) }

  after(:each) do
    Group.destroy_all
  end

  describe '#github_team', :vcr do
    let(:group) { Group.create(grouping: grouping, title: 'Toon Town') }

    it 'has a GitHubTeam' do
      expect(group.github_team).to be_instance_of(GitHubTeam)
    end
  end

  describe 'callbacks', :vcr do
    let(:organization) { GitHubFactory.create_owner_classroom_org }
    let(:grouping)     { Grouping.create(title: 'Grouping 1', organization: organization) }

    before(:each) do
      @group = Group.create(grouping: grouping, title: 'Toon Town')
    end

    describe 'before_validation' do
      describe '#create_github_team' do
        it 'creates the team on GitHub' do
          expect(WebMock).to have_requested(:post, github_url("/organizations/#{organization.github_id}/teams"))
        end
      end
    end

    describe 'assocation callbacks' do
      let(:user) { GitHubFactory.create_classroom_student }

      before(:each) do
        @repo_access = RepoAccess.create(user: user, organization: organization)
        @group.repo_accesses << @repo_access
      end

      after(:each) do
        @repo_access.destroy if @repo_access
      end

      describe 'before_add' do
        describe '#add_member_to_github_team' do
          it 'adds the user to the GitHub team' do
            memberships_url = "teams/#{@group.github_team_id}/memberships/#{@repo_access.github_user.login}"
            expect(WebMock).to have_requested(:put, github_url(memberships_url))
          end
        end
      end

      describe 'before_destroy' do
        describe '#remove_from_github_team' do
          it 'removes the user from the GitHub team' do
            github_user = @repo_access.github_user
            @group.repo_accesses.delete(@repo_access)

            rmv_from_team_github_url = github_url("/teams/#{@group.github_team_id}/memberships/#{github_user.login}")
            expect(WebMock).to have_requested(:delete, rmv_from_team_github_url)
          end
        end
      end
    end
  end
end

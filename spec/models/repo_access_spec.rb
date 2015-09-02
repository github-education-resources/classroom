require 'rails_helper'

RSpec.describe RepoAccess, type: :model do
  describe 'callbacks', :vcr do
    let(:organization) { GitHubFactory.create_owner_classroom_org }
    let(:user)         { organization.users.first                 }

    before(:each) do
      @repo_access = RepoAccess.create(user: user, organization: organization)
    end

    after(:each) do
      @repo_access.destroy if @repo_access
    end

    describe 'before_validation' do
      describe '#create_github_team' do
        it 'creates the team on GitHub' do
          assert_requested :post, github_url("/organizations/#{organization.github_id}/teams")
        end
      end

      describe '#add_member_to_github_team' do
        it 'adds the user to the GitHub team' do
          github_user = GitHubUser.new(user.github_client)
          assert_requested :put, github_url("teams/#{@repo_access.github_team_id}/memberships/#{github_user.login}")
        end

        it 'accepts the users membership to the Organization' do
          assert_requested :patch, github_url("/user/memberships/orgs/#{organization.title}")
        end
      end
    end

    describe 'before_destroy' do
      describe '#destroy_github_team' do
        it 'deletes the team on GitHub' do
          team_id = @repo_access.github_team_id
          @repo_access.destroy

          assert_requested :delete, github_url("/teams/#{team_id}")
        end
      end
    end
  end
end

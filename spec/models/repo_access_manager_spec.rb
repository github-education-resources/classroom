require 'rails_helper'

describe RepoAccessManager, :vcr do
  let(:organization)       { GitHubFactory.create_owner_classroom_org }
  let(:user)               { GitHubFactory.create_classroom_student   }

  before(:each) do
    @team_name           = "Team #{Time.zone.now.to_i}"
    @repo_access_manager = RepoAccessManager.new(user, organization)
  end

  after(:each) do
    org_owner = organization.fetch_owner
    team_id   = user.repo_accesses.last.github_team_id

    org_owner.github_client.delete_team(team_id)
  end

  describe '#find_or_create_repo_access' do
    context 'user does not have a RepoAccess' do
      it 'creates a GitHub team and the RepoAccess' do
        @repo_access_manager.find_or_create_repo_access(@team_name)

        assert_requested :post, github_url("/organizations/#{organization.github_id}/teams")
        expect(user.repo_accesses.count).to eql(1)
      end
    end

    context 'user already has a RepoAccess' do
      let(:repo_access) { RepoAccess.create(user: user, organization: organization, github_team_id: 45) }

      before do
        user.repo_accesses << repo_access
        user.save
      end

      it 'finds the RepoAccess' do
        @repo_access_manager.find_or_create_repo_access(@team_name)
        expect(user.repo_accesses.count).to eql(1)
      end
    end
  end
end

require 'rails_helper'

describe AssignmentRepoManager do
  let(:organization)  { GitHubFactory.create_owner_classroom_org }
  let(:github_client) { organization.fetch_owner.github_client   }
  let(:user)          { GitHubFactory.create_classroom_student   }

  let(:assignment) do
    Assignment.create(title: 'Ruby-Project', organization: organization, public_repo: false)
  end

  let(:repo_access) { RepoAccess.new(user: user, organization: organization) }

  before(:each) do
    @github_organization = GitHubOrganization.new(organization.fetch_owner.github_client, organization.github_id)
    github_team          = @github_organization.create_team('Team')

    repo_access.github_team_id = github_team.id
    repo_access.save

    @assignment_repo_manager = AssignmentRepoManager.new(assignment, repo_access)
  end

  after(:each) do
    github_client.delete_team(repo_access.github_team_id)
    github_client.delete_repository(assignment.assignment_repos.last.github_repo_id)
  end

  describe '#find_or_create_assignment_repo', :vcr do
    context 'user does not have an AssignmentRepo for the Assignment' do
      it 'creates a GitHub Repository and the AssignmentRepo' do
        @assignment_repo_manager.find_or_create_assignment_repo

        assert_requested :post, github_url("/organizations/#{organization.github_id}/repos")
        expect(assignment.assignment_repos.count).to eql(1)
      end
    end

    context 'user does have an AssignmentRepo for the Assignment' do
      before(:each) do
        github_repository = @github_organization.create_repository(assignment.title,
                                                                   team: repo_access.github_team_id,
                                                                   private: true)

        assignment_repo  = AssignmentRepo.create(assignment: assignment,
                                                 repo_access: repo_access,
                                                 github_repo_id: github_repository.id)

        assignment.assignment_repos << assignment_repo
        assignment.save
      end

      it 'finds the AssignmentRepo' do
        @assignment_repo_manager.find_or_create_assignment_repo
        expect(assignment.assignment_repos.count).to eql(1)
      end
    end
  end
end

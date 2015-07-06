require 'rails_helper'

describe AssignmentRepoManager do
  let(:organization)       { GitHubFactory.create_owner_classroom_org }
  let(:organization_owner) { organization.fetch_owner                 }
  let(:user)               { GitHubFactory.create_classroom_student   }

  let(:assignment) do
    Assignment.create(title: 'Ruby-Project', organization: organization, public_repo: false)
  end

  let(:repo_access) { RepoAccess.new(user: user, organization: organization) }

  before(:each) do
    github_organization = GitHubOrganization.new(organization.fetch_owner.github_client, organization.github_id)
    github_team         = github_organization.create_team('Team')

    repo_access.github_team_id = github_team.id
    repo_access.save

    @assignment_repo_manager = AssignmentRepoManager.new(assignment, repo_access)
  end

  after(:each) do
    organization_owner.github_client.delete_team(repo_access.github_team_id)
    organization_owner.github_client.delete_repository("#{organization.title}/#{assignment.title}")
  end

  describe '#find_or_create_assignment_repo', :vcr do
    context 'user does not have an AssignmentRepo for the Assignment' do
      it 'creates a GitHub Repository and the AssignmentRepo' do
        @assignment_repo_manager.find_or_create_assignment_repo(assignment.title)

        expect(assignment.assignment_repos.count).to eql(1)
        assert_requested :post, github_url("/organizations/#{organization.github_id}/repos")
      end
    end

    context 'user does have an AssignmentRepo for the Assignment' do
      let(:assignment_repo) do
        AssignmentRepo.create(assignment: assignment, repo_access: repo_access, github_repo_id: 123)
      end

      before do
        assignment.assignment_repos << assignment_repo
        assignment.save
      end

      it 'finds the AssignmentRepo' do
        @assignment_repo_manager.find_or_create_assignment_repo(assignment.title)
        expect(assignment.assignment_repos.count).to eql(1)
      end
    end
  end
end

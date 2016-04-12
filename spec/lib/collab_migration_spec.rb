require 'rails_helper'

RSpec.describe CollabMigration do
  let(:organization) { GitHubFactory.create_owner_classroom_org }
  let(:student)      { GitHubFactory.create_classroom_student   }
  let(:repo_access)  { RepoAccess.create(user: student, organization: organization) }

  let(:github_organization) { organization.github_organization }

  let(:assignment) do
    creator = organization.users.first
    Assignment.create(organization: organization,
                      title: 'gitignore',
                      creator: creator,
                      public_repo: false)
  end

  describe 'repo_access with an assignment_repo', :vcr do
    before(:each) do
      @assignment_repo = AssignmentRepo.create(assignment: assignment, user: student)
      @assignment_repo.update_attributes(user: nil, repo_access: repo_access)
    end

    after(:each) do
      AssignmentRepo.destroy_all
    end

    it 'adds the user as a collaborator to the assignment_repos GitHub repo' do
      CollabMigration.new(repo_access).migrate
      add_user_request = "/repositories/#{@assignment_repo.github_repo_id}/collaborators/#{student.github_user.login}"
      expect(WebMock).to have_requested(:put, github_url(add_user_request)).times(2)
    end

    context 'with a `github_team_id`' do
      before(:each) do
        @github_team = github_organization.create_team(name: 'Test Team')
        repo_access.update_attributes(github_team_id: @github_team.id)
      end

      after(:each) do
        github_organization.organization.delete_team(github_team: @github_team)
      end

      it 'deletes the GitHub team' do
        CollabMigration.new(repo_access).migrate
        expect(WebMock).to have_requested(:delete, github_url("/teams/#{@github_team.id}"))
      end

      it 'sets the `github_team_id` to nil' do
        expect(repo_access.github_team_id).to eq(@github_team.id)
        CollabMigration.new(repo_access).migrate

        expect(repo_access.github_team_id).to be(nil)
      end
    end
  end
end

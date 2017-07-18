# frozen_string_literal: true

require "rails_helper"

RSpec.describe CollabMigration do
  let(:organization) { classroom_org }
  let(:student)      { classroom_student }
  let(:repo_access)  { RepoAccess.create(user: student, organization: organization) }

  let(:github_organization) { organization.github_organization }

  let(:assignment) do
    create(:assignment, title: "gitignore", organization: organization)
  end

  describe "repo_access with an assignment_repo", :vcr do
    before(:each) do
      @assignment_repo = AssignmentRepo::Creator.perform(assignment: assignment, user: student).assignment_repo
      @assignment_repo.update_attributes(user: nil, repo_access: repo_access)
    end

    after(:each) do
      AssignmentRepo.destroy_all
    end

    it "adds the user as a collaborator to the assignment_repos GitHub repo" do
      CollabMigration.new(repo_access).migrate
      add_user_request_regex = %r{#{github_url("/repositories")}/\d+/collaborators/.+$}
      expect(WebMock).to have_requested(:put, add_user_request_regex).times(2)
    end

    context "with a `github_team_id`" do
      before(:each) do
        @github_team = github_organization.create_team("Test Team")
        repo_access.update_attribute(:github_team_id, @github_team.id) # rubocop:disable Rails/SkipsModelValidations
      end

      after(:each) do
        organization.github_client.delete_team(@github_team.id)
      end

      it "deletes the GitHub team" do
        CollabMigration.new(repo_access).migrate
        expect(WebMock).to have_requested(:delete, github_url("/teams/#{@github_team.id}"))
      end

      it "sets the `github_team_id` to nil" do
        expect(repo_access.github_team_id).to eq(@github_team.id)
        CollabMigration.new(repo_access).migrate

        expect(repo_access.github_team_id).to be(nil)
      end
    end
  end
end

require 'rails_helper'

RSpec.describe AssignmentInvitationRedeemer, type: :model do
  let(:organization) { GitHubFactory.create_owner_classroom_org }

  let(:assignment)   { Assignment.create(title: 'Ruby', organization: organization, public_repo: false) }
  let(:invitee)      { GitHubFactory.create_classroom_student }

  before(:each) do
    @invitation_redeemer = AssignmentInvitationRedeemer.new(assignment, invitee)
  end

  after(:each) do
    org_owner = organization.fetch_owner
    team_id   = invitee.repo_accesses.last.github_team_id

    org_owner.github_client.delete_team(team_id)
    org_owner.github_client.delete_repository(@full_repo_name)
  end

  describe '#redeem', :vcr do
    it 'it finds or creates the repo_access and the assignment_repo, then verifes it on github' do
      @full_repo_name = @invitation_redeemer.redeem

      assert_requested :post, github_url("/organizations/#{organization.github_id}/teams")
      assert_requested :post, github_url("/organizations/#{organization.github_id}/repos")

      expect(@full_repo_name).to eql("#{organization.title}/GHClassroom-#{assignment.title}-1")
    end
  end
end

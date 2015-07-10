require 'rails_helper'

describe AssignmentInvitationRedeemer do
  let(:organization)  { GitHubFactory.create_owner_classroom_org }
  let(:github_client) { organization.fetch_owner.github_client   }

  let(:assignment)   { Assignment.create(title: 'Ruby', organization: organization, public_repo: false) }
  let(:invitee)      { GitHubFactory.create_classroom_student }

  before(:each) do
    @invitation_redeemer = AssignmentInvitationRedeemer.new(assignment)
  end

  after(:each) do
    github_client.delete_team(RepoAccess.last.github_team_id)
    github_client.delete_repository(AssignmentRepo.last.github_repo_id)
  end

  describe '#redeem_for', :vcr do
    it 'it finds or creates the repo_access and the assignment_repo, then verifes it on github' do
      full_repo_name = @invitation_redeemer.redeem_for(invitee)

      assert_requested :post, github_url("/organizations/#{organization.github_id}/teams")
      assert_requested :post, github_url("/organizations/#{organization.github_id}/repos")

      expect(full_repo_name).to eql("#{organization.title}/#{assignment.title}-1")
    end
  end
end

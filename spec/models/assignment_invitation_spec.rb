require 'rails_helper'

RSpec.describe AssignmentInvitation, type: :model do
  it { should belong_to(:assignment) }

  it { should validate_presence_of(:assignment) }

  it { should validate_presence_of(:key) }
  # https://github.com/thoughtbot/shoulda-matchers/issues/745
  # it { should validate_uniqueness_of(:key) }

  it 'should have a key after initialization' do
    assignment_invitation = AssignmentInvitation.new
    expect(assignment_invitation.key).to_not be_nil
  end

  describe '#redeem', :vcr do
    let(:organization)  { GitHubFactory.create_owner_classroom_org }
    let(:github_client) { organization.fetch_owner.github_client   }

    let(:assignment) { Assignment.create(title: 'Ruby', organization: organization, public_repo: false) }
    let(:invitee)    { GitHubFactory.create_classroom_student                                           }

    after(:each) do
      github_client.delete_team(RepoAccess.last.github_team_id)
      github_client.delete_repository(AssignmentRepo.last.github_repo_id)
    end

    it 'returns the full repo name of the users GitHub repository' do
      invitation_redeemer = AssignmentInvitationRedeemer.new(assignment)
      full_repo_name      = invitation_redeemer.redeem_for(invitee)

      expect(full_repo_name).to eql("#{organization.title}/#{assignment.title}-1")
    end
  end

  describe '#to_param' do
    let(:assignment_invitation) { create(:assignment_invitation) }

    it 'should return the key' do
      expect(assignment_invitation.to_param).to eql(assignment_invitation.key)
    end
  end
end

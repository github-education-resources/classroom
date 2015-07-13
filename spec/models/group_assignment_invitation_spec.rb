require 'rails_helper'

RSpec.describe GroupAssignmentInvitation, type: :model do
  it { should belong_to(:group_assignment) }

  it { should validate_presence_of(:group_assignment) }

  it { should validate_presence_of(:key) }
  # https://github.com/thoughtbot/shoulda-matchers/issues/745
  # it { should validate_uniqueness_of(:key) }

  it 'should have a key after initialization' do
    group_assignment_invitation = GroupAssignmentInvitation.new
    expect(group_assignment_invitation.key).to_not be_nil
  end

  describe '#redeem', :vcr do
    let(:invitee)       { GitHubFactory.create_classroom_student   }
    let(:organization)  { GitHubFactory.create_owner_classroom_org }
    let(:grouping)      { Grouping.create(title: 'Grouping', organization: organization) }

    let(:github_client) { organization.fetch_owner.github_client   }

    let(:group_assignment)  do
      GroupAssignment.create(creator: organization.fetch_owner,
                             title: 'JavaScript',
                             organization: organization,
                             public_repo: false,
                             grouping: grouping)
    end

    after do
      github_client.delete_team(RepoAccess.last.github_team_id)
      github_client.delete_team(Group.last.github_team_id)
      github_client.delete_repository(GroupAssignmentRepo.last.github_repo_id)
    end

    it 'returns the full repo name of the users GitHub repository' do
      invitation_redeemer = GroupAssignmentInvitationRedeemer.new(group_assignment, nil, 'Code Squad')
      full_repo_name      = invitation_redeemer.redeem_for(invitee)

      expect(full_repo_name).to eql("#{organization.title}/#{group_assignment.title}-Code-Squad")
    end
  end

  describe '#to_param' do
    let(:group_assignment_invitation) { create(:group_assignment_invitation) }

    it 'should return the key' do
      expect(group_assignment_invitation.to_param).to eql(group_assignment_invitation.key)
    end
  end
end

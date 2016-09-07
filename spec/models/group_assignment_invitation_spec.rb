# frozen_string_literal: true
require 'rails_helper'

RSpec.describe GroupAssignmentInvitation, type: :model do
  it 'should have a key after initialization' do
    group_assignment_invitation = GroupAssignmentInvitation.new
    expect(group_assignment_invitation.key).to_not be_nil
  end

  describe '#redeem_for', :vcr do
    let(:invitee)       { GitHubFactory.create_classroom_student   }
    let(:organization)  { GitHubFactory.create_owner_classroom_org }
    let(:grouping)      { Grouping.create(title: 'Grouping', organization: organization) }

    let(:group_assignment) do
      GroupAssignment.create(creator: organization.users.first,
                             title: 'JavaScript',
                             slug: 'javascript',
                             organization: organization,
                             public_repo: false,
                             grouping: grouping)
    end

    let(:group_assignment_invitation) { GroupAssignmentInvitation.create(group_assignment: group_assignment) }

    after(:each) do
      RepoAccess.destroy_all
      Group.destroy_all
      GroupAssignmentRepo.destroy_all
    end

    it 'returns the GroupAssignmentRepo' do
      group_assignment_repo = group_assignment_invitation.redeem_for(invitee, nil, 'Code Squad')
      expect(group_assignment_repo).to eql(GroupAssignmentRepo.last)
    end
  end

  describe '#title' do
    let(:group_assignment_invitation) { create(:group_assignment_invitation) }

    it 'returns the group assignments title' do
      group_assignment_title = group_assignment_invitation.group_assignment.title
      expect(group_assignment_invitation.title).to eql(group_assignment_title)
    end
  end

  describe '#to_param' do
    let(:group_assignment_invitation) { create(:group_assignment_invitation) }

    it 'should return the key' do
      expect(group_assignment_invitation.to_param).to eql(group_assignment_invitation.key)
    end
  end
end

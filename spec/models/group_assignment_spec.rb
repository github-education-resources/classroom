require 'rails_helper'

RSpec.describe GroupAssignment, type: :model do
  describe 'uniqueness of title across organization' do
    let(:organization) { create(:organization)    }
    let(:creator)      { organization.users.first }

    let(:grouping) { Grouping.create(title: 'Grouping', organization: organization) }

    let(:assignment) { Assignment.create(creator: creator, title: 'Ruby Project', organization: organization) }

    let(:group_assignment) do
      GroupAssignment.new(creator: creator,
                          title: assignment.title,
                          organization: organization,
                          grouping: grouping)
    end

    it 'validates that an Assignment in the same organization does not have the same title' do
      expect { group_assignment.save! }.to raise_error(ActiveRecord::RecordInvalid,
                                                       'Validation failed: Title has already been taken')
    end
  end

  describe '#group_assignment_invitation' do
    let(:group_assignment_invitation) { create(:group_assignment_invitation)         }
    let(:group_assignment)            { group_assignment_invitation.group_assignment }

    it 'returns a NullGroupAssignmentInvitation if the GroupAssignmentInvitation doe not exist' do
      group_assignment.group_assignment_invitation = nil
      group_assignment.save

      expect(group_assignment.group_assignment_invitation.class).to eql(NullGroupAssignmentInvitation)
    end

    it 'returns the GroupAssignmentInvitation' do
      expect(group_assignment.group_assignment_invitation.class).to eql(GroupAssignmentInvitation)
    end
  end

  describe '#public?' do
    it 'returns true if Assignments public_repo column is true' do
      group_assignment = create(:group_assignment)
      expect(group_assignment.public?).to be(true)
    end
  end

  describe '#private?' do
    it 'returns false if Assignments public_repo column is true' do
      group_assignment = create(:group_assignment)
      expect(group_assignment.private?).to be(false)
    end
  end
end

require 'rails_helper'

RSpec.describe GroupAssignment, type: :model do
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
end

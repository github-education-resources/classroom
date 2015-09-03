require 'rails_helper'

RSpec.describe GroupAssignment, type: :model do
  describe 'callbacks' do
    describe 'after_create' do
      describe '#create_group_assignment_invitation' do
        let(:group_assignment) { create(:assignment) }

        it 'creates the invitation for the assignment' do
          expect(assignment.invitation).not_to be_nil
          expect(AssignmentInvitation.all.count).to eql(1)
        end
      end
    end
  end

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

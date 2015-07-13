require 'rails_helper'

RSpec.describe GroupAssignment, type: :model do
  it { should have_one(:group_assignment_invitation).dependent(:destroy) }

  it { should have_many(:group_assignment_repos) }

  it { should belong_to(:creator) }
  it { should belong_to :organization }

  it { should validate_presence_of(:creator) }
  it { should validate_presence_of(:organization) }

  it { should validate_presence_of(:title) }
  # https://github.com/thoughtbot/shoulda-matchers/issues/745
  # it { should validate_uniqueness_of(:title).scoped_to(:organization) }

  it 'validates that an Assignment in the same organization does not have the same title' do
    organization     = create(:organization)
    assignment       = Assignment.create(creator: organization.fetch_owner,
                                         title: 'Ruby Project',
                                         organization: organization)

    grouping         = Grouping.new(title: 'Grouping', organization: organization)
    group_assignment = GroupAssignment.create(creator: assignment.creator,
                                              title: assignment.title,
                                              organization: organization,
                                              grouping: grouping)

    expect { group_assignment.save! }.to raise_error(ActiveRecord::RecordInvalid,
                                                     'Validation failed: Title has already been taken')
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

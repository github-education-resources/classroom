require 'rails_helper'

RSpec.describe Assignment, type: :model do
  it { is_expected.to have_one(:assignment_invitation).dependent(:destroy) }

  it { is_expected.to have_many(:assignment_repos).dependent(:destroy) }

  it { is_expected.to belong_to(:creator).class_name(User) }
  it { is_expected.to belong_to(:organization) }

  it_behaves_like 'a default scope where deleted_at is not present'

  describe 'validation and uniqueness' do
    subject { Assignment.new }

    it { is_expected.to validate_presence_of(:creator) }

    it { is_expected.to validate_presence_of(:organization) }

    it { is_expected.to validate_presence_of(:title) }
    # it { is_expected.to validate_uniqueness_of(:title).scoped_to(:organization) }
  end

  describe 'uniqueness of title across organization' do
    let(:organization) { create(:organization)    }
    let(:creator)      { organization.users.first }

    let(:grouping)     { Grouping.create(title: 'Grouping', organization: organization) }

    let(:group_assignment) do
      GroupAssignment.create(creator: creator,
                             title: 'Ruby Project',
                             organization: organization,
                             grouping: grouping)
    end

    let(:assignment) { Assignment.new(creator: creator, title: group_assignment.title, organization: organization) }

    it 'validates that a GroupAssignment in the same organization does not have the same title' do
      expect { assignment.save! }.to raise_error(ActiveRecord::RecordInvalid,
                                                 'Validation failed: Title has already been taken')
    end
  end

  describe '#assignment_invitation' do
    let(:assignment_invitation) { create(:assignment_invitation)   }
    let(:assignment)            { assignment_invitation.assignment }

    it 'returns a NullAssignmentInvitation if the AssignmentInvitation doe not exist' do
      assignment.assignment_invitation = nil
      assignment.save

      expect(assignment.assignment_invitation.class).to eql(NullAssignmentInvitation)
    end

    it 'returns the AssignmentInvitation' do
      expect(assignment.assignment_invitation.class).to eql(AssignmentInvitation)
    end
  end

  describe '#public?' do
    it 'returns true if Assignments public_repo column is true' do
      assignment = create(:assignment)
      expect(assignment.public?).to be(true)
    end
  end

  describe '#private?' do
    it 'returns false if Assignments public_repo column is true' do
      assignment = create(:assignment)
      expect(assignment.private?).to be(false)
    end
  end
end

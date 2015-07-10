require 'rails_helper'

RSpec.describe Assignment, type: :model do
  it { should have_one(:assignment_invitation).dependent(:destroy) }

  it { should have_many(:assignment_repos) }

  it { should belong_to :organization }

  it { should validate_presence_of(:organization) }

  it { should validate_presence_of(:title) }
  # https://github.com/thoughtbot/shoulda-matchers/issues/745
  # it { should validate_uniqueness_of(:title).scoped_to(:organization) }

  it 'validates that a GroupAssignment in the same organization does not have the same title' do
    organization     = create(:organization)
    grouping         = Grouping.new(title: 'Grouping', organization: organization)
    group_assignment = GroupAssignment.create(title: 'Ruby Project', organization: organization, grouping: grouping)
    assignment       = Assignment.new(title: group_assignment.title, organization: organization)

    assignment.save

    expect(assignment.errors.count).to eql(1)
    expect(assignment.errors.messages[:title].first).to eql('has already been taken')
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

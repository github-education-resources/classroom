require 'rails_helper'

RSpec.describe Assignment, type: :model do
  it_behaves_like 'a default scope where deleted_at is not present'

  describe 'slug uniqueness' do
    let(:organization) { create(:organization) }

    it 'verifes that the slug is unique even if the titles are unique' do
      create(:assignment, organization: organization, title: 'assignment-1')
      new_assignment = build(:assignment, organization: organization, title: 'assignment 1')

      expect { new_assignment.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe 'when the title is updated' do
    subject { create(:assignment) }

    it 'updates the slug' do
      subject.update_attributes(title: 'New Title')
      expect(subject.slug).to eql('new-title')
    end
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
      validation_message = 'Validation failed: Your assignment title must be unique'
      expect { assignment.save! }.to raise_error(ActiveRecord::RecordInvalid, validation_message)
    end
  end

  describe 'uniqueness of title across application' do
    let(:organization_1) { create(:organization) }
    let(:organization_2) { create(:organization) }

    it 'allows two organizations to have the same Assignment title and slug' do
      assignment_1 = create(:assignment, organization: organization_1)
      assignment_2 = create(:assignment, organization: organization_2, title: assignment_1.title)

      expect(assignment_2.title).to eql(assignment_1.title)
      expect(assignment_2.slug).to eql(assignment_1.slug)
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

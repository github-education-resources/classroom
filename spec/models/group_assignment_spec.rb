require 'rails_helper'

RSpec.describe GroupAssignment, type: :model do
  describe 'when the title is updated' do
    subject { create(:group_assignment) }

    it 'updates the slug' do
      subject.update_attributes(title: 'New Title')
      expect(subject.slug).to eql('new-title')
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
      validation_message = 'Validation failed: Your assignment title is already in use for your organization'
      expect { group_assignment.save! }.to raise_error(ActiveRecord::RecordInvalid, validation_message)
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

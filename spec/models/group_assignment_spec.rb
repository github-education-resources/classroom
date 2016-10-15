# frozen_string_literal: true
require 'rails_helper'

RSpec.describe GroupAssignment, type: :model do
  it_behaves_like 'a default scope where deleted_at is not present'

  describe 'slug uniqueness' do
    let(:organization) { create(:organization) }

    it 'verifes that the slug is unique even if the titles are unique' do
      create(:group_assignment, organization: organization, title: 'group-assignment-1', slug: 'group-assignment-1')
      new_group_assignment = build(:group_assignment,
                                   organization: organization,
                                   title: 'group assignment 1',
                                   slug: 'group-assignment-1')

      expect { new_group_assignment.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe 'uniqueness of title across organization' do
    let(:organization) { create(:organization)    }
    let(:creator)      { organization.users.first }

    let(:grouping) { Grouping.create(title: 'Grouping', organization: organization) }

    let(:assignment) { create(:assignment, organization: organization) }
    let(:group_assignment) { create(:group_assignment, organization: organization) }

    it 'validates that an Assignment in the same organization does not have the same slug' do
      group_assignment.slug = assignment.slug

      validation_message = 'Validation failed: Your assignment repository prefix must be unique'
      expect { group_assignment.save! }.to raise_error(ActiveRecord::RecordInvalid, validation_message)
    end
  end

  describe 'uniqueness of title across application' do
    let(:organization1) { create(:organization) }
    let(:organization2) { create(:organization) }

    it 'allows two organizations to have the same GroupAssignment title and slug' do
      groupassignment1 = create(:assignment, organization: organization1)
      groupassignment2 = create(:group_assignment,
                                organization: organization2,
                                title: groupassignment1.title,
                                slug: groupassignment1.slug)

      expect(groupassignment2.title).to eql(groupassignment1.title)
      expect(groupassignment2.slug).to eql(groupassignment1.slug)
    end
  end

  context 'with group_assignment' do
    subject { create(:group_assignment) }

    describe '#flipper_id' do
      it 'should return an id' do
        expect(subject.flipper_id).to eq("GroupAssignment:#{subject.id}")
      end
    end

    describe '#public?' do
      it 'returns true if Assignments public_repo column is true' do
        expect(subject.public?).to be(true)
      end
    end

    describe '#private?' do
      it 'returns false if Assignments public_repo column is true' do
        expect(subject.private?).to be(false)
      end
    end
  end
end

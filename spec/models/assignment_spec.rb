# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Assignment, type: :model do
  it_behaves_like 'a default scope where deleted_at is not present'

  describe 'slug uniqueness' do
    let(:organization) { create(:organization) }

    it 'verifes that the slug is unique even if the titles are unique' do
      create(:assignment, organization: organization, title: 'assignment-1', slug: 'assignment-1')
      new_assignment = build(:assignment, organization: organization, title: 'assignment 1', slug: 'assignment-1')

      expect { new_assignment.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe 'uniqueness of title across organization' do
    let(:organization) { create(:organization)    }
    let(:creator)      { organization.users.first }

    let(:grouping)     { Grouping.create(title: 'Grouping', organization: organization) }

    let(:group_assignment) do
      GroupAssignment.create(creator: creator,
                             title: 'Ruby Project',
                             slug: 'ruby-project',
                             organization: organization,
                             grouping: grouping)
    end

    let(:assignment) do
      Assignment.new(creator: creator,
                     title: group_assignment.title,
                     slug: group_assignment.slug,
                     organization: organization)
    end

    it 'validates that a GroupAssignment in the same organization does not have the same slug' do
      validation_message = 'Validation failed: Your assignment repository prefix must be unique'
      expect { assignment.save! }.to raise_error(ActiveRecord::RecordInvalid, validation_message)
    end
  end

  describe 'uniqueness of title across application' do
    let(:organization1) { create(:organization) }
    let(:organization2) { create(:organization) }

    it 'allows two organizations to have the same Assignment title and slug' do
      assignment1 = create(:assignment, organization: organization1)
      assignment2 = create(:assignment,
                           organization: organization2,
                           title: assignment1.title,
                           slug: assignment1.slug)

      expect(assignment2.title).to eql(assignment1.title)
      expect(assignment2.slug).to eql(assignment1.slug)
    end
  end

  context 'with assignment' do
    subject { create(:assignment) }

    describe '#flipper_id' do
      it 'should return an id' do
        expect(subject.flipper_id).to eq("Assignment:#{subject.id}")
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

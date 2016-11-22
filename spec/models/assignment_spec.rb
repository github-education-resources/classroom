# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Assignment, type: :model do
  it_behaves_like 'a default scope where deleted_at is not present'

  describe 'slug uniqueness' do
    let(:classroom) { create(:classroom) }

    it 'verifes that the slug is unique even if the titles are unique' do
      create(:assignment, classroom: classroom, title: 'assignment-1', slug: 'assignment-1')
      new_assignment = build(:assignment, classroom: classroom, title: 'assignment 1', slug: 'assignment-1')

      expect { new_assignment.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe 'uniqueness of title across classroom' do
    let(:classroom) { create(:classroom)    }
    let(:creator)   { classroom.users.first }

    let(:grouping) { Grouping.create(title: 'Grouping', classroom: classroom) }

    let(:group_assignment) do
      GroupAssignment.create(creator: creator,
                             title: 'Ruby Project',
                             slug: 'ruby-project',
                             organization: classroom,
                             grouping: grouping)
    end

    let(:assignment) do
      Assignment.new(creator: creator,
                     title: group_assignment.title,
                     slug: group_assignment.slug,
                     organization: classroom)
    end

    it 'validates that a GroupAssignment in the same organization does not have the same slug' do
      validation_message = 'Validation failed: Your assignment repository prefix must be unique'
      expect { assignment.save! }.to raise_error(ActiveRecord::RecordInvalid, validation_message)
    end
  end

  describe 'uniqueness of title across application' do
    let(:classroom1) { create(:classroom) }
    let(:classroom2) { create(:classroom) }

    it 'allows two classrooms to have the same Assignment title and slug' do
      assignment1 = create(:assignment, classroom: classroom1)
      assignment2 = create(:assignment,
                           classroom: classroom2,
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

# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Organization, type: :model do
  subject { create(:organization) }

  describe 'when title is changed' do
    it 'updates the slug' do
      subject.update_attributes(title: 'New Title')
      expect(subject.slug).to eql("#{subject.github_id}-new-title")
    end
  end

  describe '#all_assignments' do
    context 'new Organization' do
      it 'returns an empty array' do
        expect(subject.all_assignments).to be_kind_of(Array)
        expect(subject.all_assignments.count).to eql(0)
      end
    end

    context 'with Assignments and GroupAssignments' do
      let(:creator) { subject.users.first }

      before do
        grouping = Grouping.new(title: 'Grouping', organization: subject)

        Assignment.create(creator: creator, title: 'Assignment', organization: subject)
        GroupAssignment.create(creator: creator,
                               grouping: grouping,
                               organization: subject,
                               title: 'Group Assignment')
      end

      it 'should return an array of Assignments and GroupAssignments' do
        expect(subject.all_assignments).to be_kind_of(Array)
        expect(subject.all_assignments.count).to eql(2)
      end
    end
  end

  describe '#flipper_id' do
    it 'should return an id' do
      expect(subject.flipper_id).to eq("Organization:#{subject.id}")
    end
  end

  describe '#github_client' do
    it 'selects a users github_client at random' do
      expect(subject.github_client.class).to eql(Octokit::Client)
    end
  end
end
